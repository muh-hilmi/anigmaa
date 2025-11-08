import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/event_category.dart';
import '../bloc/posts/posts_bloc.dart';
import '../bloc/posts/posts_event.dart';
import '../pages/post_detail/post_detail_screen.dart';
import '../pages/social/user_profile_screen.dart';
import 'event_mini_card.dart';
import 'find_matches_modal.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Repost header (if this is a repost)
              if (post.type == PostType.repost && post.repostAuthor != null)
                _buildRepostHeader(context),

              // Author info
              _buildAuthorHeader(context),

              const SizedBox(height: 12),

              // Post content
              if (post.content.isNotEmpty) _buildContent(context),

              // Images
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImages(context),
              ],

              // Attached event - PROMINENT DISPLAY
              if (post.attachedEvent != null) ...[
                const SizedBox(height: 16),
                EventMiniCard(
                  event: post.attachedEvent!,
                  onJoin: () {
                    // Check if event has ended
                    if (post.attachedEvent!.hasEnded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event ini udah selesai, gabisa join lagi nih!'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // TODO: Handle join event
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mantap! Lo udah ikutan event ini. Cek "Cari Temen" buat kenalan sama peserta lain yuk!'),
                        duration: Duration(seconds: 3),
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
                          eventId: post.attachedEvent!.id,
                          eventTitle: post.attachedEvent!.title,
                        ),
                      ),
                    );
                  },
                ),
              ],

              // Poll
              if (post.poll != null) ...[
                const SizedBox(height: 12),
                _buildPoll(context, post.poll!),
              ],

              // Original post (if this is a repost with quote)
              if (post.originalPost != null && post.content.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildQuotedPost(context, post.originalPost!),
              ],

              const SizedBox(height: 12),

              // Engagement buttons
              _buildEngagementBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepostHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            '${post.repostAuthor!.name} repost ini',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader(BuildContext context) {
    final displayPost = post.type == PostType.repost && post.originalPost != null
        ? post.originalPost!
        : post;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _navigateToProfile(context, displayPost.author.id);
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage: displayPost.author.avatar != null
                ? NetworkImage(displayPost.author.avatar!)
                : null,
            child: displayPost.author.avatar == null
                ? Text(
                    displayPost.author.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  _navigateToProfile(context, displayPost.author.id);
                },
                child: Row(
                  children: [
                    Text(
                      displayPost.author.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (displayPost.author.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    timeago.format(displayPost.createdAt, locale: 'en_short'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Event badge if post has event
              if (post.attachedEvent != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _getEventBadgeText(post.attachedEvent!.category),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, size: 20),
          onPressed: () => _showPostMenu(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  String _getEventBadgeText(EventCategory category) {
    switch (category) {
      case EventCategory.meetup:
        return 'EVENT · MEETUP';
      case EventCategory.sports:
        return 'EVENT · SPORTS';
      case EventCategory.workshop:
        return 'EVENT · WORKSHOP';
      case EventCategory.networking:
        return 'EVENT · NETWORK';
      case EventCategory.food:
        return 'EVENT · FOOD';
      case EventCategory.creative:
        return 'EVENT · CREATIVE';
      case EventCategory.outdoor:
        return 'EVENT · OUTDOOR';
      case EventCategory.fitness:
        return 'EVENT · FITNESS';
      case EventCategory.learning:
        return 'EVENT · LEARN';
      case EventCategory.social:
        return 'EVENT · SOCIAL';
    }
  }

  Widget _buildContent(BuildContext context) {
    return Text(
      post.content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.4,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    final imageCount = post.imageUrls.length;

    if (imageCount == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          post.imageUrls[0],
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 64),
            );
          },
        ),
      );
    } else if (imageCount == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: post.imageUrls.map((url) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Image.network(
                  url,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else if (imageCount >= 3) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Image.network(
              post.imageUrls[0],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Image.network(
                    post.imageUrls[1],
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    children: [
                      Image.network(
                        post.imageUrls[2],
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                      if (imageCount > 3)
                        Container(
                          height: 150,
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${imageCount - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Old event card removed - now using EventMiniCard

  Widget _buildPoll(BuildContext context, Poll poll) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...poll.options.map((option) {
            final percentage = poll.totalVotes > 0
                ? (option.votes / poll.totalVotes * 100)
                : 0.0;
            final isSelected = poll.votedOptionId == option.id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: poll.hasVoted || poll.isEnded ? null : () {
                  // TODO: Vote on poll
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.text,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            if (poll.hasVoted || poll.isEnded) ...[
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  isSelected ? Colors.blue : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (poll.hasVoted || poll.isEnded) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.blue : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            poll.isEnded
                ? 'Polling udah selesai • ${poll.totalVotes} suara'
                : '${poll.totalVotes} suara • Berakhir ${timeago.format(poll.endsAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedPost(BuildContext context, Post quotedPost) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: quotedPost.author.id,
                        userName: quotedPost.author.name,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: quotedPost.author.avatar != null
                      ? NetworkImage(quotedPost.author.avatar!)
                      : null,
                  child: quotedPost.author.avatar == null
                      ? Text(
                          quotedPost.author.name[0].toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                quotedPost.author.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                ' • ${timeago.format(quotedPost.createdAt, locale: 'en_short')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            quotedPost.content,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildEngagementButton(
          icon: Icons.chat_bubble_outline,
          count: post.commentsCount,
          color: Colors.grey.shade700,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: post),
              ),
            );
          },
        ),
        _buildEngagementButton(
          icon: Icons.repeat,
          count: post.repostsCount,
          color: post.isRepostedByCurrentUser ? Colors.green : Colors.grey.shade700,
          onTap: () => _handleRepost(context),
        ),
        _buildEngagementButton(
          icon: post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
          count: post.likesCount,
          color: post.isLikedByCurrentUser ? Colors.red : Colors.grey.shade700,
          onTap: () {
            context.read<PostsBloc>().add(
                  LikePostToggled(post.id, post.isLikedByCurrentUser),
                );
          },
        ),
        _buildEngagementButton(
          icon: Icons.ios_share,
          count: post.sharesCount,
          color: Colors.grey.shade700,
          onTap: () => _handleShare(context),
        ),
      ],
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleRepost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Repost'),
              onTap: () {
                Navigator.pop(context);
                context.read<PostsBloc>().add(RepostRequested(post.id));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Quote Tweet'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create post with quote
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleShare(BuildContext context) {
    Share.share(
      '${post.author.name} on Anigmaa:\n\n${post.content}\n\nJoin the conversation!',
      subject: 'Check out this post on Anigmaa',
    );
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Simpan Post'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Bookmark post
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Salin Link'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy link
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: Text('Follow ${post.author.name}'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Follow user
              },
            ),
            ListTile(
              leading: Icon(Icons.report_outlined, color: Colors.red.shade700),
              title: Text('Laporin', style: TextStyle(color: Colors.red.shade700)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report post
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, String userId) {
    // Cari nama user dari post
    String userName = post.author.name;

    // Jika post adalah repost, ambil nama dari original author
    if (post.type == PostType.repost && post.originalPost != null) {
      userName = post.originalPost!.author.name;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userName: userName,
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

}
