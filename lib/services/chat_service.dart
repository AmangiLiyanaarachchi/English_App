import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/chat_room_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Box _messagesBox = Hive.box('messages');
  final Box _chatRoomsBox = Hive.box('chatRooms');

  static const int FIRESTORE_MESSAGE_LIMIT = 50;

  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Generate chat ID from two user IDs (alphabetically sorted)
  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Get all users except current user
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Search users by name or email
  Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) {
      return getAllUsers();
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final allUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      // Filter by name or email
      return allUsers.where((user) {
        final nameLower = user.displayName.toLowerCase();
        final emailLower = user.email.toLowerCase();
        final queryLower = query.toLowerCase();
        return nameLower.contains(queryLower) ||
            emailLower.contains(queryLower);
      }).toList();
    });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  // Get user's chat rooms
  Stream<List<ChatRoomModel>> getChatRooms() {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      // Update Hive cache
      for (var doc in snapshot.docs) {
        final chatRoom = ChatRoomModel.fromFirestore(doc);
        _chatRoomsBox.put(chatRoom.chatId, chatRoom);
      }

      return snapshot.docs.map((doc) {
        return ChatRoomModel.fromFirestore(doc);
      }).toList();
    });
  }

  // Get cached chat rooms from Hive (for offline)
  List<ChatRoomModel> getCachedChatRooms() {
    final rooms = _chatRoomsBox.values.toList();
    return rooms.map((room) => room as ChatRoomModel).toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
  }

  // Get messages for a chat (with pagination)
  Stream<List<MessageModel>> getMessages(String otherUserId, {int limit = 50}) {
    final chatId = getChatId(currentUserId, otherUserId);

    return _firestore
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        return MessageModel.fromFirestore(doc);
      }).toList();

      // Save to Hive for offline access
      _saveMessagesToHive(chatId, messages);

      return messages;
    });
  }

  // Get cached messages from Hive (for offline)
  List<MessageModel> getCachedMessages(String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);
    final cached = _messagesBox.get(chatId, defaultValue: <MessageModel>[]);

    if (cached is List) {
      return List<MessageModel>.from(cached);
    }
    return [];
  }

  // Save messages to Hive cache
  void _saveMessagesToHive(String chatId, List<MessageModel> messages) {
    // Get existing messages
    final existing = _messagesBox.get(chatId, defaultValue: <MessageModel>[]);
    final existingList =
        existing is List ? List<MessageModel>.from(existing) : <MessageModel>[];

    // Merge new messages (avoid duplicates)
    final messageIds = existingList.map((m) => m.id).toSet();
    final newMessages =
        messages.where((m) => !messageIds.contains(m.id)).toList();

    final merged = [...existingList, ...newMessages];
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _messagesBox.put(chatId, merged);
  }

  // Send a text message
  Future<void> sendMessage({
    required String receiverUid,
    required String text,
    String type = 'text',
    String? mediaUrl,
  }) async {
    final chatId = getChatId(currentUserId, receiverUid);
    final messageId = const Uuid().v4();

    final message = MessageModel(
      id: messageId,
      text: text,
      senderUid: currentUserId,
      receiverUid: receiverUid,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      mediaUrl: mediaUrl,
      englishTip: _generateEnglishTip(text),
    );

    // Save to Firestore
    final chatRoomRef = _firestore.collection('chatRooms').doc(chatId);
    final messageRef = chatRoomRef.collection('messages').doc(messageId);

    await _firestore.runTransaction((transaction) async {
      // IMPORTANT: Do all reads FIRST before any writes
      final chatRoomSnapshot = await transaction.get(chatRoomRef);

      // Now do all writes
      // Add message
      transaction.set(messageRef, message.toFirestore());

      // Update or create chat room
      if (chatRoomSnapshot.exists) {
        final currentData = chatRoomSnapshot.data() as Map<String, dynamic>;
        final currentUnread = currentData['unreadCount'] ?? 0;

        transaction.update(chatRoomRef, {
          'lastMessage': text,
          'lastMessageTime': Timestamp.fromDate(message.timestamp),
          'lastSenderUid': currentUserId,
          'unreadCount': currentUnread + 1,
        });
      } else {
        transaction.set(chatRoomRef, {
          'participants': [currentUserId, receiverUid],
          'lastMessage': text,
          'lastMessageTime': Timestamp.fromDate(message.timestamp),
          'lastSenderUid': currentUserId,
          'unreadCount': 1,
        });
      }
    });

    // Save to Hive immediately
    final cached = getCachedMessages(receiverUid);
    cached.insert(0, message);
    _messagesBox.put(chatId, cached);

    // Clean old messages from Firestore (keep only last 50)
    _cleanOldMessages(chatId);
  }

  // Clean old messages from Firestore (keep only last 50)
  Future<void> _cleanOldMessages(String chatId) async {
    final messagesSnapshot = await _firestore
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    if (messagesSnapshot.docs.length > FIRESTORE_MESSAGE_LIMIT) {
      // Delete messages beyond the limit
      final toDelete = messagesSnapshot.docs.skip(FIRESTORE_MESSAGE_LIMIT);
      final batch = _firestore.batch();

      for (var doc in toDelete) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String otherUserId) async {
    try {
      final chatId = getChatId(currentUserId, otherUserId);

      // Try to query and update unread messages
      final unreadMessages = await _firestore
          .collection('chatRooms')
          .doc(chatId)
          .collection('messages')
          .where('receiverUid', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Update chat room unread count
      batch.update(
        _firestore.collection('chatRooms').doc(chatId),
        {'unreadCount': 0},
      );

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
      // Don't throw - this is not critical, user can still chat
    }
  }

  // Get unread message count for a chat
  Stream<int> getUnreadCount(String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);

    return _firestore
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Generate simple English tip based on message text
  String _generateEnglishTip(String text) {
    final lower = text.toLowerCase().trim();

    // Common grammar corrections
    if (lower.contains('i am agree')) {
      return '💡 Tip: Say "I agree" (not "I am agree")';
    }
    if (lower.contains('go to home')) {
      return '💡 Tip: Say "go home" (no "to" needed)';
    }
    if (lower.contains('more better')) {
      return '💡 Tip: Use "better" alone (not "more better")';
    }
    if (lower.contains('very unique')) {
      return '💡 Tip: "Unique" means one-of-a-kind (no "very" needed)';
    }

    // Length-based tips
    if (text.split(' ').length > 30) {
      return '💡 Great detail! Try shorter sentences for clarity.';
    }
    if (text.split(' ').length < 3) {
      return '💡 Try expanding into a full sentence for practice!';
    }

    // Positive reinforcement
    final encouragements = [
      '✨ Great expression!',
      '📚 Excellent vocabulary!',
      '🎯 Clear communication!',
      '💪 Keep practicing!',
      '🌟 Well said!',
    ];

    return encouragements[text.length % encouragements.length];
  }

  // Load more messages (pagination)
  Future<List<MessageModel>> loadMoreMessages(
    String otherUserId, {
    required DateTime beforeTimestamp,
    int limit = 50,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);

    final snapshot = await _firestore
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .where('timestamp', isLessThan: Timestamp.fromDate(beforeTimestamp))
        .limit(limit)
        .get();

    final messages = snapshot.docs.map((doc) {
      return MessageModel.fromFirestore(doc);
    }).toList();

    // Update Hive cache
    _saveMessagesToHive(chatId, messages);

    return messages;
  }

  // Update user online status
  Future<void> updateUserStatus(bool isOnline) async {
    if (currentUserId.isEmpty) return;

    // Ensure user profile exists with current auth data
    await _ensureUserProfileExists();

    await _firestore.collection('users').doc(currentUserId).update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Ensure user profile exists in Firestore with proper display name and photo
  Future<void> _ensureUserProfileExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      // If user document doesn't exist or is missing critical fields, create/update it
      if (!userDoc.exists ||
          userDoc.data()?['displayName'] == null ||
          userDoc.data()?['displayName'] == 'User' ||
          userDoc.data()?['displayName']?.toString().trim().isEmpty == true) {
        // Get display name from Firebase Auth or email
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty || displayName == 'User') {
          // Extract name from email if no display name
          final email = user.email ?? '';
          if (email.isNotEmpty) {
            displayName = email.split('@')[0];
            // Capitalize first letter
            if (displayName.isNotEmpty) {
              displayName =
                  displayName[0].toUpperCase() + displayName.substring(1);
            }
          }
        }

        // Ensure we have at least some name
        if (displayName.isEmpty) {
          displayName = 'User';
        }

        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email ?? '',
          'displayName': displayName,
          'photoUrl': user.photoURL,
          'isOnline': true,
          'lastSeen': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error ensuring user profile exists: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String otherUserId, String messageId) async {
    final chatId = getChatId(currentUserId, otherUserId);

    await _firestore
        .collection('chatRooms')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    // Remove from Hive cache
    final cached = getCachedMessages(otherUserId);
    cached.removeWhere((m) => m.id == messageId);
    _messagesBox.put(chatId, cached);
  }
}
