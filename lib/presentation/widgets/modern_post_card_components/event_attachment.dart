import 'package:flutter/material.dart';
import '../../../domain/entities/post.dart';
import '../../pages/event_detail/event_detail_screen.dart';
import '../modern_event_mini_card.dart';
import '../find_matches_modal.dart';

class EventAttachment extends StatelessWidget {
  final Post post;

  const EventAttachment({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.attachedEvent == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Navigate to event detail - stop propagation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: post.attachedEvent!),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ModernEventMiniCard(
          event: post.attachedEvent!,
          onJoin: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Mantap! Lo udah ikutan event ini. Cek "Cari Temen" yuk!',
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: const Color(0xFFBBC863),
              ),
            );
          },
          onFindMatches: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) => FindMatchesModal(
                  eventId: post.attachedEvent!.id,
                  eventTitle: post.attachedEvent!.title,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
