import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../../bloc/posts/posts_bloc.dart';
import '../../bloc/posts/posts_event.dart';
import '../../bloc/posts/posts_state.dart';
import '../../bloc/ranked_feed/ranked_feed_bloc.dart';
import '../../bloc/ranked_feed/ranked_feed_event.dart';
import '../../bloc/ranked_feed/ranked_feed_state.dart';
import '../event_detail/event_detail_screen.dart';
import '../create_event/create_event_conversation.dart';
import '../../../injection_container.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late RankedFeedBloc _rankedFeedBloc;

  // Events data from BLoC
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];

  // Ranked IDs from API
  Map<String, List<String>> _rankedEventIds = {};

  // Current selected mode
  String _selectedMode = 'for_you'; // 'trending', 'for_you', 'chill'

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rankedFeedBloc = sl<RankedFeedBloc>();
    _searchController.addListener(_filterEvents);
    _scrollController.addListener(_onScroll);
    context.read<EventsBloc>().add(const LoadEventsByMode(mode: 'for_you'));
    context.read<PostsBloc>().add(LoadPosts());
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

  void _filterEvents() {
    // When search changes, reapply mode filter (which includes search)
    _applyModeFilter();
    // Precache images after filtering
    _precacheVisibleImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _rankedFeedBloc.close();
    super.dispose();
  }

  void addNewEvent(Event event) {
    context.read<EventsBloc>().add(CreateEventRequested(event));
  }

  void _changeMode(String mode) {
    setState(() {
      _selectedMode = mode;
    });
    // API consumption nanti - untuk sekarang semua client-side filtering
    _applyModeFilter();
  }

  void _applyModeFilter() {
    setState(() {
      List<Event> baseEvents = _allEvents;

      // Apply search filter first if exists
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        baseEvents = baseEvents.where((event) {
          return event.title.toLowerCase().contains(query) ||
                 event.description.toLowerCase().contains(query) ||
                 event.location.name.toLowerCase().contains(query);
        }).toList();
      }

      // Apply mode-specific filter using ranked IDs if available
      switch (_selectedMode) {
        case 'trending':
          _filteredEvents = _sortEventsByRanking(baseEvents, _rankedEventIds['trending'] ?? []);
          break;

        case 'for_you':
          _filteredEvents = _sortEventsByRanking(baseEvents, _rankedEventIds['for_you'] ?? []);
          break;

        case 'chill':
          _filteredEvents = _sortEventsByRanking(baseEvents, _rankedEventIds['chill'] ?? []);
          break;

        case 'today':
          _filteredEvents = _sortEventsByRanking(baseEvents, _rankedEventIds['today'] ?? []);
          break;

        case 'free':
          _filteredEvents = _sortEventsByRanking(baseEvents, _rankedEventIds['free'] ?? []);
          break;

        case 'paid':
          _filteredEvents = _sortEventsByRanking(baseEvents, _rankedEventIds['paid'] ?? []);
          break;

        case 'nearby':
          // Nearby: fallback to all events (TODO: implement distance calculation)
          _filteredEvents = baseEvents.toList();
          break;

        default:
          _filteredEvents = baseEvents;
      }
    });
  }

  List<Event> _sortEventsByRanking(List<Event> events, List<String> rankedIds) {
    if (rankedIds.isEmpty) return events;

    // Create map for O(1) lookup
    final eventMap = {for (var event in events) event.id: event};

    // Sort events according to ranked IDs
    final sortedEvents = <Event>[];
    for (final id in rankedIds) {
      if (eventMap.containsKey(id)) {
        sortedEvents.add(eventMap[id]!);
      }
    }

    // Add remaining events that weren't in ranking
    for (final event in events) {
      if (!rankedIds.contains(event.id)) {
        sortedEvents.add(event);
      }
    }

    return sortedEvents;
  }

  // Instagram-style image precaching for smooth scrolling
  void _precacheVisibleImages() {
    if (!mounted) return;

    // Precache first 15 visible + upcoming images
    final displayEvents = _filteredEvents.where((event) {
      return event.status == EventStatus.upcoming ||
             event.status == EventStatus.live;
    }).take(15).toList();

    for (final event in displayEvents) {
      if (event.imageUrls.isNotEmpty) {
        try {
          precacheImage(
            CachedNetworkImageProvider(
              event.imageUrls.first,
              maxWidth: 400,
              maxHeight: 300,
            ),
            context,
          );
        } catch (e) {
          // Silently fail - image will load on demand
        }
      }
    }
  }

  // Precache upcoming images when scrolling
  void _precacheUpcomingImages() {
    if (!mounted) return;

    final displayEvents = _filteredEvents.where((event) {
      return event.status == EventStatus.upcoming ||
             event.status == EventStatus.live;
    }).toList();

    // Precache next 10 images
    final startIndex = 15; // After initial precache
    final endIndex = (startIndex + 10).clamp(0, displayEvents.length);

    for (var i = startIndex; i < endIndex; i++) {
      final event = displayEvents[i];
      if (event.imageUrls.isNotEmpty) {
        try {
          precacheImage(
            CachedNetworkImageProvider(
              event.imageUrls.first,
              maxWidth: 400,
              maxHeight: 300,
            ),
            context,
          );
        } catch (e) {
          // Silently fail
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PostsBloc, PostsState>(
        builder: (context, postsState) {
          return BlocConsumer<EventsBloc, EventsState>(
            listener: (context, state) {
              if (state is EventsError) {
                AppLogger().error('Discover screen error: ${state.message}');
              }

              // Log success/error messages from EventsLoaded state
              if (state is EventsLoaded) {
                if (state.successMessage != null) {
                  AppLogger().info('Discover screen: ${state.successMessage}');
                }
                if (state.createErrorMessage != null) {
                  AppLogger().error('Discover screen error: ${state.createErrorMessage}');
                }
              }
            },
            builder: (context, eventsState) {
              // Handle error state first
              if (eventsState is EventsError) {
                return _buildErrorState(eventsState.message);
              }

              // Show loading for initial, loading states, or when posts are loading
              if (eventsState is EventsLoading ||
                  postsState is PostsLoading ||
                  eventsState is! EventsLoaded ||
                  postsState is! PostsLoaded) {
                return const Center(child: CircularProgressIndicator(
                  color: Color(0xFF84994F),
                ));
              }

              if (eventsState is EventsLoaded && postsState is PostsLoaded) {
                _allEvents = eventsState.events;

                // Trigger ranking when data is ready
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _rankedFeedBloc.add(LoadRankedFeed(
                    posts: postsState.posts,
                    events: eventsState.events,
                  ));
                });

                // Listen to ranking results
                return BlocBuilder<RankedFeedBloc, RankedFeedState>(
                  bloc: _rankedFeedBloc,
                  builder: (context, rankedState) {
                    // Update ranked IDs when ranking succeeds
                    if (rankedState is RankedFeedLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _rankedEventIds = {
                            'trending': rankedState.rankedFeed.trendingEvent,
                            'for_you': rankedState.rankedFeed.forYouEvents,
                            'chill': rankedState.rankedFeed.chillEvents,
                            'today': rankedState.rankedFeed.hariIniEvents,
                            'free': rankedState.rankedFeed.gratisEvents,
                            'paid': rankedState.rankedFeed.bayarEvents,
                          };
                        });
                        _applyModeFilter();
                        // Precache images after ranking
                        _precacheVisibleImages();
                      });
                    }

                    if (_filteredEvents.isEmpty && _searchController.text.isEmpty && _rankedEventIds.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _applyModeFilter();
                        _precacheVisibleImages();
                      });
                    }

                    return _allEvents.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: const Color(0xFF84994F),
                            onRefresh: () async {
                              context.read<EventsBloc>().add(LoadEventsByMode(mode: _selectedMode));
                              context.read<PostsBloc>().add(LoadPosts());
                              await Future.delayed(const Duration(seconds: 1));
                            },
                            child: CustomScrollView(
                              controller: _scrollController,
                              slivers: [
                                _buildAppBar(),
                                SliverToBoxAdapter(child: _buildSearchBar()),
                                SliverToBoxAdapter(child: _buildModeSwitcher()),
                                SliverToBoxAdapter(child: _buildLiveEventsBar()),
                                _buildEventsList(),
                                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                              ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventConversation(),
            ),
          );
          if (result != null && result is Event) {
            addNewEvent(result);
          }
        },
        backgroundColor: const Color(0xFF84994F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // App Bar
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Color(0xFF84994F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Jaksel Area',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: const [
        SizedBox(width: 8),
      ],
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari event, lokasi...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF84994F),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFFAF8F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // Mode Switcher
  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildModeChip(
            mode: 'trending',
            label: 'Trending',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF3B30),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'for_you',
            label: 'For You',
            icon: Icons.auto_awesome_rounded,
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'chill',
            label: 'Chill',
            icon: Icons.nightlight_round,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'nearby',
            label: 'Terdekat',
            icon: Icons.near_me_rounded,
            color: const Color(0xFF84994F),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'today',
            label: 'Hari Ini',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFFFF9500),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'free',
            label: 'Gratis',
            icon: Icons.money_off_rounded,
            color: const Color(0xFF34C759),
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            mode: 'paid',
            label: 'Berbayar',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String mode,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => _changeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Events List
  Widget _buildEventsList() {
    // Filter to only show upcoming and live events (hide completed/cancelled events)
    final displayEvents = _filteredEvents.where((event) {
      return event.status == EventStatus.upcoming ||
             event.status == EventStatus.live;
    }).toList();

    if (displayEvents.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Ga nemu event nih 😅',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coba kata kunci lain',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildEventCard(displayEvents[index]);
          },
          childCount: displayEvents.length,
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final daysUntil = event.startTime.difference(DateTime.now()).inDays;
    final hoursUntil = event.startTime.difference(DateTime.now()).inHours;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF84994F).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: const Color(0xFFFAF8F5),
                    image: event.imageUrls.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              event.imageUrls.first,
                              maxWidth: 400,
                              maxHeight: 300,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: event.imageUrls.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.event_rounded,
                            color: Color(0xFF84994F),
                            size: 32,
                          ),
                        )
                      : null,
                ),
                // Category badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getCategoryColor(event.category),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      EventCategoryUtils.getCategoryName(event.category),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Price badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: event.isFree
                          ? const Color(0xFF84994F)
                          : const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.isFree ? 'GRATIS' : 'Rp${event.price!.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Countdown
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            daysUntil > 0
                                ? '$daysUntil hari lagi'
                                : hoursUntil > 0
                                    ? '$hoursUntil jam lagi'
                                    : 'Sekarang!',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Attendees
                    Row(
                      children: [
                        const Icon(
                          Icons.people_rounded,
                          size: 12,
                          color: Color(0xFF84994F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.currentAttendees}/${event.maxAttendees}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF84994F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live Events Bar (Story style)
  Widget _buildLiveEventsBar() {
    final now = DateTime.now();
    final liveEvents = _allEvents.where((event) {
      final minutesUntilStart = event.startTime.difference(now).inMinutes;
      return minutesUntilStart <= 30 && minutesUntilStart >= -60;
    }).take(10).toList();

    if (liveEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LIVE NOW',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF3B30),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${liveEvents.length} events',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: liveEvents.length,
              itemBuilder: (context, index) {
                return _buildLiveEventCard(liveEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 65,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF3B30), Color(0xFFFF6B58)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: event.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: event.imageUrls.first,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          memCacheWidth: 100,
                          memCacheHeight: 100,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFFAF8F5),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFFAF8F5),
                            child: const Icon(
                              Icons.event_rounded,
                              color: Color(0xFF84994F),
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFFAF8F5),
                          child: const Icon(
                            Icons.event_rounded,
                            color: Color(0xFF84994F),
                            size: 24,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              event.title.split(' ')[0],
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.explore_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada event nih...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yuk bikin event pertama!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEventConversation(),
                ),
              );
              if (result != null && result is Event) {
                addNewEvent(result);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Bikin Event',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Error State
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Ada Masalah',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba cek koneksi internet atau backend API',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<EventsBloc>().add(LoadEvents());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84994F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
