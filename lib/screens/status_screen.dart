import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/status_model.dart';
import '../services/status_service.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final StatusService _statusService = StatusService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Cleanup expired statuses when screen loads
    _statusService.cleanupExpiredStatuses();
  }

  Future<void> _showAddStatusDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.text_fields, color: Color(0xFF4A90A4)),
              title: const Text('Text Status'),
              onTap: () {
                Navigator.pop(context);
                _showTextStatusDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF4A90A4)),
              title: const Text('Image Status'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTextStatusDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Text Status'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'What\'s on your mind?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await _statusService.createTextStatus(controller.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status posted!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90A4),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      await _statusService.createImageStatus(File(image.path));
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusDetail(StatusModel status) {
    // Mark as viewed
    _statusService.addView(status.statusId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(status: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<StatusModel>>(
        stream: _statusService.getActiveStatuses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final statuses = snapshot.data ?? [];

          if (statuses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No Status Yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first status',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Group statuses by user
          final Map<String, List<StatusModel>> groupedStatuses = {};
          for (var status in statuses) {
            if (!groupedStatuses.containsKey(status.ownerId)) {
              groupedStatuses[status.ownerId] = [];
            }
            groupedStatuses[status.ownerId]!.add(status);
          }

          final myUserId = _statusService.currentUser?.uid;

// Convert map to ordered list of entries
          final entries = groupedStatuses.entries.toList();

// 👤 Move current user's status to top
          if (myUserId != null) {
            final myIndex = entries.indexWhere((e) => e.key == myUserId);

            if (myIndex > 0) {
              final myEntry = entries.removeAt(myIndex);
              entries.insert(0, myEntry);
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final userStatuses = entry.value;
              final latestStatus = userStatuses.first;

              return _buildStatusCard(latestStatus, userStatuses);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStatusDialog,
        backgroundColor: const Color(0xFF4A90A4),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusCard(
      StatusModel status, List<StatusModel> allUserStatuses) {
    final timeAgo = timeago.format(status.createdAt);
    final isMyStatus = status.ownerId == _statusService.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showStatusDetail(status),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profile picture with ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4A90A4),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: status.ownerPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(status.ownerPhoto)
                      : null,
                  child: status.ownerPhoto.isEmpty
                      ? Text(status.ownerName[0].toUpperCase())
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Status info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMyStatus ? 'My Status' : status.ownerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Status count
              if (allUserStatuses.length > 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90A4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${allUserStatuses.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Status Detail Screen
class StatusDetailScreen extends StatefulWidget {
  final StatusModel status;

  const StatusDetailScreen({super.key, required this.status});

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen> {
  final StatusService _statusService = StatusService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _statusService.addComment(
        widget.status.statusId,
        _commentController.text.trim(),
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.status.ownerPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(widget.status.ownerPhoto)
                  : null,
              child: widget.status.ownerPhoto.isEmpty
                  ? Text(widget.status.ownerName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.status.ownerName,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                Text(
                  timeago.format(widget.status.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<StatusModel>>(
        stream: _statusService.getActiveStatuses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentStatus = snapshot.data!.firstWhere(
              (s) => s.statusId == widget.status.statusId,
              orElse: () => widget.status);

          return Column(
            children: [
              // Status content
              Expanded(
                child: Center(
                  child: currentStatus.type == 'image'
                      ? CachedNetworkImage(
                          imageUrl: currentStatus.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.white),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            currentStatus.text!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ),
              ),

              // Views and comments section
              Container(
                color: Colors.grey.shade900,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${currentStatus.viewCount} views',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.comment,
                            size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${currentStatus.commentCount} comments',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),

                    // Comments
                    if (currentStatus.comments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: currentStatus.comments.length,
                          itemBuilder: (context, index) {
                            final comment = currentStatus.comments[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage:
                                        comment.userPhoto.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                comment.userPhoto)
                                            : null,
                                    child: comment.userPhoto.isEmpty
                                        ? Text(
                                            comment.userName[0].toUpperCase(),
                                            style:
                                                const TextStyle(fontSize: 10))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.userName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          comment.comment,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Comment input
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade800,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.send, color: Color(0xFF4A90A4)),
                          onPressed: _addComment,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
