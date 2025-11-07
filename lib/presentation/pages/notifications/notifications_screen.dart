import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';

  // TODO: Replace with real data from BLoC/Repository
  final List<NotificationItem> _mockNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  void _initializeMockData() {
    _mockNotifications.addAll([
      NotificationItem(
        id: 'notif1',
        type: NotificationType.like,
        title: 'Andi dan 12 lainnya',
        message: 'menyukai postingan lo',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        avatarUrl: null,
        actionUrl: '/post/123',
      ),
      NotificationItem(
        id: 'notif2',
        type: NotificationType.comment,
        title: 'Budi',
        message: 'berkomentar di postingan lo: "Setuju banget nih!"',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        avatarUrl: null,
        actionUrl: '/post/124',
      ),
      NotificationItem(
        id: 'notif3',
        type: NotificationType.eventReminder,
        title: 'Weekend Music Fest',
        message: 'Event dimulai besok pukul 14:00',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
        avatarUrl: null,
        actionUrl: '/event/001',
      ),
      NotificationItem(
        id: 'notif4',
        type: NotificationType.follow,
        title: 'Sarah',
        message: 'mulai mengikuti lo',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
        avatarUrl: null,
        actionUrl: '/profile/sarah',
      ),
      NotificationItem(
        id: 'notif5',
        type: NotificationType.eventJoined,
        title: 'Tech Conference 2025',
        message: 'Lo udah berhasil join event ini. Cari temen yuk!',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
        avatarUrl: null,
        actionUrl: '/event/002',
      ),
    ]);
  }

  List<NotificationItem> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'unread':
        return _mockNotifications.where((n) => !n.isRead).toList();
      case 'events':
        return _mockNotifications.where((n) =>
          n.type == NotificationType.eventReminder ||
          n.type == NotificationType.eventJoined
        ).toList();
      case 'social':
        return _mockNotifications.where((n) =>
          n.type == NotificationType.like ||
          n.type == NotificationType.comment ||
          n.type == NotificationType.follow
        ).toList();
      default:
        return _mockNotifications;
    }
  }

  int get _unreadCount {
    return _mockNotifications.where((n) => !n.isRead).length;
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
                setState(() {
                  for (var notification in _mockNotifications) {
                    notification.isRead = true;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai sudah dibaca'),
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

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      color: notification.isRead ? Colors.white : const Color(0xFFFAF8F5),
      child: InkWell(
        onTap: () {
          setState(() {
            notification.isRead = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigasi ke ${notification.actionUrl}'),
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

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.eventJoined:
        return Icons.check_circle;
      case NotificationType.eventInvite:
        return Icons.mail;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.red;
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.follow:
        return const Color(0xFF84994F);
      case NotificationType.eventReminder:
        return Colors.orange;
      case NotificationType.eventJoined:
        return const Color(0xFF84994F);
      case NotificationType.eventInvite:
        return Colors.purple;
    }
  }
}

// Models
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? avatarUrl;
  final String actionUrl;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.avatarUrl,
    required this.actionUrl,
  });
}

enum NotificationType {
  like,
  comment,
  follow,
  eventReminder,
  eventJoined,
  eventInvite,
}
