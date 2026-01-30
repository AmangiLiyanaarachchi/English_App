// import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:timeago/timeago.dart' as timeago;

// import '../models/status_model.dart';
// import '../services/status_service.dart';

// class StatusScreen extends StatefulWidget {
//   const StatusScreen({super.key});

//   @override
//   State<StatusScreen> createState() => _StatusScreenState();
// }

// class _StatusScreenState extends State<StatusScreen> {
//   final StatusService _statusService = StatusService();
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     // Cleanup expired statuses when screen loads
//     _statusService.cleanupExpiredStatuses();
//   }

//   Future<void> _showAddStatusDialog() async {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'Add Status',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             ListTile(
//               leading: const Icon(Icons.text_fields, color: Color(0xFF4A90A4)),
//               title: const Text('Text Status'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showTextStatusDialog();
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.image, color: Color(0xFF4A90A4)),
//               title: const Text('Image Status'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _pickImage();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _showTextStatusDialog() async {
//     final controller = TextEditingController();

//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Create Text Status'),
//         content: TextField(
//           controller: controller,
//           maxLines: 3,
//           maxLength: 200,
//           decoration: const InputDecoration(
//             hintText: 'What\'s on your mind?',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (controller.text.trim().isNotEmpty) {
//                 try {
//                   await _statusService.createTextStatus(controller.text.trim());
//                   if (mounted) {
//                     Navigator.pop(context);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text('Status posted!')),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Error: $e')),
//                     );
//                   }
//                 }
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4A90A4),
//             ),
//             child: const Text('Post'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (image == null) return;

//     // Show loading
//     if (mounted) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     try {
//       await _statusService.createImageStatus(File(image.path));
//       if (mounted) {
//         Navigator.pop(context); // Close loading
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Status posted!')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.pop(context); // Close loading
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }

