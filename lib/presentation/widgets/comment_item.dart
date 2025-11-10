import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/comment.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final bool isReply;

  const CommentItem({
    super.key,
    required this.comment,
    this.onLike,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 48 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: isReply ? 16 : 20,
            backgroundImage: comment.author.avatar != null
                ? NetworkImage(comment.author.avatar!)
                : null,
            child: comment.author.avatar == null
                ? Text(
                    comment.author.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: isReply ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author name and time
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(comment.createdAt, locale: 'id'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                // Actions (Like, Reply)
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: onLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            comment.isLikedByCurrentUser
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: comment.isLikedByCurrentUser
                                ? const Color(0xFFED4956)
                                : Colors.grey[600],
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likesCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: comment.isLikedByCurrentUser
                                    ? const Color(0xFFED4956)
                                    : Colors.grey[600],
                                fontWeight: comment.isLikedByCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Reply button
                    if (!isReply && onReply != null)
                      InkWell(
                        onTap: onReply,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Balas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (comment.repliesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${comment.repliesCount})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (comment.editedAt != null) ...[
                      const Spacer(),
                      Text(
                        'diedit',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
