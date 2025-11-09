import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_category.dart';

class ModernEventMiniCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onJoin;
  final VoidCallback? onFindMatches;

  const ModernEventMiniCard({
    super.key,
    required this.event,
    this.onJoin,
    this.onFindMatches,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnded = event.status == EventStatus.ended || event.hasEnded;

    return Opacity(
      opacity: isEnded ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: isEnded ? const Color(0xFFE8E4DD) : const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnded ? Colors.grey.shade400 : const Color(0xFFE8E4DD),
            width: 1.5,
          ),
        ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Title with Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isEnded ? Colors.grey[600] : const Color(0xFF000000),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEnded) ...[
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Info Row - Time
          _buildInfoRow(
            Icons.access_time_rounded,
            _formatEventDateTime(),
            isEnded,
          ),
          const SizedBox(height: 8),

          // Info Row - Location
          _buildInfoRow(
            Icons.location_on_rounded,
            event.location.name,
            isEnded,
          ),
          const SizedBox(height: 14),

          // Bottom Row - Participants & Price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE8E4DD), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: isEnded ? Colors.grey[600] : Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEnded
                          ? '${event.currentAttendees} attended'
                          : '${event.currentAttendees} joined',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isEnded ? Colors.grey[600] : const Color(0xFF000000),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Price Badge (only for upcoming)
              if (!isEnded) _buildPriceBadge(),
            ],
          ),

          // Buttons Row
          // Row(
          //   children: [
          //     Expanded(
          //       child: ElevatedButton(
          //         onPressed: onJoin,
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: const Color(0xFFE53E3E),
          //           foregroundColor: Colors.white,
          //           padding: const EdgeInsets.symmetric(vertical: 12),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //           elevation: 0,
          //         ),
          //         child: const Text(
          //           'Join Event',
          //           style: TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       ),
          //     ),
          //     const SizedBox(width: 10),
          //     Expanded(
          //       child: OutlinedButton(
          //         onPressed: onFindMatches,
          //         style: OutlinedButton.styleFrom(
          //           foregroundColor: const Color(0xFFE53E3E),
          //           padding: const EdgeInsets.symmetric(vertical: 12),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //           side: const BorderSide(
          //             color: Color(0xFFE53E3E),
          //             width: 1.5,
          //           ),
          //         ),
          //         child: const Text(
          //           'Find Matches',
          //           style: TextStyle(
          //             fontSize: 14,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      ),
    );
  }


  Widget _buildInfoRow(IconData icon, String text, bool isEnded) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isEnded ? Colors.grey[500] : Colors.grey[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isEnded ? Colors.grey[600] : Colors.grey[700],
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'ENDED',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Widget _buildParticipantAvatars() {
  //   // Show up to 3 stacked avatars
  //   const maxAvatars = 3;
  //   final avatarCount = event.currentAttendees > maxAvatars
  //       ? maxAvatars
  //       : event.currentAttendees;

  //   if (avatarCount == 0) {
  //     return const SizedBox.shrink();
  //   }

  //   return SizedBox(
  //     width: avatarCount * 18.0 + 6,
  //     height: 24,
  //     child: Stack(
  //       children: List.generate(avatarCount, (index) {
  //         return Positioned(
  //           left: index * 18.0,
  //           child: Container(
  //             width: 24,
  //             height: 24,
  //             decoration: BoxDecoration(
  //               shape: BoxShape.circle,
  //               border: Border.all(color: const Color(0xFFF5F5F7), width: 2),
  //               color: const Color(0xFF84994F).withValues(alpha: 0.2),
  //             ),
  //             child: CircleAvatar(
  //               radius: 10,
  //               backgroundColor: const Color(0xFF84994F).withValues(alpha: 0.15),
  //               child: Text(
  //                 String.fromCharCode(65 + index), // A, B, C
  //                 style: const TextStyle(
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.w600,
  //                   color: Color(0xFF84994F),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         );
  //       }),
  //     ),
  //   );
  // }

  Widget _buildPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: event.isFree ? const Color(0xFF000000) : const Color(0xFF84994F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        event.isFree ? 'Gratis' : 'Rp ${_formatPrice(event.price ?? 0)}',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  String _formatEventDateTime() {
    final now = DateTime.now();
    final diff = event.startTime.difference(now);

    const daysShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

    // Check if event has ended
    if (event.hasEnded) {
      return 'Sudah selesai · ${daysShort[event.startTime.weekday - 1]}, ${event.startTime.day} ${monthsShort[event.startTime.month - 1]}';
    }

    // Format waktu relatif yang mudah dipahami
    if (diff.inMinutes < 60 && diff.inMinutes >= 0) {
      if (diff.inMinutes < 1) {
        return 'Dimulai sekarang! 🔥';
      } else if (diff.inMinutes <= 30) {
        return '${diff.inMinutes} menit lagi! ⚡';
      } else {
        return '${diff.inMinutes} menit lagi';
      }
    } else if (diff.inHours < 24 && diff.inHours >= 0) {
      return '${diff.inHours} jam lagi! 🔥';
    } else if (diff.inDays == 0) {
      return 'Hari ini · ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Besok · ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lagi! · ${daysShort[event.startTime.weekday - 1]}, ${event.startTime.day} ${monthsShort[event.startTime.month - 1]}';
    } else {
      return '${daysShort[event.startTime.weekday - 1]}, ${event.startTime.day} ${monthsShort[event.startTime.month - 1]} · ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }
}
