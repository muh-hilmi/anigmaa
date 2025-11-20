import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/event.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart' as posts_events;
import '../../bloc/posts/posts_state.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../bloc/ranked_feed/ranked_feed_bloc.dart';
import '../../bloc/ranked_feed/ranked_feed_event.dart';
import '../../bloc/ranked_feed/ranked_feed_state.dart';
import '../../widgets/modern_post_card.dart';
import '../../widgets/modern_event_mini_card.dart';
import '../create_post/create_post_screen.dart';
import '../../../injection_container.dart';

class RankedFeedScreen extends StatefulWidget {
  const RankedFeedScreen({super.key});

  @override
  State<RankedFeedScreen> createState() => _RankedFeedScreenState();
}

class _RankedFeedScreenState extends State<RankedFeedScreen> {
  late ScrollController _scrollController;
  late RankedFeedBloc _rankedFeedBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _rankedFeedBloc = sl<RankedFeedBloc>();

    // Load posts and events
    context.read<PostsBloc>().add(posts_events.LoadPosts());
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
                  if (_rankedFeedBloc.state is! RankedFeedLoaded) {
                    _loadRankedFeed(postsState.posts, eventsState.events);
                  }
                });

                return BlocProvider<RankedFeedBloc>.value(
                  value: _rankedFeedBloc,
                  child: BlocBuilder<RankedFeedBloc, RankedFeedState>(
                    builder: (context, rankedState) {
                      if (rankedState is RankedFeedLoading) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF8B5CF6),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Personalizing your feed...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (rankedState is RankedFeedError) {
                        // Fallback to unranked feed
                        return _buildUnrankedFeed(postsState.posts, eventsState.events);
                      }

                      if (rankedState is RankedFeedLoaded) {
                        return _buildRankedFeed(rankedState);
                      }

                      return _buildUnrankedFeed(postsState.posts, eventsState.events);
                    },
                  ),
                );
              }

              return _buildEmptyState();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );

          if (result != null && result is Post) {
            // Refresh posts after creating a new post
            context.read<PostsBloc>().add(posts_events.RefreshPosts());
          }
        },
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRankedFeed(RankedFeedLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PostsBloc>().add(posts_events.RefreshPosts());
        context.read<EventsBloc>().add(LoadEvents());
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFF8B5CF6),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 🔥 Trending Event Section (if available)
          if (state.trendingEvents.isNotEmpty) ...[
            _buildSectionHeader('🔥 Trending Now'),
            _buildTrendingEventCard(state.trendingEvents.first),
            const SizedBox(height: 16),
          ],

          // 📅 Hari Ini Events Section (if available)
          if (state.hariIniEvents.isNotEmpty) ...[
            _buildSectionHeader('📅 Happening Today'),
            _buildHorizontalEventList(state.hariIniEvents),
            const SizedBox(height: 16),
          ],

          // 📱 For You Feed Section
          _buildSectionHeader('For You'),
          const SizedBox(height: 8),

          // Interleave posts and events
          ..._buildInterleavedForYouFeed(state),
        ],
      ),
    );
  }

  Widget _buildUnrankedFeed(List<Post> posts, List<Event> events) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PostsBloc>().add(posts_events.RefreshPosts());
        context.read<EventsBloc>().add(LoadEvents());
        await Future.delayed(const Duration(seconds: 1));
      },
      color: const Color(0xFF8B5CF6),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return ModernPostCard(post: posts[index]);
        },
      ),
    );
  }

  List<Widget> _buildInterleavedForYouFeed(RankedFeedLoaded state) {
    final widgets = <Widget>[];
    final maxLength = state.forYouPosts.length > state.forYouEvents.length
        ? state.forYouPosts.length
        : state.forYouEvents.length;

    for (int i = 0; i < maxLength; i++) {
      // Add post if available
      if (i < state.forYouPosts.length) {
        widgets.add(ModernPostCard(post: state.forYouPosts[i]));
      }

      // Add event if available (interleave every 2 posts)
      if (i % 2 == 1 && i < state.forYouEvents.length) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ModernEventMiniCard(event: state.forYouEvents[i ~/ 2]),
        ));
      }
    }

    return widgets;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF000000),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTrendingEventCard(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8B5CF6),
              const Color(0xFF8B5CF6).withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // TODO: Navigate to event detail
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🔥 TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.location?.name ?? 'Online',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.startTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalEventList(List<Event> events) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO: Navigate to event detail
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(event.startTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
                              event.location?.name ?? 'Online',
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
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF84994F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.price == 0 ? 'FREE' : 'Rp ${event.price}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF84994F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<PostsBloc>().add(posts_events.LoadPosts());
                context.read<EventsBloc>().add(LoadEvents());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
