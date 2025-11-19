import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/event.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_event.dart';
import '../../bloc/events/events_state.dart';
import '../event_detail/event_detail_screen.dart';

class SwipeableEventsScreen extends StatefulWidget {
  const SwipeableEventsScreen({super.key});

  @override
  State<SwipeableEventsScreen> createState() => _SwipeableEventsScreenState();
}

class _SwipeableEventsScreenState extends State<SwipeableEventsScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  String _currentEventTitle = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageChanged);

    final eventsBloc = context.read<EventsBloc>();
    if (eventsBloc.state is! EventsLoaded) {
      eventsBloc.add(LoadEvents());
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    if (!_pageController.hasClients) return;

    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<EventsBloc, EventsState>(
        builder: (context, state) {
          if (state is EventsLoaded) {
            final events = state.filteredEvents;

            if (events.isEmpty) {
              return _buildEmptyState();
            }

            // Update current event title
            if (_currentPage < events.length) {
              _currentEventTitle = events[_currentPage].title;
            }

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    key: ValueKey(events.length), // Force rebuild when list changes
                    controller: _pageController,
                    itemCount: events.length,
                    physics: const PageScrollPhysics(), // Enable page scroll for skip buttons
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _currentEventTitle = events[index].title;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildEventCard(events[index], index, events.length);
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF84994F),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Event event, int index, int totalEvents) {
    return _DraggableEventCard(
      event: event,
      onJoined: () {
        // Remove swiped event from the list
        context.read<EventsBloc>().add(RemoveEvent(event.id));
      },
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
              color: const Color(0xFF84994F).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Color(0xFF84994F),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No More Events',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve seen all available events',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableEventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onJoined;

  const _DraggableEventCard({
    required this.event,
    required this.onJoined,
  });

  @override
  State<_DraggableEventCard> createState() => _DraggableEventCardState();
}

class _DraggableEventCardState extends State<_DraggableEventCard>
    with TickerProviderStateMixin {
  double _dragOffset = 0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });

    // Setup icon animation
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dy;
      // No limit for smooth swipe experience
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Get both vertical and horizontal velocity
    final verticalVelocity = details.velocity.pixelsPerSecond.dy;
    final horizontalVelocity = details.velocity.pixelsPerSecond.dx.abs();

    // Swipe up (including diagonal northeast/northwest) - Join event
    // If moving upward (negative vertical velocity) and not too much horizontal movement
    if ((verticalVelocity < -500 && horizontalVelocity < 1000) || _dragOffset < -150) {
      // Animate card out of screen
      _animation = Tween<double>(
        begin: _dragOffset,
        end: -MediaQuery.of(context).size.height,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
      );
      _animationController.forward(from: 0).then((_) {
        if (mounted) {
          _showJoinSuccessModal();
        }
      });
    }
    // Swipe down - Mark as interested and go to next card
    else if (verticalVelocity > 300 || _dragOffset > 100) {
      // Animate card out downward with interest feedback
      _animation = Tween<double>(
        begin: _dragOffset,
        end: MediaQuery.of(context).size.height,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
      );
      _animationController.forward(from: 0).then((_) {
        if (mounted) {
          // Show brief interest snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Added to interested!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.grey[900],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1500),
              margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            ),
          );
          // Go to next card
          widget.onJoined();
        }
      });
    }
    // Return to original position
    else {
      _animation = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _isDragging
        ? (1.0 - (_dragOffset.abs() / 300)).clamp(0.3, 1.0)
        : 1.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: widget.event),
          ),
        );
      },
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      // Background image
                      if (widget.event.imageUrls.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            widget.event.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if image fails to load
                              return Container(
                                color: const Color(0xFFFAF8F5),
                                child: Center(
                                  child: Icon(
                                    Icons.event_rounded,
                                    size: 140,
                                    color: const Color(0xFF84994F).withValues(alpha: 0.08),
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFFFAF8F5),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: const Color(0xFF84994F),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        // Fallback background when no image
                        Container(
                          color: const Color(0xFFFAF8F5),
                          child: Center(
                            child: Icon(
                              Icons.event_rounded,
                              size: 140,
                              color: const Color(0xFF84994F).withValues(alpha: 0.08),
                            ),
                          ),
                        ),

                      // Top badges
                      Positioned(
                        top: 20,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            // Price badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.event.isFree
                                  ? const Color(0xFF84994F)
                                  : const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.event.isFree ? Icons.card_giftcard : Icons.paid,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.event.isFree
                                      ? 'GRATIS'
                                      : CurrencyFormatter.formatToCompact(widget.event.price ?? 0),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF84994F).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                widget.event.category.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF84994F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.0),
                                Colors.black.withValues(alpha: 0.6),
                                Colors.black.withValues(alpha: 0.9),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                widget.event.title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              if (widget.event.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.event.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Date & Time
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('EEEE, MMM d').format(widget.event.startTime),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('h:mm a').format(widget.event.startTime),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Location
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.event.location.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Participants & Max participants info
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Participants count
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.people,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${widget.event.currentAttendees} Peserta',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  'Maks: ${widget.event.maxAttendees}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Organizer
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withValues(alpha: 0.3),
                                            ),
                                            child: Center(
                                              child: Text(
                                                widget.event.host.name.substring(0, 1).toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Organizer',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                Text(
                                                  widget.event.host.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinSuccessModal() {
    // Trigger icon animation
    if (mounted) {
      _iconAnimationController.forward(from: 0.0);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (modalContext) => GestureDetector(
        onVerticalDragEnd: (details) {
          // If user swipes down on the modal, close it and go to next card
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.pop(context);
            widget.onJoined();
          }
        },
        child: Stack(
        children: [
          // Modal content at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Success Icon with animation (smaller)
                AnimatedBuilder(
                  animation: _iconScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _iconScaleAnimation.value,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF84994F),
                              Color(0xFF6B7D3F),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF84994F).withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Success Title (smaller)
                Text(
                  widget.event.isFree ? 'Kamu Terdaftar!' : 'Hampir Selesai!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.8,
                  ),
                ),

                const SizedBox(height: 6),

                // Event name (smaller)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF84994F),
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Price info if not free (compact)
                if (!widget.event.isFree && widget.event.price != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Biaya: ${CurrencyFormatter.formatToRupiah(widget.event.price!)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Event Info (compact inline)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF84994F)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('EEE, MMM d · h:mm a').format(widget.event.startTime),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF84994F)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.event.location.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

              // Action Buttons (compact)
              Column(
                children: [
                  // Payment Button (if not free)
                  if (!widget.event.isFree) ...[
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur pembayaran segera hadir!'),
                                backgroundColor: Color(0xFFF59E0B),
                              ),
                            );
                            widget.onJoined();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: Text(
                              'Bayar (${CurrencyFormatter.formatToCompact(widget.event.price!)})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // View Details
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF84994F), Color(0xFF6B7D3F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: widget.event),
                            ),
                          );
                          if (mounted) widget.onJoined();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Continue Button
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF84994F), width: 1.5),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          widget.onJoined();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            'Lanjut Cari Event',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF84994F),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Cancel Button (tiny)
                  TextButton(
                    onPressed: () => _showCancelConfirmation(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
                    child: Text(
                      'Batalkan pendaftaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        decoration: TextDecoration.underline,
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
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    int confirmationStep = 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Batalkan Pendaftaran?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (confirmationStep == 0) ...[
                  const Text(
                    'Apakah kamu yakin ingin membatalkan pendaftaran untuk event ini?',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kamu mungkin kehilangan kesempatan!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFF59E0B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (confirmationStep == 1) ...[
                  const Text(
                    'Kamu benar-benar yakin? Event ini mungkin tidak akan ada lagi.',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  const Text(
                    'Terakhir kali! Apa kamu 100% yakin ingin membatalkan?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Jangan Batalkan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF84994F),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (confirmationStep < 2) {
                    setState(() => confirmationStep++);
                  } else {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context); // Close success modal
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pendaftaran dibatalkan'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    widget.onJoined(); // Go to next card
                  }
                },
                child: Text(
                  confirmationStep < 2 ? 'Ya, Batalkan' : 'Ya, Saya Yakin',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF84994F).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF84994F),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
