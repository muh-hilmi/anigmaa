import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/event_category_utils.dart';
import '../event_detail/event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Event> events;

  const MapScreen({super.key, required this.events});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Event? _selectedEvent;
  double _mapScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Events Map',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.black87),
            onPressed: () {
              setState(() {
                _mapScale = 1.0;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () => _showFilterSheet(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map mockup
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _mapScale = (_mapScale * details.scale).clamp(0.8, 2.0);
              });
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[50]!,
                    Colors.green[50]!,
                    Colors.blue[100]!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Grid lines for map feel
                  ...List.generate(10, (i) {
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: i * 80.0,
                      child: Container(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    );
                  }),
                  ...List.generate(10, (i) {
                    return Positioned(
                      top: 0,
                      bottom: 0,
                      left: i * 80.0,
                      child: Container(
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.1),
                      ),
                    );
                  }),
                  // Event pins
                  ...widget.events.asMap().entries.map((entry) {
                    final index = entry.key;
                    final event = entry.value;
                    return _buildEventPin(event, index);
                  }).toList(),
                  // Current location indicator
                  Positioned(
                    left: MediaQuery.of(context).size.width / 2 - 20,
                    top: MediaQuery.of(context).size.height / 2 - 100,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Selected event card
          if (_selectedEvent != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSelectedEventCard(_selectedEvent!),
            ),
          // Zoom controls
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  setState(() {
                    _mapScale = (_mapScale + 0.2).clamp(0.8, 2.0);
                  });
                }),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.remove, () {
                  setState(() {
                    _mapScale = (_mapScale - 0.2).clamp(0.8, 2.0);
                  });
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventPin(Event event, int index) {
    final positions = [
      {'left': 100.0, 'top': 150.0},
      {'left': 250.0, 'top': 200.0},
      {'left': 150.0, 'top': 350.0},
      {'left': 280.0, 'top': 400.0},
      {'left': 80.0, 'top': 450.0},
    ];

    final position = positions[index % positions.length];
    final isSelected = _selectedEvent?.id == event.id;

    return Positioned(
      left: position['left'],
      top: position['top'],
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEvent = event;
          });
        },
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 40,
            height: 50,
            child: Stack(
              children: [
                // Pin shadow
                Positioned(
                  bottom: 0,
                  left: 8,
                  child: Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Pin
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.getCategoryColor(event.category),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.getCategoryColor(event.category)
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${event.currentAttendees}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Pin pointer
                Positioned(
                  bottom: 0,
                  left: 16,
                  child: CustomPaint(
                    size: const Size(8, 10),
                    painter: _PinPointerPainter(
                      color: AppColors.getCategoryColor(event.category),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event image
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage(
                  event.imageUrls.isNotEmpty
                      ? event.imageUrls.first
                      : 'https://doodleipsum.com/600x200/abstract',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      padding: const EdgeInsets.all(4),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedEvent = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(event.location.latitude + event.location.longitude).abs().toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            _buildFilterOption('Show all categories', true),
            _buildFilterOption('Free events only', false),
            _buildFilterOption('Within 2km', false),
            _buildFilterOption('Starting today', false),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (value) {},
            activeColor: Colors.black,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PinPointerPainter extends CustomPainter {
  final Color color;

  _PinPointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
