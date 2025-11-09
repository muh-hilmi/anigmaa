import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/post.dart';
import '../bloc/posts/posts_bloc.dart';
import '../bloc/posts/posts_event.dart';
import '../bloc/posts/posts_state.dart';
import '../pages/post_detail/post_detail_screen.dart';
import '../pages/event_detail/event_detail_screen.dart';
import '../pages/social/user_profile_screen.dart';
import 'modern_event_mini_card.dart';
import 'find_matches_modal.dart';

enum ReactionType {
  like,
  love,
  haha,
  wow,
  sad,
  angry,
}

extension ReactionTypeExtension on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😡';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Suka';
      case ReactionType.love:
        return 'Cinta';
      case ReactionType.haha:
        return 'Lucu';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sedih';
      case ReactionType.angry:
        return 'Marah';
    }
  }

  Color get color {
    switch (this) {
      case ReactionType.like:
        return const Color(0xFF0866FF);
      case ReactionType.love:
        return const Color(0xFFED4956);
      case ReactionType.haha:
        return const Color(0xFFF7B125);
      case ReactionType.wow:
        return const Color(0xFFF7B125);
      case ReactionType.sad:
        return const Color(0xFFF7B125);
      case ReactionType.angry:
        return const Color(0xFFE9710F);
    }
  }
}

class ModernPostCard extends StatefulWidget {
  final Post post;
  final bool showCommentPreview;
  final bool showActionBar;

  ModernPostCard({
    super.key,
    required this.post,
    this.showCommentPreview = true,
    this.showActionBar = true,
  }) {
    if (post.attachedEvent != null) {
      print('[ModernPostCard] Created with attached event: ${post.attachedEvent!.title}');
    }
  }

  @override
  State<ModernPostCard> createState() => _ModernPostCardState();
}

class _ModernPostCardState extends State<ModernPostCard> with SingleTickerProviderStateMixin {
  List<Map<String, String>> _previewComments = [];
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;
    _loadCommentPreview();

