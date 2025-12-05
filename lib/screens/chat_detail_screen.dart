import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/call_signaling_service.dart';
import '../services/agora_service.dart';
import 'voice_call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;

  const ChatDetailScreen({Key? key, required this.otherUserId})
      : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final CallSignalingService _callSignalingService = CallSignalingService();
  final AgoraService _agoraService = AgoraService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isOffline = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  UserModel? _otherUser;
  List<MessageModel> _allMessages = [];
  String? _englishChallenge;

  // English challenges for the institute twist
  final List<String> _challenges = [
    '💡 Synonym Challenge: Use a fancier word!',
    '📚 Grammar Drill: Try a conditional sentence',
    '🎯 Vocab Boost: Include "serendipity"',
    '✨ Idiom Practice: Use an English idiom',
    '🌟 Formal Mode: Rephrase professionally',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkConnectivity();
    _loadOtherUser();
    _generateChallenge();
    _setupScrollListener();
    _markMessagesAsRead();

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _loadOtherUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (doc.exists) {
        setState(() {
          _otherUser = UserModel.fromMap(doc.data()!, widget.otherUserId);
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _generateChallenge() {
    setState(() {
      _englishChallenge =
          _challenges[DateTime.now().millisecond % _challenges.length];
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more when scrolled to top (reversed list)
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _allMessages.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final oldestMessage = _allMessages.last;
      final olderMessages = await _chatService.loadMoreMessages(
        widget.otherUserId,
        beforeTimestamp: oldestMessage.timestamp,
      );

      if (olderMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
      } else {
        setState(() {
          _allMessages.addAll(olderMessages);
        });
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(widget.otherUserId);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear input immediately for better UX
    _messageController.clear();
    _generateChallenge(); // New challenge after sending

    try {
      await _chatService.sendMessage(
        receiverUid: widget.otherUserId,
        text: text,
      );

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        actions: [
          // Voice call button
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Voice Call',
            onPressed: _otherUser != null ? _initiateVoiceCall : null,
          ),
          if (_englishChallenge != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Chip(
                  label: Text(
                    _englishChallenge!,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: Colors.amber.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.offline_bolt,
                      size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Text(
                    'Offline - Messages will send when connected',
                    style:
                        TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: _buildMessagesList(),
          ),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (_otherUser == null) {
      return Text(widget.otherUserId.substring(0, 8) + '...');
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF4A90A4),
          backgroundImage: _otherUser!.photoUrl != null
              ? NetworkImage(_otherUser!.photoUrl!)
              : null,
          child: _otherUser!.photoUrl == null
              ? Text(
                  _otherUser!.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _otherUser!.displayName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _otherUser!.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11,
                  color: _otherUser!.isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessages(widget.otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _allMessages.isEmpty) {
          // Try loading from cache first
          final cached = _chatService.getCachedMessages(widget.otherUserId);
          if (cached.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          _allMessages = cached;
        } else if (snapshot.hasData) {
          _allMessages = snapshot.data!;
        }

        if (_allMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Start your English practice conversation!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message below 👇',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // Newest messages at bottom
          padding: const EdgeInsets.all(16),
          itemCount: _allMessages.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _allMessages.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final message = _allMessages[index];
            final isMe = message.senderUid == _chatService.currentUserId;

            // Show date separator
            final showDateSeparator = index == _allMessages.length - 1 ||
                !_isSameDay(
                    message.timestamp, _allMessages[index + 1].timestamp);

            return Column(
              children: [
                if (showDateSeparator) _buildDateSeparator(message.timestamp),
                _buildMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    String dateText;
    final now = DateTime.now();

    if (_isSameDay(date, now)) {
      dateText = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    final time = DateFormat('HH:mm').format(message.timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF4A90A4) : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message text
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),

            // English tip (if available)
            if (message.englishTip != null &&
                message.englishTip!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.2)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.englishTip!,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.9)
                        : Colors.orange.shade800,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Time and read status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? Colors.blue.shade300
                        : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Voice note button (placeholder for future implementation)
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF4A90A4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.mic, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎤 Voice messages coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Voice message',
              ),
            ),

            const SizedBox(width: 4),

            // Send button
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF4A90A4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Initiate voice call
  Future<void> _initiateVoiceCall() async {
    if (_otherUser == null) return;

    try {
      // Request microphone permission first
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice calls'),
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Get current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final currentUserData = UserModel.fromMap(
        currentUserDoc.data()!,
        currentUser.uid,
      );

      // Create call
      final call = await _callSignalingService.createCall(
        receiverId: _otherUser!.uid,
        receiverName: _otherUser!.displayName,
        receiverPhotoUrl: _otherUser!.photoUrl ?? '',
        callerName: currentUserData.displayName,
        callerPhotoUrl: currentUserData.photoUrl ?? '',
      );

      // Join Agora channel (initialize is handled internally)
      await _agoraService.joinChannel(call.agoraChannelId);

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to voice call screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            call: call,
            isOutgoing: true,
          ),
        ),
      );
    } catch (e) {
      print('Error initiating call: $e');
      // Leave the channel if we joined it before the error
      await _agoraService.leaveChannel().catchError((err) {
        print('Error leaving channel after failed initiation: $err');
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate call: $e')),
      );
    }
  }
}
