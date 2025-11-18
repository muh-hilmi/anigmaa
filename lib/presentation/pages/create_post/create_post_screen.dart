import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_state.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  Event? _selectedEvent; // For event tagging

  bool get canPost => _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        User? currentUser;
        if (userState is UserLoaded) {
          currentUser = userState.user;
        }

        return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bikin Post',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: canPost ? _createPost : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text('Posting'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: currentUser?.avatar != null
                            ? NetworkImage(currentUser!.avatar!)
                            : null,
                        child: currentUser?.avatar == null
                            ? Text(
                                currentUser?.name.isNotEmpty == true
                                    ? currentUser!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: "Lagi ngapain nih?",
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          style: const TextStyle(fontSize: 18),
                          maxLines: null,
                          autofocus: true,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildImageGrid(),
                  ],
                  if (_selectedEvent != null) ...[
                    const SizedBox(height: 16),
                    _buildEventChip(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
      },
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_selectedImages[index]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImages.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _pickImages,
              icon: Icon(Icons.image_outlined, color: Colors.grey.shade700),
              tooltip: 'Tambahin foto',
            ),
            IconButton(
              onPressed: () {
                // TODO: Add GIF picker
              },
              icon: Icon(Icons.gif_box_outlined, color: Colors.grey.shade700),
              tooltip: 'Tambahin GIF',
            ),
            IconButton(
              onPressed: () {
                // TODO: Add poll
              },
              icon: Icon(Icons.poll_outlined, color: Colors.grey.shade700),
              tooltip: 'Tambahin polling',
            ),
            IconButton(
              onPressed: _showEventSelector,
              icon: Icon(
                Icons.event_outlined,
                color: _selectedEvent != null ? const Color(0xFF84994F) : Colors.grey.shade700,
              ),
              tooltip: 'Tag event',
            ),
            const Spacer(),
            if (_textController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCharCountColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_textController.text.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getCharCountColor(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCharCountColor() {
    final length = _textController.text.length;
    if (length > 500) return Colors.red;
    if (length > 400) return Colors.orange;
    return Colors.grey.shade700;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && _selectedImages.length + images.length <= 4) {
        setState(() {
          _selectedImages.addAll(images.map((img) => img.path).toList());
        });
      } else if (_selectedImages.length + images.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal 4 foto aja yaa!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waduh... gagal pilih foto nih'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEventChip() {
    if (_selectedEvent == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF84994F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF84994F), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Color(0xFF84994F), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEvent!.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedEvent!.location.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedEvent = null),
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showEventSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Pilih Event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<UserBloc, UserState>(
                builder: (context, userState) {
                  User? currentUser;
                  if (userState is UserLoaded) {
                    currentUser = userState.user;
                  }

                  return BlocBuilder<EventsBloc, EventsState>(
                    builder: (context, state) {
                      if (state is EventsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is EventsLoaded) {
                        // Get user's events (hosted + joined)
                        final userEvents = state.events.where((event) {
                          final isHosted = currentUser != null && event.host.id == currentUser.id;
                          final isJoined = currentUser != null && event.attendeeIds.contains(currentUser.id);
                          return isHosted || isJoined;
                        }).toList();

                    if (userEvents.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada event nih',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bikin atau join event dulu yaa!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: userEvents.length,
                      itemBuilder: (context, index) {
                        final event = userEvents[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedEvent = event);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        event.imageUrls.isNotEmpty
                                            ? event.imageUrls.first
                                            : 'https://doodleipsum.com/200x200/abstract',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        event.location.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                      return const Center(child: Text('Failed to load events'));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createPost() {
    final userState = context.read<UserBloc>().state;
    User? currentUser;
    if (userState is UserLoaded) {
      currentUser = userState.user;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waduh... user belum dimuat. Coba lagi yaa!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Determine post type
    PostType type = PostType.text;
    if (_selectedEvent != null) {
      // Event tagging takes precedence - can have event with or without images
      type = PostType.textWithEvent;
    } else if (_selectedImages.isNotEmpty) {
      type = PostType.textWithImages;
    }

    // Convert local image paths to network URLs (in real app, upload to server first)
    final imageUrls = _selectedImages.map((path) {
      // For now, use placeholder. In production, upload to cloud storage
      return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/600';
    }).toList();

    // IMPORTANT: This ID is temporary and will be replaced by backend
    // The repository layer does NOT send this ID to backend - backend generates its own ID
    // This is only needed because Post entity requires an ID field
    final post = Post(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      author: currentUser,
      content: _textController.text.trim(),
      type: type,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      attachedEvent: _selectedEvent, // Event tagging feature
    );

    Navigator.pop(context, post);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
