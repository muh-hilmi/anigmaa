import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Not strictly needed if we just pass File?
import 'dart:io';
import '../../../../domain/entities/event_category.dart';
import '../../../../core/utils/event_category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
// For LocationData type if needed, or just pass name

// Assuming LocationData is from location_picker.dart or similar.
// If LocationData is not exported, I might need to import it.
// In the original file: import '../../widgets/location_picker.dart';
// Let's check location_picker.dart to see if LocationData is defined there.

class EventPreviewCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime startDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String locationName;
  final EventCategory category;
  final bool isFree;
  final double price;
  final int capacity;
  final EventPrivacy privacy;
  final File? coverImage;

  const EventPreviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.startDate,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.category,
    required this.isFree,
    required this.price,
    required this.capacity,
    required this.privacy,
    this.coverImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBC863), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event title
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBBC863),
            ),
          ),
          const SizedBox(height: 8),

          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFBBC863).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              EventCategoryUtils.getCategoryDisplayName(category),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBBC863),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const Divider(height: 24),

          // Event details
          _buildPreviewRow(
            context,
            Icons.calendar_today,
            '${DateFormat('dd MMM yyyy').format(startDate)} • ${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
          ),
          const SizedBox(height: 8),
          _buildPreviewRow(context, Icons.location_on, locationName),
          const SizedBox(height: 8),
          _buildPreviewRow(context, Icons.people, '$capacity orang'),
          const SizedBox(height: 8),
          _buildPreviewRow(
            context,
            isFree ? Icons.card_giftcard : Icons.attach_money,
            isFree ? 'Gratis' : CurrencyFormatter.formatToRupiah(price),
          ),
          const SizedBox(height: 8),
          _buildPreviewRow(
            context,
            privacy == EventPrivacy.public ? Icons.public : Icons.lock,
            privacy == EventPrivacy.public ? 'Publik' : 'Private',
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Widget _buildPreviewRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}
