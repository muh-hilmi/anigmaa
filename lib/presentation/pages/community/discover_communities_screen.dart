import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/entities/community_category.dart';
import '../../bloc/communities/communities_bloc.dart';
import '../../bloc/communities/communities_state.dart';
import '../../bloc/communities/communities_event.dart';
import 'community_detail_screen.dart';

/// X-style Discover Communities Screen
/// Shows communities with recent post previews
class DiscoverCommunitiesScreen extends StatefulWidget {
  const DiscoverCommunitiesScreen({super.key});

  @override
  State<DiscoverCommunitiesScreen> createState() =>
      _DiscoverCommunitiesScreenState();
}

class _DiscoverCommunitiesScreenState extends State<DiscoverCommunitiesScreen> {
  CommunityCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<CommunitiesBloc>().add(LoadCommunities());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: BlocBuilder<CommunitiesBloc, CommunitiesState>(
              builder: (context, state) {
                if (state is CommunitiesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF84994F),
                    ),
                  );
                }

                if (state is CommunitiesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load communities',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context
                                .read<CommunitiesBloc>()
                                .add(LoadCommunities());
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CommunitiesLoaded) {
                  var communities = state.filteredCommunities;

                  // Filter by category if selected
                  if (_selectedCategory != null) {
                    communities = communities
                        .where((c) => c.category == _selectedCategory)
                        .toList();
                  }

                  if (communities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No communities found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF84994F),
                    onRefresh: () async {
                      context.read<CommunitiesBloc>().add(LoadCommunities());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        return _CommunityCard(
                          community: communities[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommunityDetailScreen(
                                  community: communities[index],
                                ),
                              ),
                            );
                          },
                          onJoin: () {
                            context
                                .read<CommunitiesBloc>()
                                .add(JoinCommunity(communities[index].id));
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Discover Communities',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', null),
          ...CommunityCategory.values.map((category) {
            return _buildCategoryChip(
              category.displayName,
              category,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, CommunityCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF84994F).withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF84994F) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF84994F) : Colors.grey.shade300,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// Community Card Widget (X-style)
class _CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const _CommunityCard({
    required this.community,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Community Icon/Avatar
                _buildCommunityAvatar(),
                const SizedBox(width: 12),
                // Community Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (community.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Color(0xFF84994F),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            community.category.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            community.category.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            ' • ${_formatMemberCount(community.memberCount)} members',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Join Button
                _buildJoinButton(context),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              community.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Recent Posts Preview
            _buildRecentPostsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityAvatar() {
    if (community.icon != null && community.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: community.icon!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 56,
            height: 56,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF84994F),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF84994F).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          community.name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF84994F),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    return OutlinedButton(
      onPressed: onJoin,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF84994F),
        side: const BorderSide(color: Color(0xFF84994F)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(70, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text(
        'Join',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecentPostsPreview() {
    // Mock recent posts data (replace with real data from API)
    final mockPosts = _getMockPosts();

    if (mockPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.article_outlined, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined,
                  size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Recent posts',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...mockPosts.take(2).map((post) => _buildPostPreview(post)),
        ],
      ),
    );
  }

  Widget _buildPostPreview(Map<String, dynamic> post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author avatar
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              post['author'][0].toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Post content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['author'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  post['content'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockPosts() {
    // Mock data - replace with real API call
    return [
      {
        'author': 'John Doe',
        'content': 'Just attended an amazing tech meetup! The discussions were insightful.',
      },
      {
        'author': 'Jane Smith',
        'content': 'Sharing some tips on getting started with Flutter development.',
      },
    ];
  }

  String _formatMemberCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
