import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    _scrollController.addListener(_onScroll);
    _rankedFeedBloc = sl<RankedFeedBloc>();

    // Load posts and events
    context.read<PostsBloc>().add(LoadPosts());
    context.read<EventsBloc>().add(LoadEvents());
  }

  // Instagram-style scroll listener for prefetching
  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;

      // Preload more images when 70% scrolled
      if (currentScroll > maxScroll * 0.7) {
        _precacheUpcomingImages();
      }
    }
  }

  // Precache first 15 visible post images on page load
  void _precacheVisibleImages(List<Post> posts) {
    if (!mounted) return;

    // Take first 15 posts
    final visiblePosts = posts.take(15).toList();

    for (final post in visiblePosts) {
      if (post.imageUrls.isNotEmpty) {
        for (final imageUrl in post.imageUrls) {
          precacheImage(
            CachedNetworkImageProvider(
              imageUrl,
              maxWidth: 800,
              maxHeight: 600,
            ),
            context,
          );
        }
      }
    }
  }

  // Precache next 10 upcoming post images when scrolling
  void _precacheUpcomingImages() {
    if (!mounted) return;

    // Get current posts from state
    final postsState = context.read<PostsBloc>().state;
    if (postsState is! PostsLoaded) return;

    final userState = context.read<UserBloc>().state;
    String? currentUserId;
    if (userState is UserLoaded) {
      currentUserId = userState.user.id;
    }

    // Filter out current user's posts
    final feedPosts = currentUserId != null
        ? postsState.posts.where((post) => post.author.id != currentUserId).toList()
        : postsState.posts;

    if (feedPosts.isEmpty) return;

    // Calculate current scroll position in terms of items
    final currentScroll = _scrollController.position.pixels;
    final itemHeight = 500.0; // Approximate height of a post card
    final currentIndex = (currentScroll / itemHeight).floor();

    // Precache next 10 posts
    final startIndex = currentIndex + 1;
    final endIndex = (startIndex + 10).clamp(0, feedPosts.length);

    for (int i = startIndex; i < endIndex; i++) {
      final post = feedPosts[i];
      if (post.imageUrls.isNotEmpty) {
        for (final imageUrl in post.imageUrls) {
          precacheImage(
            CachedNetworkImageProvider(
              imageUrl,
              maxWidth: 800,
              maxHeight: 600,
            ),
            context,
          );
        }
      }
    }
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

                    // Precache visible images when posts are loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _precacheVisibleImages(feedPosts);
                    });

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
