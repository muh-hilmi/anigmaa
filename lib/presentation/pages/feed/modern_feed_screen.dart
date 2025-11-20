import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../bloc/ranked_feed/ranked_feed_bloc.dart';
import '../../bloc/ranked_feed/ranked_feed_event.dart';
import '../../bloc/ranked_feed/ranked_feed_state.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../widgets/modern_post_card.dart';
import '../create_post/create_post_screen.dart';
import '../../../injection_container.dart';

class ModernFeedScreen extends StatefulWidget {
  const ModernFeedScreen({super.key});

  @override
  State<ModernFeedScreen> createState() => _ModernFeedScreenState();
}

class _ModernFeedScreenState extends State<ModernFeedScreen> {
  late ScrollController _scrollController;
  late RankedFeedBloc _rankedFeedBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _rankedFeedBloc = sl<RankedFeedBloc>();

    // Load posts and events
    context.read<PostsBloc>().add(LoadPosts());
    context.read<EventsBloc>().add(LoadEvents());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rankedFeedBloc.close();
    super.dispose();
  }

  void _loadRankedFeed(List<Post> posts, List<Event> events) {
    _rankedFeedBloc.add(LoadRankedFeed(posts: posts, events: events));
  }

  List<Post> _sortPostsByRanking(List<Post> posts, List<String> rankedIds) {
    if (rankedIds.isEmpty) return posts;

    // Create map for O(1) lookup
    final postMap = {for (var post in posts) post.id: post};

    // Sort posts according to ranked IDs
    final sortedPosts = <Post>[];
    for (final id in rankedIds) {
      if (postMap.containsKey(id)) {
        sortedPosts.add(postMap[id]!);
      }
    }

    // Add remaining posts that weren't in ranking
    for (final post in posts) {
      if (!rankedIds.contains(post.id)) {
        sortedPosts.add(post);
      }
    }

    return sortedPosts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, postsState) {
          return BlocBuilder<EventsBloc, EventsState>(
            builder: (context, eventsState) {
              // Wait for both posts and events to load
              if (postsState is PostsLoading || eventsState is EventsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                    strokeWidth: 3,
                  ),
                );
              }

              if (postsState is PostsError) {
                return _buildErrorState('Failed to load posts: ${postsState.message}');
              }

              if (eventsState is EventsError) {
                return _buildErrorState('Failed to load events: ${eventsState.message}');
              }

              if (postsState is PostsLoaded && eventsState is EventsLoaded) {
                // Trigger ranking when data is ready
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadRankedFeed(postsState.posts, eventsState.events);
                });

                // Build UI with ranking results
                return BlocBuilder<RankedFeedBloc, RankedFeedState>(
                  bloc: _rankedFeedBloc,
                  builder: (context, rankedState) {
                    List<Post> displayPosts = postsState.posts;

                    // If ranking succeeded, sort posts
                    if (rankedState is RankedFeedLoaded) {
                      displayPosts = _sortPostsByRanking(
                        postsState.posts,
                        rankedState.rankedFeed.forYouPosts,
                      );
                    }

                    // Get current user ID to filter out their posts
                    final userState = context.read<UserBloc>().state;
                    String? currentUserId;
                    if (userState is UserLoaded) {
                      currentUserId = userState.user.id;
                    }

                    // Filter out current user's posts
                    final feedPosts = currentUserId != null
                        ? displayPosts.where((post) => post.author.id != currentUserId).toList()
                        : displayPosts;

                    if (feedPosts.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<PostsBloc>().add(RefreshPosts());
                        context.read<EventsBloc>().add(LoadEvents());
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      color: const Color(0xFF8B5CF6),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: feedPosts.length,
                        itemBuilder: (context, index) {
                          return ModernPostCard(post: feedPosts[index]);
                        },
                      ),
                    );
                  },
                );
              }

              return _buildEmptyState();
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFFF6B6B),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3142),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<PostsBloc>().add(LoadPosts());
              context.read<EventsBloc>().add(LoadEvents());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF84994F).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.feed_outlined,
              size: 60,
              color: Color(0xFF84994F),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Halo! Selamat datang di Anigmaa 👋',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Yuk gas connect sama orang-orang keren\ndan ikutan event seru!',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF9E9E9E),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );

              if (result != null && result is Post) {
                context.read<PostsBloc>().add(CreatePostRequested(result));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: const Text(
              'Bikin Post',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
