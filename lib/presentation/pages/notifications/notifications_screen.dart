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
  String _selectedFilter = 'all';

  // REMOVED MOCK DATA - Ready for API integration
  // Once backend implements GET /notifications endpoint, integrate with NotificationsBloc
  final List<domain.Notification> _notifications = [];

  @override
  void initState() {
    super.initState();
    // TODO: Call NotificationsBloc to load notifications from API
    // context.read<NotificationsBloc>().add(LoadNotifications());
  }

  List<domain.Notification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'events':
        return _notifications.where((n) =>
          n.type == domain.NotificationType.eventReminder ||
          n.type == domain.NotificationType.eventJoined
        ).toList();
      case 'social':
        return _notifications.where((n) =>
          n.type == domain.NotificationType.like ||
          n.type == domain.NotificationType.comment ||
          n.type == domain.NotificationType.follow
        ).toList();
      default:
        return _notifications;
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF000000),
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount belum dibaca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                // TODO: Call API to mark all notifications as read
                // context.read<NotificationsBloc>().add(MarkAllAsRead());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur akan tersedia setelah integrasi backend'),
                    backgroundColor: Color(0xFF84994F),
                  ),
                );
              },
              child: const Text(
                'Tandai Semua',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF84994F),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_filteredNotifications[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Semua', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Belum Dibaca', 'unread'),
          const SizedBox(width: 8),
          _buildFilterChip('Event', 'events'),
          const SizedBox(width: 8),
          _buildFilterChip('Sosial', 'social'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF84994F),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF84994F) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Notification notification) {
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
    String message;
    String icon;

    switch (_selectedFilter) {
      case 'unread':
        message = 'Semua notifikasi sudah dibaca';
        icon = '✓';
        break;
      case 'events':
        message = 'Belum ada notifikasi event';
        icon = '🎉';
        break;
      case 'social':
        message = 'Belum ada notifikasi sosial';
        icon = '👥';
        break;
      default:
        message = 'Belum ada notifikasi nih';
        icon = '🔔';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            message,
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