    // Setup animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _likeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadCommentPreview() {
    if (widget.showCommentPreview && widget.post.commentsCount > 0) {
      // Load comments via BLoC after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PostsBloc>().add(LoadComments(widget.post.id));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        try {
          // Get updated post from state if available
          Post currentPost = widget.post;
        if (state is PostsLoaded) {
          try {
            final updatedPost = state.posts.firstWhere(
              (p) => p.id == widget.post.id,
            );
            currentPost = updatedPost;
          } catch (e) {
            // Post not found in state, keep using widget.post
            currentPost = widget.post;
          }

          // Sync local state with bloc state
          if (_isLiked != currentPost.isLikedByCurrentUser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLiked = currentPost.isLikedByCurrentUser;
                });
              }
            });
          }

          // Extract comment preview from state if available
          if (state.commentsByPostId.containsKey(widget.post.id)) {
            final comments = state.commentsByPostId[widget.post.id]!;
            if (comments.isNotEmpty) {
              final newPreviewComments = comments.take(3).map((comment) {
                return {
                  'author': comment.author.name,
                  'content': comment.content,
                };
              }).toList();

              // Only update if changed to avoid unnecessary rebuilds
              if (_previewComments.length != newPreviewComments.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _previewComments = newPreviewComments;
                    });
                  }
                });
              }
            }
          }
        }

        final cardContent = Container(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _buildPostHeader(context),
          ),

          // Post Text Content
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _buildPostContent(),
            ),

          // Post Images
          if (widget.post.imageUrls.isNotEmpty) _buildPostImages(),

          // Event Mini Card (if has event)
          if (widget.post.attachedEvent != null) ...[
            Builder(
              builder: (context) {
                print('[ModernPostCard] Rendering attached event: ${widget.post.attachedEvent!.title}');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildEventAttachment(context),
                );
              },
            ),
          ],

          // Poll (if has poll)
          if (widget.post.poll != null) _buildPoll(),

          // Action Bar
          if (widget.showActionBar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildActionBar(context, currentPost),
            ),

          // Comment Preview
          if (widget.showCommentPreview && widget.post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _buildCommentPreview(),
            ),
        ],
          ),
        );

        // Only wrap with GestureDetector if showActionBar is true (not in detail view)
        if (widget.showActionBar) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: widget.post),
                ),
              );
            },
            child: cardContent,
          );
        }

        return cardContent;
        } catch (e, stackTrace) {
          print('[ModernPostCard] Error building card: $e');
          print('[ModernPostCard] Stack trace: $stackTrace');
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error displaying post: $e'),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: widget.post.author.id,
                  userName: widget.post.author.name,
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFAF8F5),
            child: Text(
              widget.post.author.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF84994F),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // User info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.author.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF000000),
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                timeago.format(widget.post.createdAt, locale: 'en_short'),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // More Menu - rounded button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_horiz_rounded, size: 22, color: Color(0xFF262626)),
            onPressed: () => _showPostMenu(context),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent() {
    return Text(
      widget.post.content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Color(0xFF1a1a1a),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildPostImages() {
    if (widget.post.imageUrls.length == 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            widget.post.imageUrls[0],
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.grey[400]),
                ),
              );
            },
          ),
        ),
      );
    }

    // Grid for multiple images with rounded corners
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: widget.post.imageUrls.length > 4 ? 4 : widget.post.imageUrls.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.post.imageUrls[index],
                  fit: BoxFit.cover,
                ),
                if (index == 3 && widget.post.imageUrls.length > 4)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+${widget.post.imageUrls.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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

  Widget _buildEventAttachment(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to event detail - stop propagation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: widget.post.attachedEvent!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ModernEventMiniCard(
          event: widget.post.attachedEvent!,
          onJoin: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Mantap! Lo udah ikutan event ini. Cek "Cari Temen" yuk!'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: const Color(0xFF84994F),
              ),
            );
          },
          onFindMatches: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) => FindMatchesModal(
                  eventId: widget.post.attachedEvent!.id,
                  eventTitle: widget.post.attachedEvent!.title,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPoll() {
    // TODO: Implement modern poll design
    return const SizedBox.shrink();
  }

  Widget _buildActionBar(BuildContext context, Post currentPost) {
    return Row(
      children: [
        // Like Button - more prominent
        GestureDetector(
          onTap: () {
            final newLikedState = !currentPost.isLikedByCurrentUser;
            setState(() {
              _isLiked = newLikedState;
            });
            _likeAnimationController.forward(from: 0.0);
            context.read<PostsBloc>().add(
              LikePostToggled(currentPost.id, currentPost.isLikedByCurrentUser),
            );
          },
          child: AnimatedBuilder(
            animation: _likeScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _likeScaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isLiked ? const Color(0xFFE8EDDA) : const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLiked ? '⭐' : '⭐',
                        style: TextStyle(
                          fontSize: 19 * (_isLiked ? 1.1 : 1.0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currentPost.likesCount > 0 ? _formatCount(currentPost.likesCount) : 'Simpan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _isLiked ? FontWeight.w700 : FontWeight.w600,
                          color: _isLiked ? const Color(0xFF84994F) : const Color(0xFF262626),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          emoji: '💬',
          label: widget.post.commentsCount > 0 ? _formatCount(widget.post.commentsCount) : 'Tanya',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: widget.post),
              ),
            );
          },
        ),
        const Spacer(),
        _buildActionButton(
          emoji: '🔗',
          label: 'Bagikan',
          onTap: () => _sharePost(context),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 19),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF262626),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentPreview() {
    if (_previewComments.isEmpty) {
      return const SizedBox.shrink();
    }

    final commentContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.post.commentsCount > _previewComments.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Liat semua ${widget.post.commentsCount} komentar',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ..._previewComments.map((comment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1a1a1a),
                  height: 1.4,
                  letterSpacing: -0.1,
                ),
                children: [
                  TextSpan(
                    text: '${comment['author']} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: comment['content'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );

    // Only wrap with GestureDetector if showActionBar is true (not in detail view)
    if (widget.showActionBar) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: widget.post),
            ),
          );
        },
        child: commentContent,
      );
    }

    return commentContent;
  }


  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E4DD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                context,
                icon: Icons.bookmark_border_rounded,
                iconColor: const Color(0xFF84994F),
                backgroundColor: const Color(0xFFE8EDDA),
                title: 'Simpan Post',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF6B6B6B),
                backgroundColor: const Color(0xFFFAF8F5),
                title: 'Salin Link',
                onTap: () => Navigator.pop(context),
              ),
              _buildMenuItem(
                context,
                icon: Icons.flag_outlined,
                iconColor: const Color(0xFFFF6B6B),
                backgroundColor: const Color(0xFFFFEBEE),
                title: 'Laporin',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Bagikan Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildShareOption(
                          context,
                          icon: Icons.copy,
                          label: 'Salin Link',
                          color: Colors.grey[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            _copyPostLink(context);
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.message,
                          label: 'WhatsApp',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _showShareMessage(context, 'WhatsApp');
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: Colors.blue[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            _showShareMessage(context, 'Facebook');
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.alternate_email,
                          label: 'Twitter',
                          color: Colors.lightBlue,
                          onTap: () {
                            Navigator.pop(context);
                            _showShareMessage(context, 'Twitter');
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pop(context);
                            _showShareMessage(context, 'Instagram Stories');
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.email,
                          label: 'Email',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _showShareMessage(context, 'Email');
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.share,
                          label: 'Lainnya',
                          color: Colors.grey[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            _showShareMessage(context, 'system share dialog');
                          },
                        ),
                        _buildShareOption(
                          context,
                          icon: Icons.qr_code,
                          label: 'QR Code',
                          color: Colors.black,
                          onTap: () {
                            Navigator.pop(context);
                            _showQRCode(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close dialog first
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    userId: widget.post.author.id,
                                    userName: widget.post.author.name,
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFAF8F5),
                              child: Text(
                                widget.post.author.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF84994F),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.author.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.post.content.length > 50
                                      ? '${widget.post.content.substring(0, 50)}...'
                                      : widget.post.content,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _copyPostLink(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Link post udah disalin nih!'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 80, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('QR Code Here'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan buat liat detail postingan',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyPostLink(context);
            },
            child: const Text('Simpan QR'),
          ),
        ],
      ),
    );
  }

  void _showShareMessage(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lagi buka $platform...'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
