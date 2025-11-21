import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/user.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../widgets/modern_post_card.dart';
import '../profile/profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByCurrentUser;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load comments when screen is displayed (works on both first visit and return visits)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<PostsBloc>().state;
        // Only load if comments don't exist yet for this post
        if (state is PostsLoaded) {
          final hasComments = state.commentsByPostId.containsKey(widget.post.id);
          if (!hasComments) {
            context.read<PostsBloc>().add(LoadComments(widget.post.id));
          }
        } else {
          // State not loaded yet, trigger load
          context.read<PostsBloc>().add(LoadComments(widget.post.id));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Postingan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000000), size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      ModernPostCard(
                        post: widget.post,
                        showCommentPreview: false,
                        showActionBar: false,
                      ),
                      // Action Bar for Post Detail
                      BlocBuilder<PostsBloc, PostsState>(
                        builder: (context, state) {
                          // Get updated post from state if available
                          Post currentPost = widget.post;
                          if (state is PostsLoaded) {
                            try {
                              final updatedPost = state.posts.firstWhere(
                                (p) => p.id == widget.post.id,
                              );
                              currentPost = updatedPost;
                            } catch (e) {
                              // Post not found in state, use widget.post
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
                          }

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: _buildDetailActionBar(context, currentPost),
                          );
                        },
                      ),
                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.grey.shade200,
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Comments Section Title
                      if (state is PostsLoaded &&
                          (state.commentsByPostId[widget.post.id]?.isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                          child: Row(
                            children: [
                              Text(
                                'Komentar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF8F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${widget.post.commentsCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (state is PostsLoaded) ...[
                        () {
                          final comments = state.commentsByPostId[widget.post.id] ?? [];

                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                          const Color(0xFFEC4899).withValues(alpha: 0.1),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 50,
                                      color: Color(0xFFB8AFA0),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Belum ada komentar nih',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF000000),
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Yuk jadi yang pertama komen!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              return _buildCommentItem(comments[index]);
                            },
                          );
                        }(),
                      ] else
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFF84994F),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        final isSending = state is PostsLoaded && state.sendingCommentIds.contains(comment.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userId: comment.author.id,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFFAF8F5),
                      child: Text(
                        comment.author.name.isNotEmpty
                            ? comment.author.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF84994F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                comment.author.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF000000),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${timeago.format(comment.createdAt, locale: 'en_short')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (isSending) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• Mengirim...',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSending ? const Color(0xFF9CA3AF) : const Color(0xFF1a1a1a),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isSending ? null : () {
                      context.read<PostsBloc>().add(
                            LikeCommentToggled(
                              widget.post.id,
                              comment.id,
                              comment.isLikedByCurrentUser,
                            ),
                          );
                    },
                    child: Opacity(
                      opacity: isSending ? 0.5 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: comment.isLikedByCurrentUser
                            ? const Color(0xFFFFE8E8)
                            : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: comment.isLikedByCurrentUser
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF999999),
                            ),
                            if (comment.likesCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '${comment.likesCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: comment.isLikedByCurrentUser
                                    ? const Color(0xFFFF6B6B)
                                    : const Color(0xFF999999),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis komentar lo...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _submitComment,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitComment() {
    if (_commentController.text.trim().isEmpty) return;

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

    // Generate temporary UUID for optimistic update
    final tempId = 'temp_${Uuid().v4()}';

    final comment = Comment(
      id: tempId,
      postId: widget.post.id,
      author: currentUser,
      content: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    context.read<PostsBloc>().add(CreateCommentRequested(comment));
    _commentController.clear();
  }

  Widget _buildDetailActionBar(BuildContext context, Post currentPost) {
    return Row(
      children: [
        // Like/Save Button
        Expanded(
          child: GestureDetector(
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
                    decoration: BoxDecoration(
                      color: _isLiked
                        ? const Color(0xFFE8EDDA)
                        : const Color(0xFFFAF8F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '⭐',
                          style: TextStyle(
                            fontSize: 20 * (_isLiked ? 1.1 : 1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentPost.likesCount > 0
                            ? '${currentPost.likesCount} Simpan'
                            : 'Simpan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _isLiked ? FontWeight.w700 : FontWeight.w600,
                            color: _isLiked
                              ? const Color(0xFF84994F)
                              : const Color(0xFF262626),
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
        ),
        const SizedBox(width: 12),
        // Share Button
        Expanded(
          child: GestureDetector(
            onTap: _sharePost,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔗', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text(
                    'Bagikan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF262626),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _sharePost() {
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
                          icon: Icons.copy,
                          label: 'Salin Link',
                          color: Colors.grey[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            _copyPostLink();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.message,
                          label: 'WhatsApp',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _shareToWhatsApp();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.facebook,
                          label: 'Facebook',
                          color: Colors.blue[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            _shareToFacebook();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.alternate_email,
                          label: 'Twitter',
                          color: Colors.lightBlue,
                          onTap: () {
                            Navigator.pop(context);
                            _shareToTwitter();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pop(context);
                            _shareToInstagram();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.email,
                          label: 'Email',
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _shareViaEmail();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.share,
                          label: 'Lainnya',
                          color: Colors.grey[600]!,
                          onTap: () {
                            Navigator.pop(context);
                            _shareMore();
                          },
                        ),
                        _buildShareOption(
                          icon: Icons.qr_code,
                          label: 'QR Code',
                          color: Colors.black,
                          onTap: () {
                            Navigator.pop(context);
                            _showQRCode();
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
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFFAF8F5),
                            child: Text(
                              widget.post.author.name.isNotEmpty
                                  ? widget.post.author.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF84994F),
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

  Widget _buildShareOption({
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

  void _copyPostLink() {
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

  void _shareToWhatsApp() {
    _showShareMessage('WhatsApp');
  }

  void _shareToFacebook() {
    _showShareMessage('Facebook');
  }

  void _shareToTwitter() {
    _showShareMessage('Twitter');
  }

  void _shareToInstagram() {
    _showShareMessage('Instagram Stories');
  }

  void _shareViaEmail() {
    _showShareMessage('Email');
  }

  void _shareMore() {
    _showShareMessage('system share dialog');
  }

  void _showQRCode() {
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
              _copyPostLink();
            },
            child: const Text('Simpan QR'),
          ),
        ],
      ),
    );
  }

  void _showShareMessage(String platform) {
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

  @override
  void dispose() {
    _commentController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }
}
