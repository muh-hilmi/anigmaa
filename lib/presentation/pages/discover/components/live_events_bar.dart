import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/entities/event.dart';
import '../../event_detail/event_detail_screen.dart';

class LiveEventsBar extends StatelessWidget {
  final List<Event> allEvents;

  const LiveEventsBar({super.key, required this.allEvents});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final liveEvents = allEvents.where((event) {
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
                return _LiveEventCard(event: liveEvents[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveEventCard extends StatelessWidget {
  final Event event;

  const _LiveEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
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
                            color: const Color(0xFFFCFCFC),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFFCFCFC),
                            child: const Icon(
                              Icons.event_rounded,
                              color: Color(0xFFBBC863),
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFFCFCFC),
                          child: const Icon(
                            Icons.event_rounded,
                            color: Color(0xFFBBC863),
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
}
