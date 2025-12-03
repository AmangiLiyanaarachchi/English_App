import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_model.dart';
import '../models/chat_room_model.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllUsers = false;

  @override
  void initState() {
    super.initState();
    // Update user status to online
    _chatService.updateUserStatus(true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Update user status to offline
    _chatService.updateUserStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(_showAllUsers ? Icons.chat : Icons.people),
            onPressed: () {
              setState(() {
                _showAllUsers = !_showAllUsers;
              });
            },
            tooltip: _showAllUsers ? 'Show Chats' : 'Show All Users',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _showAllUsers ? 'Search users...' : 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _showAllUsers ? _buildAllUsersList() : _buildChatsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showAllUsers = true;
          });
        },
        child: const Icon(Icons.message),
        tooltip: 'New Chat',
      ),
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<List<ChatRoomModel>>(
      stream: _chatService.getChatRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show cached chats while loading
          final cachedChats = _chatService.getCachedChatRooms();
          if (cachedChats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildChatsListView(cachedChats, isOffline: true);
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final chatRooms = snapshot.data ?? [];

        // Filter by search query
        final filteredChats = _searchQuery.isEmpty
            ? chatRooms
            : chatRooms.where((chat) {
                final otherUserId = chat.participants.firstWhere(
                  (id) => id != _chatService.currentUserId,
                  orElse: () => '',
                );
                // For now, search by last message
                // You could enhance this to search by user name
                return chat.lastMessage
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty
                      ? Icons.chat_bubble_outline
                      : Icons.search_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No chats yet\nStart chatting with your English practice partners!'
                      : 'No chats found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildChatsListView(filteredChats);
      },
    );
  }

  Widget _buildChatsListView(List<ChatRoomModel> chatRooms,
      {bool isOffline = false}) {
    return Column(
      children: [
        if (isOffline)
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
                  'Offline - Showing cached chats',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final otherUserId = chatRoom.participants.firstWhere(
                (id) => id != _chatService.currentUserId,
                orElse: () => '',
              );

              return _buildChatTile(chatRoom, otherUserId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatTile(ChatRoomModel chatRoom, String otherUserId) {
    final isUnread = chatRoom.lastSenderUid != _chatService.currentUserId &&
        chatRoom.unreadCount > 0;

    return FutureBuilder<UserModel?>(
      future: _chatService.getUserById(otherUserId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final displayName =
            user?.displayName ?? otherUserId.substring(0, 8) + '...';
        final photoUrl = user?.photoUrl;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF4A90A4),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            displayName,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Row(
            children: [
              if (chatRoom.lastSenderUid == _chatService.currentUserId)
                const Icon(Icons.done_all, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  chatRoom.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeago.format(chatRoom.lastMessageTime, locale: 'en_short'),
                style: TextStyle(
                  fontSize: 12,
                  color: isUnread ? const Color(0xFF4A90A4) : Colors.grey,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isUnread) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90A4),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chatRoom.unreadCount > 9 ? '9+' : '${chatRoom.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatDetailScreen(otherUserId: otherUserId),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _chatService.searchUsers(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isEmpty
                      ? Icons.people_outline
                      : Icons.search_off,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No users found'
                      : 'No users match your search',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4A90A4),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(user.displayName),
              subtitle: Text(
                user.isOnline
                    ? 'Online'
                    : user.lastSeen != null
                        ? 'Last seen ${timeago.format(user.lastSeen!)}'
                        : user.email,
                style: TextStyle(
                  color: user.isOnline ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chat_bubble_outline),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatDetailScreen(otherUserId: user.uid),
                  ),
                ).then((_) {
                  // Return to chats view after opening a chat
                  setState(() {
                    _showAllUsers = false;
                  });
                });
              },
            );
          },
        );
      },
    );
  }
}
