import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/comment.dart';
import '../bloc/posts/posts_bloc.dart';
import '../bloc/posts/posts_event.dart';
import '../bloc/posts/posts_state.dart';
import '../bloc/user/user_bloc.dart';
import '../bloc/user/user_state.dart';
import 'comment_item.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final int initialCommentsCount;

  const CommentSection({
    super.key,
    required this.postId,
    this.initialCommentsCount = 0,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  String? _replyToCommentId;
  String? _replyToAuthorName;

  @override
  void initState() {
    super.initState();
    // Load comments when section is created
    context.read<PostsBloc>().add(LoadComments(widget.postId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _handleReply(Comment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAuthorName = comment.author.name;
    });
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAuthorName = null;
    });
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to comment')),
      );
      return;
    }

    final comment = Comment(
      id: '', // Will be assigned by backend
      postId: widget.postId,
      author: userState.user,
      content: content,
      createdAt: DateTime.now(),
      parentCommentId: _replyToCommentId,
    );

    context.read<PostsBloc>().add(CreateCommentRequested(comment));
    _commentController.clear();
    _cancelReply();
    _commentFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<PostsBloc, PostsState>(
            builder: (context, state) {
              final comments = state is PostsLoaded
                  ? state.commentsByPostId[widget.postId] ?? []
                  : [];

              return Text(
                'Komentar (${comments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),

        // Comment input
        _buildCommentInput(),

        const Divider(height: 1),

        // Comments list
        BlocBuilder<PostsBloc, PostsState>(
          builder: (context, state) {
            if (state is PostsLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is! PostsLoaded) {
              return const SizedBox.shrink();
            }

            final comments = state.commentsByPostId[widget.postId] ?? [];

            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada komentar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jadilah yang pertama berkomentar!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Separate top-level comments and replies
            final topLevelComments = comments.where((c) => !c.isReply).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topLevelComments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final comment = topLevelComments[index];
                final replies = comments
                    .where((c) => c.parentCommentId == comment.id)
                    .toList();

                return Column(
                  children: [
                    CommentItem(
                      comment: comment,
                      onLike: () {
                        context.read<PostsBloc>().add(
                              LikeCommentToggled(
                                widget.postId,
                                comment.id,
                                comment.isLikedByCurrentUser,
                              ),
                            );
                      },
                      onReply: () => _handleReply(comment),
                    ),
                    // Show replies
                    if (replies.isNotEmpty)
                      ...replies.map(
                        (reply) => CommentItem(
                          comment: reply,
                          isReply: true,
                          onLike: () {
                            context.read<PostsBloc>().add(
                                  LikeCommentToggled(
                                    widget.postId,
                                    reply.id,
                                    reply.isLikedByCurrentUser,
                                  ),
                                );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply indicator
          if (_replyToAuthorName != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Membalas $_replyToAuthorName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Comment input field
          Row(
            children: [
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UserLoaded) {
                    return CircleAvatar(
                      radius: 18,
                      backgroundImage: state.user.avatar != null
                          ? NetworkImage(state.user.avatar!)
                          : null,
                      child: state.user.avatar == null
                          ? Text(
                              state.user.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 14),
                            )
                          : null,
                    );
                  }
                  return const CircleAvatar(radius: 18);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submitComment,
                icon: const Icon(Icons.send),
                color: const Color(0xFF6C63FF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
