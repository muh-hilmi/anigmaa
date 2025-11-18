import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
// import '../../../domain/entities/event_category.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../event_detail/event_detail_screen.dart';
import '../create_event/create_event_screen.dart';
// import '../calendar/calendar_screen.dart';
import '../map/map_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();

  // Events data from BLoC
  List<Event> _allEvents = [];
  List<Event> _trendingEvents = [];
  List<Event> _mostJoinedEvents = [];
  List<Event> _forYouEvents = [];
  List<Event> _chillEvents = [];

  @override
  void initState() {
    super.initState();
    context.read<EventsBloc>().add(LoadEvents());
  }

  void addNewEvent(Event event) {
    context.read<EventsBloc>().add(CreateEventRequested(event));
  }

  // Categorize events into 4 sections
  void _categorizeEvents(List<Event> events) {
    final now = DateTime.now();

    // Filter out past events
    final upcomingEvents = events.where((event) => event.startTime.isAfter(now)).toList();

    // 1. Trending: Events happening soon (within 48 hours) with some attendees
    _trendingEvents = upcomingEvents.where((event) {
      final hoursUntilStart = event.startTime.difference(now).inHours;
      return hoursUntilStart > 0 &&
             hoursUntilStart <= 48 &&
             event.currentAttendees >= 1; // Lowered from 10 to 1
    }).toList()
      ..sort((a, b) => b.currentAttendees.compareTo(a.currentAttendees));

    // 2. Most Joined: Events sorted by attendee count (take top 10)
    _mostJoinedEvents = (List<Event>.from(upcomingEvents)
      ..sort((a, b) => b.currentAttendees.compareTo(a.currentAttendees)))
      .take(10).toList();

    // 3. For You (FYP): Mix of different categories (personalized later)
    _forYouEvents = upcomingEvents;

    // 4. Chill: Small intimate events (<= 50 people, increased from 20)
    _chillEvents = upcomingEvents.where((event) {
      return event.maxAttendees <= 50;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventsError) {
            AppLogger().error('Discover screen error: ${state.message}');
          }

          // Log success/error messages from EventsLoaded state
          if (state is EventsLoaded) {
            if (state.successMessage != null) {
              AppLogger().info('Discover screen: ${state.successMessage}');
              // Clear the message after showing
              context.read<EventsBloc>().emit(state.clearMessages());
            }
            if (state.createErrorMessage != null) {
              AppLogger().error('Discover screen error: ${state.createErrorMessage}');
              // Clear the message after showing
              context.read<EventsBloc>().emit(state.clearMessages());
            }
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(child: CircularProgressIndicator(
              color: Color(0xFF84994F),
            ));
          }

          if (state is EventsLoaded) {
            _allEvents = state.events;
            _categorizeEvents(_allEvents);

            return _allEvents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: const Color(0xFF84994F),
                    onRefresh: () async {
                      context.read<EventsBloc>().add(LoadEvents());
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        _buildAppBar(),
                        SliverToBoxAdapter(child: _buildLiveEventsBar()),
                        SliverToBoxAdapter(child: _buildTrendingSection()),
                        SliverToBoxAdapter(child: _buildMostJoinedSection()),
                        SliverToBoxAdapter(child: _buildForYouSection()),
                        SliverToBoxAdapter(child: _buildChillSection()),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                    ),
                  );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEventScreen(),
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
      actions: [
        IconButton(
          onPressed: () => _showSearchDialog(),
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFAF8F5),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF1A1A1A),
              size: 20,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapScreen(events: _allEvents)),
            );
          },
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFAF8F5),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: Color(0xFF1A1A1A),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
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
                  child: Image.network(
                    event.imageUrls.isNotEmpty
                      ? event.imageUrls.first
                      : 'https://picsum.photos/100/100?random=${event.id}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
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

  // Section 1: Trending Events
  Widget _buildTrendingSection() {
    if (_trendingEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF3B30),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Trending',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to see all trending
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84994F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _trendingEvents.take(5).length,
              itemBuilder: (context, index) {
                return _buildTrendingCard(_trendingEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(Event event) {
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
        width: 200,
        margin: const EdgeInsets.only(right: 12),
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
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        event.imageUrls.isNotEmpty
                            ? event.imageUrls.first
                            : 'https://picsum.photos/400/300?random=${event.id}',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Trending badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_rounded,
                        size: 14,
                        color: Color(0xFF84994F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentAttendees} joined',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF84994F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 2: Most Joined Events
  Widget _buildMostJoinedSection() {
    if (_mostJoinedEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84994F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF84994F),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Paling Rame',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to see all
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84994F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _mostJoinedEvents.take(5).length,
              itemBuilder: (context, index) {
                return _buildMostJoinedCard(_mostJoinedEvents[index], index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostJoinedCard(Event event, int rank) {
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
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF84994F).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rank <= 3
                    ? const Color(0xFF84994F).withOpacity(0.1)
                    : const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: rank <= 3
                        ? const Color(0xFF84994F)
                        : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Event image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(
                      event.imageUrls.isNotEmpty
                          ? event.imageUrls.first
                          : 'https://picsum.photos/200/200?random=${event.id}',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Event info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_rounded,
                          size: 14,
                          color: Color(0xFF84994F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.currentAttendees} orang joined',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF84994F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatEventTime(event.startTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  // Section 3: For You (FYP)
  Widget _buildForYouSection() {
    if (_forYouEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.purple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'For You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to see all
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84994F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _forYouEvents.take(5).length,
              itemBuilder: (context, index) {
                return _buildForYouCard(_forYouEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouCard(Event event) {
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
        width: 220,
        margin: const EdgeInsets.only(right: 12),
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
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    event.imageUrls.isNotEmpty
                        ? event.imageUrls.first
                        : 'https://picsum.photos/440/320?random=${event.id}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getCategoryColor(event.category),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        EventCategoryUtils.getCategoryName(event.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Price
                  if (!event.isFree)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Rp ${event.price!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatEventTime(event.startTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 4: Chill Events
  Widget _buildChillSection() {
    if (_chillEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.nightlight_round,
                    color: Colors.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Chill Vibes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Intimate',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to see all
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84994F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _chillEvents.take(5).length,
              itemBuilder: (context, index) {
                return _buildChillCard(_chillEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChillCard(Event event) {
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
        width: 180,
        margin: const EdgeInsets.only(right: 12),
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
            // Image with overlay
            Stack(
              children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        event.imageUrls.isNotEmpty
                            ? event.imageUrls.first
                            : 'https://picsum.photos/360/260?random=${event.id}',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Max attendees badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Max ${event.maxAttendees}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentAttendees}/${event.maxAttendees}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Intimate',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                  builder: (context) => const CreateEventScreen(),
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

  // Helpers
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Search Events',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Cari event...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  String _formatEventTime(DateTime time) {
    final now = DateTime.now();
    final diff = time.difference(now);

    if (diff.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} hari lagi';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam lagi';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit lagi';
    } else {
      return 'Sekarang';
    }
  }
}
