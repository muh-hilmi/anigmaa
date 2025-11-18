import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../domain/entities/notification.dart' as domain;

// TODO: Implement NotificationsBloc for state management
// TODO: Create NotificationRepository with API datasource
// TODO: Backend must implement GET /notifications endpoint
//
// Required API Response Format:
// {
//   "success": true,
//   "data": [
//     {
//       "id": "notif123",
//       "type": "like",
//       "title": "Andi dan 12 lainnya",
//       "message": "menyukai postingan lo",
//       "timestamp": "2025-11-18T10:30:00Z",
//       "is_read": false,
//       "avatar_url": "https://...",
//       "action_url": "/post/123",
//       "metadata": {"post_id": "123", "user_ids": ["user1", "user2"]}
//     }
//   ],
//   "meta": {
//     "total": 50,
//     "limit": 20,
//     "offset": 0,
//     "hasNext": true
//   }
// }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // REMOVED MOCK DATA - Ready for API integration
  // Once backend implements GET /notifications endpoint, integrate with NotificationsBloc
  // All notifications are shown without filtering
  final List<domain.Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    // TODO: Call NotificationsBloc to load notifications from API
    // context.read<NotificationsBloc>().add(LoadNotifications());
    // TODO: Mark all notifications as read when page is opened (like Instagram)
    // context.read<NotificationsBloc>().add(MarkAllAsRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF000000),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }


  Widget _buildNotificationItem(domain.Notification notification) {
    return Container(
      color: notification.isRead ? Colors.white : const Color(0xFFFAF8F5),
      child: InkWell(
        onTap: () {
          // TODO: Mark notification as read via API
          // context.read<NotificationsBloc>().add(MarkAsRead(notification.id));

          // TODO: Navigate to actionUrl
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigasi ke ${notification.actionUrl ?? "detail"}'),
              backgroundColor: const Color(0xFF84994F),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: ' ${notification.message}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.timestamp, locale: 'en_short'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF84994F),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔔',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi nih',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.like:
        return Icons.favorite;
      case domain.NotificationType.comment:
        return Icons.chat_bubble;
      case domain.NotificationType.follow:
        return Icons.person_add;
      case domain.NotificationType.eventReminder:
        return Icons.event;
      case domain.NotificationType.eventJoined:
        return Icons.check_circle;
      case domain.NotificationType.eventInvite:
        return Icons.mail;
      case domain.NotificationType.repost:
        return Icons.repeat;
      case domain.NotificationType.mention:
        return Icons.alternate_email;
    }
  }

  Color _getNotificationColor(domain.NotificationType type) {
    switch (type) {
      case domain.NotificationType.like:
        return Colors.red;
      case domain.NotificationType.comment:
        return Colors.blue;
      case domain.NotificationType.follow:
        return const Color(0xFF84994F);
      case domain.NotificationType.eventReminder:
        return Colors.orange;
      case domain.NotificationType.eventJoined:
        return const Color(0xFF84994F);
      case domain.NotificationType.eventInvite:
        return Colors.purple;
      case domain.NotificationType.repost:
        return const Color(0xFF84994F);
      case domain.NotificationType.mention:
        return Colors.deepPurple;
    }
  }
}

// NOTE: Notification entity and NotificationType enum are now in domain layer
// See: lib/domain/entities/notification.dart
// See: lib/data/models/notification_model.dart
