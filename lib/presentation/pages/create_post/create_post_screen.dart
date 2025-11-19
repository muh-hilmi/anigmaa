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

class _CreatePostScreenState extends State<CreatePostScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  Event? _selectedEvent;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  bool get canPost => _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        User? currentUser;
        if (userState is UserLoaded) {
          currentUser = userState.user;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F5),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Bikin Post 📝',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: Stack(
            children: [
              // Gradient Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFAF8F5),
                      const Color(0xFF84994F).withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // User Info & Text Input
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar with ring
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF84994F), Color(0xFFA8B968)],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
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
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentUser?.name ?? 'User',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF84994F).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.public,
                                              size: 12,
                                              color: Colors.grey[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Publik',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Text Input with modern styling
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _textController,
                                decoration: const InputDecoration(
                                  hintText: "Lagi ngapain nih? Ceritain dong! ✨",
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    fontSize: 17,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                                maxLines: null,
                                minLines: 4,
                                autofocus: true,
                                textCapitalization: TextCapitalization.sentences,
                                onChanged: (_) => setState(() {
                                  if (canPost) {
                                    _fabController.forward();
                                  } else {
                                    _fabController.reverse();
                                  }
                                }),
                              ),
                            ),

                            // Character Counter
                            if (_textController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildCharacterCounter(),
                            ],

                            // Event Tag
                            if (_selectedEvent != null) ...[
                              const SizedBox(height: 16),
                              _buildEventChipModern(),
                            ],

                            // Image Preview
                            if (_selectedImages.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildImageGridModern(),
                            ],

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBarModern(),
                  ],
                ),
              ),

              // Floating Post Button
              Positioned(
                bottom: 100,
                right: 20,
                child: ScaleTransition(
                  scale: _fabAnimation,
                  child: FloatingActionButton.extended(
                    onPressed: canPost ? _createPost : null,
                    backgroundColor: const Color(0xFF84994F),
                    elevation: 8,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text(
                      'Posting',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharacterCounter() {
    final length = _textController.text.length;
    final color = _getCharCountColor();
    final percentage = (length / 500).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$length',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGridModern() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _selectedImages.length == 1 ? 1 : 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: _selectedImages.length == 1 ? 16 / 9 : 1,
          ),
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(_selectedImages[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
                // Remove button
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Image number badge
                if (_selectedImages.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/${_selectedImages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBarModern() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            _buildActionButton(
              icon: Icons.image_rounded,
              label: 'Foto',
              color: const Color(0xFF6366F1),
              onTap: _pickImages,
              isActive: _selectedImages.isNotEmpty,
            ),
            const SizedBox(width: 6),
            _buildActionButton(
              icon: Icons.event_rounded,
              label: 'Event',
              color: const Color(0xFF84994F),
              onTap: _showEventSelector,
              isActive: _selectedEvent != null,
            ),
            const Spacer(),
            // Quick emoji reactions
            ..._buildQuickEmojis(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.4) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? color : Colors.grey[600],
              size: 19,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuickEmojis() {
    final emojis = ['😊', '🔥', '❤️'];
    return emojis.map((emoji) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _textController.text += emoji;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }).toList();
  }

  Color _getCharCountColor() {
    final length = _textController.text.length;
    if (length > 500) return Colors.red;
    if (length > 400) return Colors.orange;
    if (length > 300) return Colors.amber;
    return const Color(0xFF84994F);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && _selectedImages.length + images.length <= 4) {
        setState(() {
          _selectedImages.addAll(images.map((img) => img.path).toList());
          _fabController.forward();
        });
      } else if (_selectedImages.length + images.length > 4) {
        _showSnackBar('Maksimal 4 foto aja yaa! 📸', isError: true);
      }
    } catch (e) {
      _showSnackBar('Waduh... gagal pilih foto nih 😅', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF84994F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildEventChipModern() {
    if (_selectedEvent == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF84994F).withValues(alpha: 0.1),
            const Color(0xFF84994F).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF84994F).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF84994F).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Color(0xFF84994F),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEvent!.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _selectedEvent!.location.name,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedEvent = null),
            icon: Icon(Icons.close_rounded, size: 20, color: Colors.grey[600]),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
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
          color: Color(0xFFFAF8F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84994F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Color(0xFF84994F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pilih Event',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Events list
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
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF84994F),
                          ),
                        );
                      }

                      if (state is EventsLoaded) {
                        final userEvents = state.events.where((event) {
                          final isHosted =
                              currentUser != null && event.host.id == currentUser.id;
                          final isJoined = currentUser != null &&
                              event.attendeeIds.contains(currentUser.id);
                          return isHosted || isJoined;
                        }).toList();

                        if (userEvents.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.event_busy_rounded,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Belum ada event nih',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Bikin atau join event dulu yaa!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: userEvents.length,
                          itemBuilder: (context, index) {
                            final event = userEvents[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedEvent = event);
                                Navigator.pop(context);
                                _fabController.forward();
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        event.imageUrls.isNotEmpty
                                            ? event.imageUrls.first
                                            : 'https://doodleipsum.com/200x200/abstract',
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
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
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  event.location.name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.grey[400],
                                    ),
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
      _showSnackBar('Waduh... user belum dimuat. Coba lagi yaa!', isError: true);
      return;
    }

    PostType type = PostType.text;
    if (_selectedEvent != null) {
      type = PostType.textWithEvent;
    } else if (_selectedImages.isNotEmpty) {
      type = PostType.textWithImages;
    }

    final imageUrls = _selectedImages.map((path) {
      return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/600';
    }).toList();

    final post = Post(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      author: currentUser,
      content: _textController.text.trim(),
      type: type,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
      attachedEvent: _selectedEvent,
    );

    Navigator.pop(context, post);
    _showSnackBar('Post lo udah live! 🎉');
  }

  @override
  void dispose() {
    _textController.dispose();
    _fabController.dispose();
    super.dispose();
  }
}
