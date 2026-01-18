import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/message.dart';
import '../models/recording.dart';
import '../models/user.dart';
import 'google_auth_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    print('🔐 [FirebaseService] Starting Google sign-in...');
    try {
      final credential = await _googleAuthService.signInWithGoogle();
      if (credential != null) {
        print(
            '✅ [FirebaseService] Google sign-in successful: ${credential.user?.uid}');
      }
      return credential;
    } catch (e) {
      print('❌ [FirebaseService] Google sign-in failed: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    print('🔐 [FirebaseService] Attempting sign in with email: $email');
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [FirebaseService] Sign in successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('❌ [FirebaseService] Sign in failed: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    print('📝 [FirebaseService] Attempting registration with email: $email');
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ [FirebaseService] Registration successful: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('❌ [FirebaseService] Registration failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    print(
        '👋 [FirebaseService] Attempting sign out for user: ${currentUser?.uid}');
    try {
      // Update user status to offline
      if (currentUser != null) {
        await updateUserStatus(currentUser!.uid, false);
        print('✅ [FirebaseService] User status updated to offline');
      }
      await _googleAuthService.signOut();
      print('✅ [FirebaseService] Sign out successful');
    } catch (e) {
      print('❌ [FirebaseService] Sign out failed: $e');
      rethrow;
    }
  }

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Update user status (online/offline)
  Future<void> updateUserStatus(String uid, bool isOnline) async {
    await _firestore.collection('users').doc(uid).set({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get users stream
  Stream<List<UserModel>> getUsersStream(String instituteCode) {
    return _firestore
        .collection('users')
        .where('instituteCode', isEqualTo: instituteCode)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList());
  }

  // Find matching partner for audio chat
  Future<UserModel?> findMatchingPartner(UserModel currentUser) async {
    final query = _firestore
        .collection('users')
        //.where('instituteCode', isEqualTo: currentUser.instituteCode)
        .where('isOnline', isEqualTo: true)
        .where('uid', isNotEqualTo: currentUser.uid);

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return null;

    // Filter by English level (match beginners with advanced, etc.)
    final candidates = snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .where((user) {
      // Match beginners with advanced users
      if (currentUser.englishLevel == EnglishLevel.beginner) {
        return user.englishLevel == EnglishLevel.advanced ||
            user.englishLevel == EnglishLevel.intermediate;
      }
      if (currentUser.englishLevel == EnglishLevel.advanced) {
        return user.englishLevel == EnglishLevel.beginner ||
            user.englishLevel == EnglishLevel.intermediate;
      }
      return true; // Intermediate can match with anyone
    }).toList();

    if (candidates.isEmpty) return null;

    // TODO: Implement karma-based matching
    candidates.shuffle();
    return candidates.first;
  }

  // Create or get chat room
  Future<String> createOrGetChatRoom(List<String> participants,
      {bool isGroup = false, String? name}) async {
    // For 1-on-1 chats, check if room already exists
    if (!isGroup && participants.length == 2) {
      final existingChat = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: participants[0])
          .where('isGroup', isEqualTo: false)
          .get();

      for (var doc in existingChat.docs) {
        final chatRoom = ChatRoom.fromJson(doc.data());
        if (chatRoom.participants.contains(participants[1])) {
          return doc.id;
        }
      }
    }

    // Create new chat room
    final chatRoom = ChatRoom(
      id: _firestore.collection('chatRooms').doc().id,
      name: name ?? 'Chat',
      participants: participants,
      lastMessageTime: DateTime.now(),
      isGroup: isGroup,
      createdAt: DateTime.now(),
      createdBy: participants[0],
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoom.id)
        .set(chatRoom.toJson());
    return chatRoom.id;
  }

  // Get chat rooms stream
  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromJson(doc.data())).toList());
  }

  // Send message
  Future<void> sendMessage(Message message) async {
    await _firestore
        .collection('chatRooms')
        .doc(message.chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toJson());

    // Update chat room's last message
    await _firestore.collection('chatRooms').doc(message.chatId).update({
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
  }

  // Save recording
  Future<void> saveRecording(Recording recording) async {
    await _firestore
        .collection('recordings')
        .doc(recording.id)
        .set(recording.toJson());
  }

  // Get recordings stream
  Stream<List<Recording>> getRecordingsStream(String userId) {
    return _firestore
        .collection('recordings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recording.fromJson(doc.data()))
            .toList());
  }

  // Upload file to storage
  Future<String> uploadFile(String path, Uint8List bytes) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  // Create audio session
  Future<void> createAudioSession(AudioSession session) async {
    await _firestore
        .collection('audioSessions')
        .doc(session.id)
        .set(session.toJson());
  }

  // Update audio session
  Future<void> updateAudioSession(
      String sessionId, Map<String, dynamic> data) async {
    await _firestore.collection('audioSessions').doc(sessionId).update(data);
  }

  // Increment user stats
  Future<void> incrementUserStats(String uid,
      {int? chats, int? minutes, int? karma}) async {
    final updates = <String, dynamic>{};
    if (chats != null) updates['totalChats'] = FieldValue.increment(chats);
    if (minutes != null) {
      updates['totalMinutes'] = FieldValue.increment(minutes);
    }
    if (karma != null) updates['karmaPoints'] = FieldValue.increment(karma);

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }

  // Award badge
  Future<void> awardBadge(String uid, String badge) async {
    await _firestore.collection('users').doc(uid).update({
      'badges': FieldValue.arrayUnion([badge]),
    });
  }

  Future<String> uploadProfileImage(String uid, File image) async {
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');

    await ref.putFile(image);
    return await ref.getDownloadURL();
  }
  
}
