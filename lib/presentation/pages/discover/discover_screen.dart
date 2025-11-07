import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../event_detail/event_detail_screen.dart';
import '../create_event/create_event_screen.dart';
import '../calendar/calendar_screen.dart';
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
  List<Event> _nearbyEvents = [];
  List<Event> _filteredEvents = [];
  EventCategory? _selectedCategory;
  String? _selectedTimeFilter; // '30m', '1h', '2h', 'all'

  @override
  void initState() {
    super.initState();
    // Load events using BLoC
    context.read<EventsBloc>().add(LoadEvents());
  }

  void addNewEvent(Event event) {
    context.read<EventsBloc>().add(CreateEventRequested(event));
  }

  void _filterByCategory(EventCategory? category) {
    context.read<EventsBloc>().add(FilterEventsByCategory(category));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe right to open calendar
          if (details.primaryVelocity! > 500) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalendarScreen(),
              ),
            );
          }
        },
        child: BlocConsumer<EventsBloc, EventsState>(
        listener: (context, state) {
          if (state is EventsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EventsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EventsLoaded) {
            _allEvents = state.events;
            _filteredEvents = state.filteredEvents;
            _nearbyEvents = state.nearbyEvents;
            _selectedCategory = state.selectedCategory;

            return _filteredEvents.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      context.read<EventsBloc>().add(LoadEvents());
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        _buildAppBar(),
                        SliverToBoxAdapter(child: _buildStoryBar()),
                        SliverToBoxAdapter(child: _buildTimeFilters()),
                        _buildEventsList(),
                      ],
                    ),
                  );
          }

          return _buildEmptyState();
        },
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Jakarta, Indonesia',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.explore_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
                const Text(
                  'Belum ada acara di sekitar sini… 🫠',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gas bikin acara pertama biar rame!\nAjak temen-temen nongkrong yuk 🔥',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Refresh/reload events
                        setState(() {
                          // This would typically reload data from API
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                    const SizedBox(width: 12),
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
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Bikin Acara Yuk ✨'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF84994F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Jaksel Area',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showSearchDialog(),
                icon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[700],
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryBar() {
    // Filter live events (happening now or starting within 30 min)
    final now = DateTime.now();
    final liveEvents = _allEvents.where((event) {
      final minutesUntilStart = event.startTime.difference(now).inMinutes;
      return minutesUntilStart <= 30 && minutesUntilStart >= -60;
    }).take(10).toList();

    if (liveEvents.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B30),
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  '${liveEvents.length} events',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
                return _buildStoryCard(liveEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Event event) {
    return GestureDetector(
      onTap: () {
        _showQuickJoinModal(event);
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
                    event.host.avatar,
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
              event.host.name.split(' ')[0],
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
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

  void _showQuickJoinModal(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 8),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${event.currentAttendees} online',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF84994F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(event.host.avatar),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.host.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Host',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _quickJoinEvent(event);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84994F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Join Sekarang! 🔥',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

  Widget _buildGabutButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show modal to find quick hangout
            _showQuickHangoutModal();
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '😴',
                        style: TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gabut Nih... 🫠',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Cari Hangout Sekarang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF84994F),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CEPAT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF000000),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickHangoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mau Ngapain Nih? 🤔',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih vibes yang kamu mau, kita cariin temen!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [
                          _buildVibeCard('☕', 'Ngopi', 'Coffee & chill'),
                          _buildVibeCard('🍜', 'Makan', 'Ngegas makan'),
                          _buildVibeCard('🎮', 'Main', 'Gaming bareng'),
                          _buildVibeCard('🎨', 'Seni', 'Art & craft'),
                          _buildVibeCard('⚽', 'Olahraga', 'Main bola/basket'),
                          _buildVibeCard('🎵', 'Music', 'Dengerin musik'),
                        ],
                      ),
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

  Widget _buildVibeCard(String emoji, String title, String subtitle) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lagi nyari temen buat $title... 🔍'),
              backgroundColor: const Color(0xFF000000),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTimeFilterChip('Sekarang', 'now', isHighlight: true),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('30 Menit', '30m'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('1 Jam', '1h'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('2 Jam', '2h'),
                      const SizedBox(width: 8),
                      _buildTimeFilterChip('Semua', null),
                    ],
                  ),
          ),
          if (_selectedTimeFilter != null || _selectedCategory != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_alt,
                        size: 12,
                        color: Color(0xFF000000),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filter: ${_getFilterLabel()}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTimeFilter = null;
                      _selectedCategory = null;
                    });
                    _filterByCategory(null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, String? value, {bool isHighlight = false}) {
    final isSelected = _selectedTimeFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFF84994F)
            : const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF000000),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMapHero() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Mock map background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[50]!,
                  Colors.green[50]!,
                ],
              ),
            ),
          ),
          // Map content overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_allEvents.length} events nearby',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Within 5km radius',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 14,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Mock map pins
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) => _buildMapPin(index)),
                  ),
                  const SizedBox(height: 4),
                  // Pin legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPinLegend(const Color(0xFFFF3B30), 'Live'),
                      const SizedBox(width: 10),
                      _buildPinLegend(const Color(0xFF84994F), '<1h'),
                      const SizedBox(width: 10),
                      _buildPinLegend(const Color(0xFF84994F), 'Nanti'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(events: _allEvents),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Peta 📍',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPin(int index) {
    // Red = live/now, Blue = upcoming, Green = later
    final colors = [
      const Color(0xFFFF3B30), // Live
      const Color(0xFF84994F), // Upcoming
      const Color(0xFF84994F), // Later
    ];
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: colors[index],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: colors[index].withValues(alpha: 0.4),
            blurRadius: index == 0 ? 8 : 4,
            spreadRadius: index == 0 ? 1 : 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _buildPinLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyNowSection() {
    if (_nearbyEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mau Mulai Sebentar Lagi! ⚡',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _nearbyEvents.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _navigateToEventDetail(_nearbyEvents[index]),
                child: _buildNearbyEventCard(_nearbyEvents[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNearbyEventCard(Event event) {
    final now = DateTime.now();
    final minutesUntilStart = event.startTime.difference(now).inMinutes;
    final isLive = minutesUntilStart <= 30 && minutesUntilStart >= -60;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Event image
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: NetworkImage(
                  event.imageUrls.isNotEmpty
                    ? event.imageUrls.first
                    : 'https://doodleipsum.com/600x400/abstract'
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                if (event.isPrivate)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (isLive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${event.startTime.difference(DateTime.now()).inHours}h',
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
          // Event details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (event.currentAttendees > 0)
                          SizedBox(
                            width: event.currentAttendees >= 3 ? 48 : (event.currentAttendees * 16.0),
                            height: 18,
                            child: Stack(
                              children: List.generate(
                                event.currentAttendees.clamp(0, 3),
                                (index) => Positioned(
                                  left: index * 12.0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=user${event.attendeeIds.isNotEmpty ? event.attendeeIds[index] : index}&size=36',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: event.currentAttendees > 0 ? 6 : 0),
                        Row(
                          children: [
                            if (isLive) ...[
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF84994F),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                '${event.currentAttendees} online',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF84994F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else
                              Text(
                                '${event.currentAttendees} join',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _quickJoinEvent(event),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: event.isFull ? Colors.grey[300] : Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.isFull ? 'Penuh' : 'Join',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: event.isFull ? Colors.grey[600] : Colors.white,
                          ),
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

  // Widget _buildCategoriesSection() {
  //   final categories = EventCategory.values.take(6).toList();

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text(
  //               'Cari berdasarkan vibe 🏷️',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w700,
  //                 color: Colors.black87,
  //               ),
  //             ),
  //             if (_selectedCategory != null)
  //               GestureDetector(
  //                 onTap: () => _filterByCategory(null),
  //                 child: Text(
  //                   'Clear',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.blue[600],
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ),
  //           ],
  //         ),
  //       ),
  //       SizedBox(
  //         height: 100,
  //         child: ListView.builder(
  //           scrollDirection: Axis.horizontal,
  //           padding: const EdgeInsets.symmetric(horizontal: 16),
  //           itemCount: categories.length,
  //           itemBuilder: (context, index) {
  //             return _buildCategoryCard(categories[index]);
  //           },
  //         ),
  //       ),
  //       const SizedBox(height: 24),
  //     ],
  //   );
  // }

  Widget _buildCategoryCard(EventCategory category) {
    final isSelected = _selectedCategory == category;
    final categoryName = EventCategoryUtils.getCategoryName(category);

    return GestureDetector(
      onTap: () => _filterByCategory(isSelected ? null : category),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.getCategoryColor(category) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.getCategoryColor(category) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$categoryName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.getCategoryColor(category),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return const SizedBox.shrink();
            }
            return _buildVerticalFeedCard(_filteredEvents[index - 1]);
          },
          childCount: _filteredEvents.length + 1,
        ),
      ),
    );
  }

  Widget _buildVerticalFeedCard(Event event) {
    final now = DateTime.now();
    final minutesUntilStart = event.startTime.difference(now).inMinutes;
    final isLive = minutesUntilStart <= 30 && minutesUntilStart >= -60;

    return GestureDetector(
      onTap: () => _showEventDetailModal(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  event.imageUrls.isNotEmpty
                      ? event.imageUrls.first
                      : 'https://api.dicebear.com/7.x/shapes/png?seed=${event.id}&size=400',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: double.infinity,
                    height: 180,
                    color: Colors.grey[200],
                    child: Icon(Icons.image, color: Colors.grey[400], size: 48),
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              // Top badges
              Positioned(
                top: 12,
                left: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.getCategoryColor(event.category).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        EventCategoryUtils.getCategoryName(event.category),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Price badge
              if (!event.isFree)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rp ${event.price!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              // Distance & Time badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _getDistanceText() + ' • ' + _getTimeText(event.startTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Host
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(event.host.avatar),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'by ${event.host.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                // Attendees & Join button
                Row(
                  children: [
                    // Attendees
                    Expanded(
                      child: Row(
                        children: [
                          if (event.currentAttendees > 0)
                            SizedBox(
                              width: event.currentAttendees >= 3 ? 65 : (event.currentAttendees * 22.0),
                              height: 28,
                              child: Stack(
                                children: List.generate(
                                  event.currentAttendees.clamp(0, 3),
                                  (index) => Positioned(
                                    left: index * 18.0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://api.dicebear.com/7.x/avataaars/png?seed=user${event.attendeeIds.isNotEmpty ? event.attendeeIds[index] : index}&size=56',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(width: event.currentAttendees > 0 ? 8 : 0),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isLive && event.currentAttendees > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(right: 5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF84994F),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          '${event.currentAttendees} online',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF84994F),
                                            fontWeight: FontWeight.w800,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    event.currentAttendees > 0
                                        ? '${event.currentAttendees} join'
                                        : 'Pertama!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (event.currentAttendees > 0)
                                  Text(
                                    '${event.spotsLeft} slot',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Join Button
                    ElevatedButton(
                      onPressed: event.isFull ? null : () => _quickJoinEvent(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isFull
                            ? Colors.grey[300]
                            : (isLive ? const Color(0xFF84994F) : Colors.black),
                        foregroundColor: event.isFull ? Colors.grey[600] : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.isFull
                                ? 'Penuh'
                                : (isLive ? 'Join!' : 'Join'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!event.isFull) ...[
                            const SizedBox(width: 4),
                            Text(
                              isLive ? '🔥' : '✨',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ],
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

  void _showEventDetailModal(Event event) {
    final now = DateTime.now();
    final minutesUntilStart = event.startTime.difference(now).inMinutes;
    final isLive = minutesUntilStart <= 30 && minutesUntilStart >= -60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          event.imageUrls.isNotEmpty
                              ? event.imageUrls.first
                              : 'https://api.dicebear.com/7.x/shapes/png?seed=${event.id}&size=400',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.getCategoryColor(event.category),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              EventCategoryUtils.getCategoryName(event.category),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (isLive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Colors.white, size: 8),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Host
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(event.host.avatar),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.host.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Host',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Details
                      _buildDetailRow(Icons.access_time, _formatEventTime(event.startTime)),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.location_on_outlined, event.location.name),
                      if (!event.isFree) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.payment, 'Rp ${event.price!.toStringAsFixed(0)}'),
                      ],
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.people_outline, '${event.currentAttendees}/${event.maxAttendees} peserta'),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              // Bottom Join Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: event.isFull ? null : () {
                        Navigator.pop(context);
                        _quickJoinEvent(event);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isFull
                            ? Colors.grey[300]
                            : (isLive ? const Color(0xFF84994F) : Colors.black),
                        foregroundColor: event.isFull ? Colors.grey[600] : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        event.isFull
                            ? 'Event Penuh 😔'
                            : (isLive ? 'Join Sekarang! 🔥' : 'Join Event Yuk! ✨'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getDistanceText() {
    // Mock distance - nanti bisa pake real geolocation
    final distances = ['100m', '300m', '500m', '1km', '2km'];
    return distances[DateTime.now().second % distances.length];
  }

  String _getTimeText(DateTime startTime) {
    final now = DateTime.now();
    final difference = startTime.difference(now);

    if (difference.inMinutes < 5) {
      return 'NOW';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildEventCard(Event event) {
    final now = DateTime.now();
    final minutesUntilStart = event.startTime.difference(now).inMinutes;
    final isLive = minutesUntilStart <= 30 && minutesUntilStart >= -60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: NetworkImage(
                  event.imageUrls.isNotEmpty
                    ? event.imageUrls.first
                    : 'https://doodleipsum.com/600x400/abstract'
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                if (event.isPrivate)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
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
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!event.isFree)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Rp ${event.price!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Event content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and host
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${event.host.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(event.host.avatar),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Event details
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatEventTime(event.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Attendees and RSVP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Attendee avatars
                        if (event.currentAttendees > 0)
                          SizedBox(
                            width: event.currentAttendees >= 3 ? 60 : (event.currentAttendees * 20.0),
                            height: 24,
                            child: Stack(
                              children: List.generate(
                                event.currentAttendees.clamp(0, 3),
                                (index) => Positioned(
                                  left: index * 15.0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=user${event.attendeeIds.isNotEmpty ? event.attendeeIds[index] : index}&size=48',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: event.currentAttendees > 0 ? 8 : 0),
                        Row(
                          children: [
                            if (isLive && event.currentAttendees > 0) ...[
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF84994F),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                '${event.currentAttendees} online',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF84994F),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ] else
                              Text(
                                event.currentAttendees > 0
                                  ? '${event.currentAttendees} lagi join 👥'
                                  : 'Jadi yang pertama! 🌟',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: event.isFull ? null : () => _quickJoinEvent(event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isFull ? Colors.grey[300] : Colors.black,
                        foregroundColor: event.isFull ? Colors.grey[600] : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.isFull ? 'Penuh 😔' : 'Join Yuk! ✨',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Tomorrow ${_formatTime(dateTime)}';
      }
      return '${_getWeekday(dateTime)}, ${_formatTime(dateTime)}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${_formatTime(dateTime)}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ${_formatTime(dateTime)}';
    } else {
      return 'Starting now';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${hour}:${minute}';
  }

  String _getWeekday(DateTime dateTime) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[dateTime.weekday - 1];
  }

  void _quickJoinEvent(Event event) {
    // Quick join with 1-tap - show immediate confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sukses Join! 🎉',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sampai ketemu di ${event.title}!',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF84994F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.white,
          onPressed: () {
            _navigateToEventDetail(event);
          },
        ),
      ),
    );
  }

  void _showRSVPModal(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RSVPModal(event: event),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Pagi! Mau Ngapain Nih? ☀️';
    } else if (hour < 15) {
      return 'Siang! Udah Makan Belum? 🍜';
    } else if (hour < 18) {
      return 'Sore! Mau Ngapain Nih? 🌤️';
    } else {
      return 'Malem! Mau Nongki? 🌙';
    }
  }

  String _getFilterLabel() {
    final filters = <String>[];

    if (_selectedTimeFilter != null) {
      switch (_selectedTimeFilter) {
        case 'now':
          filters.add('Sekarang');
          break;
        case '30m':
          filters.add('30m');
          break;
        case '1h':
          filters.add('1 jam');
          break;
        case '2h':
          filters.add('2 jam');
          break;
      }
    }

    if (_selectedCategory != null) {
      filters.add('#${EventCategoryUtils.getCategoryName(_selectedCategory!).toLowerCase()}');
    }

    return filters.join(' • ');
  }

  void _navigateToEventDetail(Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: EventSearchDelegate(_allEvents),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class EventSearchDelegate extends SearchDelegate<Event?> {
  final List<Event> events;

  EventSearchDelegate(this.events);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = events.where((event) {
      return event.title.toLowerCase().contains(query.toLowerCase()) ||
          event.description.toLowerCase().contains(query.toLowerCase()) ||
          event.location.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return _buildResultsList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = events.where((event) {
      return event.title.toLowerCase().contains(query.toLowerCase()) ||
          event.location.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return _buildResultsList(suggestions);
  }

  Widget _buildResultsList(List<Event> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final event = results[index];
        return GestureDetector(
          onTap: () {
            close(context, event);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(
                        event.imageUrls.isNotEmpty
                            ? event.imageUrls.first
                            : 'https://doodleipsum.com/100x100/abstract',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.location.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RSVPModal extends StatelessWidget {
  final Event event;

  const _RSVPModal({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RSVP to Event',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Event summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              _formatEventDateTime(event.startTime),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.location.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Spots available: ${event.spotsLeft}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmRSVP(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm RSVP',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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
    );
  }

  String _formatEventDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month $day, $hour:$minute';
  }

  void _confirmRSVP(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('RSVP confirmed! Check your calendar.'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}