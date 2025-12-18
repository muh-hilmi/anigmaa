import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../pages/post_detail/post_detail_screen.dart';

class CommentPreview extends StatefulWidget {
  final Post post;
  final bool showCommentPreview;
  final bool showActionBar;

  const CommentPreview({
    super.key,
    required this.post,
    this.showCommentPreview = true,
    this.showActionBar = true,
  });

  @override
  State<CommentPreview> createState() => _CommentPreviewState();
}

class _CommentPreviewState extends State<CommentPreview> {
  List<Map<String, String>> _previewComments = [];

  @override
  void initState() {
    super.initState();
    _loadCommentPreview();
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
    if (!widget.showCommentPreview || widget.post.commentsCount == 0) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<PostsBloc, PostsState>(
      builder: (context, state) {
        if (state is PostsLoaded &&
            state.commentsByPostId.containsKey(widget.post.id)) {
          final comments = state.commentsByPostId[widget.post.id]!;
          if (comments.isNotEmpty) {
            _previewComments = comments.take(3).map((comment) {
              return {
                'author': comment.author.name,
                'content': comment.content,
              };
            }).toList();
          }
        }

        // Show loading skeleton if comments should exist but haven't loaded yet
        if (_previewComments.isEmpty && widget.post.commentsCount > 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFC),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: comment['content'],
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
              );
            }),
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
      },
    );
  }
}
