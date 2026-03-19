import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../models/call_model.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/incoming_call_screen.dart';

const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
  'chat_messages',
  'Chat Messages',
  description: 'Notifications for new chat messages',
  importance: Importance.high,
);

const AndroidNotificationChannel _callChannel = AndroidNotificationChannel(
  'incoming_calls',
  'Incoming Calls',
  description: 'High priority notifications for incoming calls',
  importance: Importance.max,
  playSound: true,
);

const AndroidInitializationSettings _androidInitSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
const DarwinInitializationSettings _iosInitSettings =
    DarwinInitializationSettings();

Future<void> _ensureNotificationPluginReady(
  FlutterLocalNotificationsPlugin plugin,
) async {
  const settings = InitializationSettings(
    android: _androidInitSettings,
    iOS: _iosInitSettings,
  );

  await plugin.initialize(settings);

  final androidPlugin = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(_chatChannel);
  await androidPlugin?.createNotificationChannel(_callChannel);
}

Future<void> _showBackgroundCallNotification(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await _ensureNotificationPluginReady(plugin);

  final title = message.data['title']?.toString() ?? 'Incoming Call';
  final body = message.data['body']?.toString() ?? 'Global Gate is calling you';

  const androidDetails = AndroidNotificationDetails(
    'incoming_calls',
    'Incoming Calls',
    channelDescription: 'High priority notifications for incoming calls',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.call,
    visibility: NotificationVisibility.public,
    ticker: 'Incoming call',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  final payload = message.data.map(
    (key, value) => MapEntry(key, value?.toString() ?? ''),
  );

  await plugin.show(
    (message.data['callId']?.toString() ?? DateTime.now().toIso8601String())
            .hashCode &
        0x7fffffff,
    title,
    body,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(payload),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final type = message.data['type']?.toString();
  if (type == 'call') {
    await _showBackgroundCallNotification(message);
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<User?>? _authSubscription;
  String? _lastSavedToken;
  String? _lastOpenedCallId;
  String? _lastOpenedMessageId;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeLocalNotifications();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _listenForTokenChanges();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const settings = InitializationSettings(
      android: _androidInitSettings,
      iOS: _iosInitSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onLocalNotificationTappedBg,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_chatChannel);
    await androidPlugin?.createNotificationChannel(_callChannel);

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchPayload != null && launchPayload.isNotEmpty) {
      try {
        final data = jsonDecode(launchPayload) as Map<String, dynamic>;
        _routeFromData(data);
      } catch (_) {
        // Ignore malformed local notification payloads.
      }
    }
  }

  @pragma('vm:entry-point')
  static void _onLocalNotificationTappedBg(NotificationResponse response) {
    // Handled when app resumes via getInitialMessage/onMessageOpenedApp.
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _routeFromData(data);
    } catch (_) {
      // Ignore malformed payloads.
    }
  }

  void _listenForTokenChanges() {
    _authSubscription ??=
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _lastSavedToken = null;
        return;
      }
      await syncTokenForUser(user.uid);
    });

    _messaging.onTokenRefresh.listen((newToken) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      _saveToken(userId, newToken);
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      syncTokenForUser(currentUser.uid);
    }
  }

  Future<void> syncTokenForUser(String userId) async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _saveToken(userId, token);
  }

  Future<void> _saveToken(String userId, String token) async {
    if (_lastSavedToken == token) return;

    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _lastSavedToken = token;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final type = message.data['type']?.toString();

    if (type == 'call') {
      await _showCallNotification(message);
      return;
    }

    if (type == 'message') {
      await _showChatNotification(message);
      return;
    }

    if (message.notification != null) {
      await _showGenericNotification(message);
    }
  }

  Future<void> _showCallNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Incoming Call';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new incoming call';

    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'High priority notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      ticker: 'Incoming call',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _localNotifications.show(
      _stableId(message.data['callId']?.toString() ??
          DateTime.now().toIso8601String()),
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(_stringifyData(message.data)),
    );
  }

  Future<void> _showChatNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'New Message';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'You received a new message';

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    await _localNotifications.show(
      _stableId(message.data['messageId']?.toString() ??
          DateTime.now().toIso8601String()),
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(_stringifyData(message.data)),
    );
  }

  Future<void> _showGenericNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'General notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(_stringifyData(message.data)),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _routeFromData(_stringifyData(message.data));
  }

  void _routeFromData(Map<String, dynamic> rawData) {
    final data = _stringifyData(rawData);
    final type = data['type'];

    if (type == 'call') {
      _openIncomingCallScreen(data);
      return;
    }

    if (type == 'message') {
      _openChatDetailScreen(data);
    }
  }

  void _openIncomingCallScreen(Map<String, String> data) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    final callId = data['callId'];
    if (callId == null || callId.isEmpty) return;

    if (_lastOpenedCallId == callId) {
      return;
    }
    _lastOpenedCallId = callId;

    final call = CallModel(
      callId: callId,
      callerId: data['callerId'] ?? '',
      callerName: data['callerName'] ?? 'Global Gate',
      callerPhotoUrl: data['callerPhotoUrl'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverPhotoUrl: data['receiverPhotoUrl'] ?? '',
      agoraChannelId: data['agoraChannelId'] ?? '',
      status: data['status'] ?? 'calling',
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
    );

    Navigator.of(navContext).push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(call: call),
      ),
    );
  }

  void _openChatDetailScreen(Map<String, String> data) {
    final navContext = navigatorKey.currentContext;
    if (navContext == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final senderId = data['senderId'];
    final receiverId = data['receiverId'];
    final otherUserId = senderId == currentUserId ? receiverId : senderId;

    if (otherUserId == null || otherUserId.isEmpty) {
      return;
    }

    final messageId = data['messageId'];
    if (messageId != null && messageId.isNotEmpty) {
      if (_lastOpenedMessageId == messageId) {
        return;
      }
      _lastOpenedMessageId = messageId;
    }

    Navigator.of(navContext).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(otherUserId: otherUserId),
      ),
    );
  }

  int _stableId(String value) => value.hashCode & 0x7fffffff;

  Map<String, String> _stringifyData(Map<String, dynamic> source) {
    final output = <String, String>{};
    source.forEach((key, value) {
      if (value == null) return;
      output[key] = value.toString();
    });
    return output;
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
