import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool get canPost => _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        User? currentUser;
        if (userState is UserLoaded && userState.user != null) {
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
              onPressed: () {
                // TODO: Add location
              },
              icon: Icon(Icons.location_on_outlined, color: Colors.grey.shade700),
              tooltip: 'Tambahin lokasi',
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

  void _createPost() {
    final userState = context.read<UserBloc>().state;
    User? currentUser;
    if (userState is UserLoaded && userState.user != null) {
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
    if (_selectedImages.isNotEmpty) {
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
      // TODO: Add attachedEvent support - need UI to select event
    );

    Navigator.pop(context, post);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