//   void _showStatusDetail(
//     StatusModel status,
//     List<StatusModel> userStatuses,
//   ) {
//     _statusService.addView(status.statusId);

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StatusDetailScreen(
//           statuses: userStatuses,
//           initialIndex: userStatuses.indexOf(status), otherUserId: status.ownerId,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text(
//           'Status',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: StreamBuilder<List<StatusModel>>(
//         stream: _statusService.getActiveStatuses(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           final statuses = snapshot.data ?? [];

//           if (statuses.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.photo_library_outlined,
//                       size: 80, color: Colors.grey.shade400),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No Status Yet',
//                     style: TextStyle(
//                       fontSize: 20,
//                       color: Colors.grey.shade600,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Tap + to add your first status',
//                     style: TextStyle(color: Colors.grey.shade500),
//                   ),
//                 ],
//               ),
//             );
//           }

//           // Group statuses by user
//           final Map<String, List<StatusModel>> groupedStatuses = {};
//           for (var status in statuses) {
//             if (!groupedStatuses.containsKey(status.ownerId)) {
//               groupedStatuses[status.ownerId] = [];
//             }
//             groupedStatuses[status.ownerId]!.add(status);
//           }

//           final myUserId = _statusService.currentUser?.uid;

// // Convert map to ordered list of entries
//           final entries = groupedStatuses.entries.toList();

// // 👤 Move current user's status to top
//           if (myUserId != null) {
//             final myIndex = entries.indexWhere((e) => e.key == myUserId);

//             if (myIndex > 0) {
//               final myEntry = entries.removeAt(myIndex);
//               entries.insert(0, myEntry);
//             }
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: entries.length,
//             itemBuilder: (context, index) {
//               final entry = entries[index];
//               final userStatuses = entry.value;
//               final latestStatus = userStatuses.first;

//               return _buildStatusCard(latestStatus, userStatuses);
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddStatusDialog,
//         backgroundColor: const Color(0xFF4A90A4),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }

//   Widget _buildStatusCard(
//       StatusModel status, List<StatusModel> allUserStatuses) {
//     final timeAgo = timeago.format(status.createdAt);
//     final isMyStatus = status.ownerId == _statusService.currentUser?.uid;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: InkWell(
//         onTap: () => _showStatusDetail(status, allUserStatuses),
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Row(
//             children: [
//               // Profile picture with ring
//               Container(
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: const Color(0xFF4A90A4),
//                     width: 3,
//                   ),
//                 ),
//                 child: CircleAvatar(
//                   radius: 28,
//                   backgroundImage: status.ownerPhoto.isNotEmpty
//                       ? CachedNetworkImageProvider(status.ownerPhoto)
//                       : null,
//                   child: status.ownerPhoto.isEmpty
//                       ? Text(status.ownerName[0].toUpperCase())
//                       : null,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               // Status info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       isMyStatus ? 'My Status' : status.ownerName,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       timeAgo,
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Status count
//               if (allUserStatuses.length > 1)
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF4A90A4),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${allUserStatuses.length}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Status Detail Screen
// class StatusDetailScreen extends StatefulWidget {
//   final List<StatusModel> statuses;
//   final int initialIndex;
//    final String otherUserId;

//   const StatusDetailScreen({
//     super.key,
//     required this.statuses,
//     required this.initialIndex,
//     required this.otherUserId,
//   });

//   @override
//   State<StatusDetailScreen> createState() => _StatusDetailScreenState();
// }

// class _StatusDetailScreenState extends State<StatusDetailScreen>
//     with SingleTickerProviderStateMixin {
//   final StatusService _statusService = StatusService();
//   final TextEditingController _commentController = TextEditingController();

//   late AnimationController _progressController;
//   late int _currentIndex;
  

//   void _nextStatus() {
//     if (_currentIndex < widget.statuses.length - 1) {
//       setState(() {
//         _currentIndex++;
//         _progressController.forward(from: 0);
//       });
//     } else {
//       Navigator.pop(context); // last status
//     }
//   }

//   void _previousStatus() {
//     if (_currentIndex > 0) {
//       setState(() {
//         _currentIndex--;
//         _progressController.forward(from: 0);
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;

//     // 🔹 ADDED

//     _progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 7),
//     )..forward();

//     _progressController.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         if (_currentIndex < widget.statuses.length - 1) {
//           setState(() {
//             _currentIndex++;
//             _progressController.forward(from: 0); // restart progress
//           });
//         } else {
//           Navigator.pop(context); // last status → exit
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _progressController.dispose();
//     _commentController.dispose();
//     super.dispose();
//   }

//   Widget _segmentedProgressBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: List.generate(widget.statuses.length, (index) {
//           double value;

//           if (index < _currentIndex) {
//             value = 1; // completed
//           } else if (index == _currentIndex) {
//             value = _progressController.value; // animating
//           } else {
//             value = 0; // upcoming
//           }

//           return Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 2),
//               child: LinearProgressIndicator(
//                 value: value,
//                 minHeight: 3,
//                 backgroundColor: Colors.white24,
//                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }

//   Future<void> _addComment() async {
//   if (_commentController.text.trim().isEmpty) return;

//   _progressController.stop(); // ⏸ pause progress

//   try {
//     await _statusService.addComment(
//       widget.statuses[_currentIndex].statusId,
//       _commentController.text.trim(),
//     );

//     _commentController.clear();
//     FocusScope.of(context).unfocus();

//     _progressController.forward(); // ▶ resume progress
//   } catch (e) {
//     _progressController.forward(); // ▶ resume even on error
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error: $e')),
//     );
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     final currentStatus = widget.statuses[_currentIndex];
    
//     //final name = user?.displayName ?? 'User';

//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//   radius: 16,
//   backgroundImage: currentStatus.ownerPhoto.isNotEmpty
//       ? CachedNetworkImageProvider(currentStatus.ownerPhoto)
//       : null,
//   child: currentStatus.ownerPhoto.isEmpty
//       ? Text(
//           currentStatus.ownerName.substring(0, 1).toUpperCase(),
//           style: const TextStyle(color: Colors.white),
//         )
//       : null,
// ),

//             const SizedBox(width: 8),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   currentStatus.ownerName,
//                   style: const TextStyle(fontSize: 14, color: Colors.white),
//                 ),
//                 Text(
//                   timeago.format(currentStatus.createdAt),
//                   style: const TextStyle(fontSize: 12, color: Colors.white70),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//       body: StreamBuilder<List<StatusModel>>(
//         stream: _statusService.getActiveStatuses(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           return Column(
//             children: [
//               AnimatedBuilder(
//                 animation: _progressController,
//                 builder: (context, child) {
//                   return Padding(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                     child: Row(
//                       children: List.generate(widget.statuses.length, (index) {
//                         double value;

//                         if (index < _currentIndex) {
//                           value = 1; // completed
//                         } else if (index == _currentIndex) {
//                           value = _progressController.value; // animating
//                         } else {
//                           value = 0; // upcoming
//                         }

//                         return Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 2),
//                             child: LinearProgressIndicator(
//                               value: value,
//                               minHeight: 3,
//                               backgroundColor: Colors.white24,
//                               valueColor: const AlwaysStoppedAnimation<Color>(
//                                   Colors.white),
//                             ),
//                           ),
//                         );
//                       }),
//                     ),
//                   );
//                 },
//               ),

//               // Status content
//               Expanded(
//                 child: GestureDetector(
//                   behavior: HitTestBehavior.opaque,
//                   onTapDown: (details) {
//                     final screenWidth = MediaQuery.of(context).size.width;
//                     final tapX = details.globalPosition.dx;

//                     if (tapX < screenWidth / 2) {
//                       _previousStatus(); // 👈 LEFT TAP
//                     } else {
//                       _nextStatus(); // 👉 RIGHT TAP
//                     }
//                   },
//                   child: Center(
//                     child: currentStatus.type == 'image'
//                         ? CachedNetworkImage(
//                             imageUrl: currentStatus.imageUrl!,
//                             fit: BoxFit.contain,
//                             placeholder: (context, url) =>
//                                 const CircularProgressIndicator(),
//                             errorWidget: (context, url, error) =>
//                                 const Icon(Icons.error, color: Colors.white),
//                           )
//                         : Padding(
//                             padding: const EdgeInsets.all(20),
//                             child: Text(
//                               currentStatus.text!,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ),
//                   ),
//                 ),
//               ),

//               // Views and comments section
//               Container(
//                 color: Colors.grey.shade900,
//                 padding: const EdgeInsets.all(12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Stats
//                     Row(
//                       children: [
//                         Icon(Icons.visibility,
//                             size: 16, color: Colors.grey.shade400),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${currentStatus.viewCount} views',
//                           style: TextStyle(color: Colors.grey.shade400),
//                         ),
//                         const SizedBox(width: 16),
//                         Icon(Icons.comment,
//                             size: 16, color: Colors.grey.shade400),
//                         const SizedBox(width: 4),
//                         Text(
//                           '${currentStatus.commentCount} comments',
//                           style: TextStyle(color: Colors.grey.shade400),
//                         ),
//                       ],
//                     ),

//                     // Comments
//                     if (currentStatus.comments.isNotEmpty) ...[
//                       const SizedBox(height: 12),
//                       SizedBox(
//                         height: 150,
//                         child: ListView.builder(
//                           itemCount: currentStatus.comments.length,
//                           itemBuilder: (context, index) {
//                             final comment = currentStatus.comments[index];
//                             return Padding(
//                               padding: const EdgeInsets.only(bottom: 8),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 12,
//                                     backgroundImage:
//                                         comment.userPhoto.isNotEmpty
//                                             ? CachedNetworkImageProvider(
//                                                 comment.userPhoto)
//                                             : null,
//                                     child: comment.userPhoto.isEmpty
//                                         ? Text(
//                                             comment.userName[0].toUpperCase(),
//                                             style:
//                                                 const TextStyle(fontSize: 10))
//                                         : null,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           comment.userName,
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 12,
//                                           ),
//                                         ),
//                                         Text(
//                                           comment.comment,
//                                           style: const TextStyle(
//                                             color: Colors.white70,
//                                             fontSize: 13,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ],

//                     // Comment input
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: _commentController,
//                             onTap: () {
//                               _progressController
//                                   .stop(); // ⏸ pause while typing
//                             },
//                             style: const TextStyle(color: Colors.white),
//                             decoration: InputDecoration(
//                               hintText: 'Add a comment...',
//                               hintStyle: TextStyle(color: Colors.grey.shade500),
//                               filled: true,
//                               fillColor: Colors.grey.shade800,
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                                 borderSide: BorderSide.none,
//                               ),
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                             ),
//                           ),
//                         ),
//                         IconButton(
//                           icon:
//                               const Icon(Icons.send, color: Color(0xFF4A90A4)),
//                           onPressed: _addComment,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
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

  // ✅ Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _statusService.cleanupExpiredStatuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    const radius = Radius.circular(50);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value.trim().toLowerCase());
        },
        decoration: InputDecoration(
          hintText: "Search status by name...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90A4)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(radius),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showStatusDetail(
    StatusModel status,
    List<StatusModel> userStatuses,
  ) {
    _statusService.addView(status.statusId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          statuses: userStatuses,
          initialIndex: userStatuses.indexOf(status),
          otherUserId: status.ownerId,
        ),
      ),
    );
  }

  // ✅ When pressing delete icon in list: open viewer in delete mode
  void _openMyStatusesForDelete(List<StatusModel> myStatuses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          statuses: myStatuses,
          initialIndex: 0,
          otherUserId: _statusService.currentUser?.uid ?? '',
          deleteMode: true, // ✅ important
        ),
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<StatusModel>>(
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

                // ✅ Group statuses by user
                final Map<String, List<StatusModel>> groupedStatuses = {};
                for (var s in statuses) {
                  groupedStatuses.putIfAbsent(s.ownerId, () => []).add(s);
                }

                final myUserId = _statusService.currentUser?.uid;

                // ✅ Convert to list & keep my statuses first
                final entries = groupedStatuses.entries.toList();

                if (myUserId != null) {
                  final myIndex = entries.indexWhere((e) => e.key == myUserId);
                  if (myIndex > 0) {
                    final myEntry = entries.removeAt(myIndex);
                    entries.insert(0, myEntry);
                  }
                }

                // ✅ Apply search filter
                final filteredEntries = entries.where((entry) {
                  final latest = entry.value.first;
                  final isMyStatus = latest.ownerId == myUserId;
                  final displayName = isMyStatus ? "My Status" : latest.ownerName;

                  if (_searchQuery.isEmpty) return true;
                  return displayName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredEntries.isEmpty) {
                  return Center(
                    child: Text(
                      "No results found",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    final userStatuses = entry.value;
                    final latestStatus = userStatuses.first;

                    return _buildStatusCard(latestStatus, userStatuses);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStatusDialog,
        backgroundColor: const Color(0xFF4A90A4),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusCard(
    StatusModel status,
    List<StatusModel> allUserStatuses,
  ) {
    final timeAgo = timeago.format(status.createdAt);
    final isMyStatus = status.ownerId == _statusService.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showStatusDetail(status, allUserStatuses),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
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

              // ✅ Status count badge (restored)
              if (allUserStatuses.length > 1)
                Container(
                  margin: const EdgeInsets.only(right: 6),
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

              // ✅ Delete icon (only for my status)
              if (isMyStatus)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _openMyStatusesForDelete(allUserStatuses),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== Status Detail Screen =====================

class StatusDetailScreen extends StatefulWidget {
  final List<StatusModel> statuses;
  final int initialIndex;
  final String otherUserId;
  final bool deleteMode; // ✅ new

  const StatusDetailScreen({
    super.key,
    required this.statuses,
    required this.initialIndex,
    required this.otherUserId,
    this.deleteMode = false, // ✅ default
  });

  @override
  State<StatusDetailScreen> createState() => _StatusDetailScreenState();
}

class _StatusDetailScreenState extends State<StatusDetailScreen>
    with SingleTickerProviderStateMixin {
  final StatusService _statusService = StatusService();
  final TextEditingController _commentController = TextEditingController();

  late AnimationController _progressController;
  late int _currentIndex;

  late List<StatusModel> _statuses;

  bool get _isMyStatus =>
      _statuses.isNotEmpty &&
      _statuses[_currentIndex].ownerId == _statusService.currentUser?.uid;

  bool _deleteSheetOpen = false; // ✅ prevent multiple bottom sheets

  @override
  void initState() {
    super.initState();
    _statuses = List<StatusModel>.from(widget.statuses);
    _currentIndex = widget.initialIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentIndex < _statuses.length - 1) {
          setState(() {
            _currentIndex++;
            _progressController.forward(from: 0);
          });
          _showDeleteSheetIfNeeded(); // ✅ show when moved
        } else {
          Navigator.pop(context);
        }
      }
    });

    // ✅ show for first status if delete mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDeleteSheetIfNeeded();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _nextStatus() {
    if (_currentIndex < _statuses.length - 1) {
      setState(() {
        _currentIndex++;
        _progressController.forward(from: 0);
      });
      _showDeleteSheetIfNeeded();
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStatus() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progressController.forward(from: 0);
      });
      _showDeleteSheetIfNeeded();
    }
  }

  void _showDeleteSheetIfNeeded() {
    if (!widget.deleteMode) return;
    if (!_isMyStatus) return;
    if (!mounted) return;
    if (_deleteSheetOpen) return;

    _deleteSheetOpen = true;

    // pause progress while sheet is open
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Delete this status?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // close sheet
                  await _confirmDeleteCurrent(); // delete
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  side: BorderSide(color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _deleteSheetOpen = false;
      if (mounted) {
        _progressController.forward(); // resume
      }
    });
  }

  Future<void> _confirmDeleteCurrent() async {
    final current = _statuses[_currentIndex];

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete status?'),
        content: const Text('This will permanently delete this status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) {
      if (mounted) _progressController.forward();
      return;
    }

    try {
      await _statusService.deleteStatus(current.statusId);

      if (!mounted) return;

      setState(() {
        _statuses.removeAt(_currentIndex);

        if (_statuses.isEmpty) {
          Navigator.pop(context);
          return;
        }

        if (_currentIndex >= _statuses.length) {
          _currentIndex = _statuses.length - 1;
        }
      });

      _progressController.forward(from: 0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status deleted')),
      );

      // ✅ after delete, show delete sheet for next status (if still delete mode)
      _showDeleteSheetIfNeeded();
    } catch (e) {
      if (mounted) {
        _progressController.forward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    _progressController.stop();

    try {
      await _statusService.addComment(
        _statuses[_currentIndex].statusId,
        _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();

      _progressController.forward();
    } catch (e) {
      _progressController.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_statuses.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentStatus = _statuses[_currentIndex];

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
              backgroundImage: currentStatus.ownerPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(currentStatus.ownerPhoto)
                  : null,
              child: currentStatus.ownerPhoto.isEmpty
                  ? Text(
                      currentStatus.ownerName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStatus.ownerName,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                Text(
                  timeago.format(currentStatus.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ✅ normal delete icon (for manual delete)
          if (_isMyStatus)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _confirmDeleteCurrent,
            ),
        ],
      ),
      body: StreamBuilder<List<StatusModel>>(
        stream: _statusService.getActiveStatuses(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: List.generate(_statuses.length, (index) {
                        double value;
                        if (index < _currentIndex) {
                          value = 1;
                        } else if (index == _currentIndex) {
                          value = _progressController.value;
                        } else {
                          value = 0;
                        }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: value,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final tapX = details.globalPosition.dx;

                    if (tapX < screenWidth / 2) {
                      _previousStatus();
                    } else {
                      _nextStatus();
                    }
                  },
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
                              currentStatus.text ?? '',
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
              ),
              Container(
                color: Colors.grey.shade900,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('${currentStatus.viewCount} views',
                            style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 16),
                        Icon(Icons.comment,
                            size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text('${currentStatus.commentCount} comments',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
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
                                    backgroundImage: comment.userPhoto.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            comment.userPhoto)
                                        : null,
                                    child: comment.userPhoto.isEmpty
                                        ? Text(
                                            comment.userName[0].toUpperCase(),
                                            style:
                                                const TextStyle(fontSize: 10),
                                          )
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            onTap: () => _progressController.stop(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle:
                                  TextStyle(color: Colors.grey.shade500),
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
                          icon: const Icon(Icons.send,
                              color: Color(0xFF4A90A4)),
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
