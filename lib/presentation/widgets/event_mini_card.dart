import 'package:flutter/material.dart';
import '../../domain/entities/event.dart';
import '../pages/event_detail/event_detail_screen.dart';

class EventMiniCard extends StatefulWidget {
  final Event event;
  final VoidCallback? onJoin;
  final VoidCallback? onFindMatches;
  final bool isJoined;

  const EventMiniCard({
    super.key,
    required this.event,
    this.onJoin,
    this.onFindMatches,
    this.isJoined = false,
  });

  @override
  State<EventMiniCard> createState() => _EventMiniCardState();
}

class _EventMiniCardState extends State<EventMiniCard> with SingleTickerProviderStateMixin {
  late AnimationController _joinAnimController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _joinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _joinAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _joinAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: widget.event),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.purple.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image preview (optional)
            if (widget.event.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  widget.event.imageUrls.first,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 140,
                      color: Colors.purple.shade100,
                      child: const Icon(Icons.event, size: 48),
                    );
                  },
                ),
              ),

            // Event info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Event metadata row
                  _buildMetadataRow(),

                  const SizedBox(height: 12),

                  // Joined avatars preview
                  _buildJoinedPreview(),

                  const SizedBox(height: 16),

                  // Action buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Column(
      children: [
        // Date & Time
        Row(
          children: [
            Icon(Icons.calendar_today, size: 15, color: Colors.purple.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _formatEventDate(widget.event.startTime),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Location
        Row(
          children: [
            Icon(Icons.location_on, size: 15, color: Colors.purple.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.event.location.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Distance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation, size: 11, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '1.2 km',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Attendees & Price
        Row(
          children: [
            Icon(Icons.people, size: 15, color: Colors.purple.shade700),
            const SizedBox(width: 6),
            Text(
              '${widget.event.currentAttendees} Joined',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              widget.event.isFree ? Icons.money_off : Icons.payments,
              size: 15,
              color: widget.event.isFree ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              widget.event.isFree ? 'Free' : 'Rp ${widget.event.price!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: widget.event.isFree ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJoinedPreview() {
    // Mock joined users avatars
    return Row(
      children: [
        // Stacked avatars
        SizedBox(
          width: 64, // 3 avatars * 18px overlap + 28px for last avatar = 64px
          height: 28,
          child: Stack(
            children: List.generate(
              3,
              (index) => Positioned(
                left: index * 18.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.primaries[index % Colors.primaries.length].shade300,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 60),
        Text(
          '+${widget.event.currentAttendees - 3}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canJoin = widget.event.canJoin;
    final hasEnded = widget.event.hasEnded;

    return Row(
      children: [
        // Join/RSVP button
        Expanded(
          flex: 2,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ElevatedButton(
              onPressed: (!canJoin || hasEnded) ? null : () {
                _joinAnimController.forward().then((_) {
                  _joinAnimController.reverse();
                });
                widget.onJoin?.call();

                // Show snackbar with undo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Joined — Tap to undo'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // TODO: Undo join
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: hasEnded
                    ? Colors.grey.shade300
                    : (widget.isJoined ? Colors.grey.shade300 : Colors.purple.shade600),
                foregroundColor: hasEnded
                    ? Colors.grey.shade600
                    : (widget.isJoined ? Colors.black87 : Colors.white),
                elevation: (widget.isJoined || hasEnded) ? 0 : 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasEnded
                        ? Icons.event_busy
                        : (widget.isJoined ? Icons.check_circle : Icons.add_circle_outline),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasEnded
                        ? 'Event Ended'
                        : (widget.isJoined ? 'Joined' : (widget.event.isFree ? 'Join · Free' : 'Get Ticket')),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Find Matches button
        Expanded(
          child: OutlinedButton(
            onPressed: hasEnded ? null : widget.onFindMatches,
            style: OutlinedButton.styleFrom(
              foregroundColor: hasEnded ? Colors.grey.shade400 : Colors.purple.shade700,
              side: BorderSide(
                color: hasEnded ? Colors.grey.shade300 : Colors.purple.shade300,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_alt_outlined, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Matches',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Bookmark button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              // TODO: Bookmark event
            },
            icon: const Icon(Icons.bookmark_border),
            iconSize: 20,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    const daysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Check if event has ended
    if (widget.event.hasEnded) {
      return 'Ended · ${daysShort[date.weekday - 1]}, ${date.day} ${monthsShort[date.month - 1]}';
    }

    if (diff.inDays == 0) {
      return 'Today · ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow · ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${daysShort[date.weekday - 1]}, ${date.day} ${monthsShort[date.month - 1]} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${daysShort[date.weekday - 1]}, ${date.day} ${monthsShort[date.month - 1]} · ${date.hour}:${date.minute.toString().padLeft(2, '0')} — ${(date.add(const Duration(hours: 2))).hour}:${(date.add(const Duration(hours: 2))).minute.toString().padLeft(2, '0')}';
    }
  }
}
