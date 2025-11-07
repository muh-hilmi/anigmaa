import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event_location.dart';
import '../../../domain/entities/event_host.dart';
import '../event_detail/event_detail_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Event> _attendingEvents = [
    Event(
      id: '1',
      title: 'Flutter Developer Meetup',
      description: 'Join us for an exciting Flutter development discussion',
      category: EventCategory.meetup,
      startTime: DateTime.now().add(const Duration(days: 3)),
      endTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
      location: const EventLocation(
        name: 'Tech Hub Jakarta',
        address: 'Jl. Sudirman No. 123, Jakarta',
        latitude: -6.2088,
        longitude: 106.8456,
      ),
      host: const EventHost(
        id: 'host1',
        name: 'Flutter Indonesia',
        bio: 'Flutter Community',
        avatar: 'https://picsum.photos/100/100?random=1',
        rating: 4.8,
        eventsHosted: 25,
        isVerified: true,
      ),
      maxAttendees: 50,
      attendeeIds: ['user1', 'user2'],
      isFree: true,
      imageUrls: ['https://picsum.photos/600/400?random=1'],
    ),
    Event(
      id: '2',
      title: 'Weekend Photography Walk',
      description: 'Explore the city and capture beautiful moments',
      category: EventCategory.creative,
      startTime: DateTime.now().add(const Duration(days: 5)),
      endTime: DateTime.now().add(const Duration(days: 5, hours: 3)),
      location: const EventLocation(
        name: 'Taman Suropati',
        address: 'Menteng, Jakarta Pusat',
        latitude: -6.1944,
        longitude: 106.8229,
      ),
      host: const EventHost(
        id: 'host2',
        name: 'Jakarta Photo Club',
        bio: 'Photography enthusiasts',
        avatar: 'https://picsum.photos/100/100?random=2',
        rating: 4.5,
        eventsHosted: 15,
        isVerified: false,
      ),
      maxAttendees: 20,
      attendeeIds: ['user1'],
      price: 50000,
      isFree: false,
      imageUrls: ['https://picsum.photos/600/400?random=2'],
    ),
  ];

  final List<Event> _hostedEvents = [
    Event(
      id: '3',
      title: 'Mobile App Design Workshop',
      description: 'Learn the fundamentals of mobile app design',
      category: EventCategory.workshop,
      startTime: DateTime.now().add(const Duration(days: 7)),
      endTime: DateTime.now().add(const Duration(days: 7, hours: 4)),
      location: const EventLocation(
        name: 'Creative Space',
        address: 'Jl. Kemang Raya No. 45, Jakarta',
        latitude: -6.2615,
        longitude: 106.8107,
      ),
      host: const EventHost(
        id: 'current_user',
        name: 'John Doe',
        bio: 'UI/UX Designer',
        avatar: 'https://picsum.photos/100/100?random=3',
        rating: 4.7,
        eventsHosted: 8,
        isVerified: true,
      ),
      maxAttendees: 30,
      attendeeIds: ['user2', 'user3', 'user4'],
      price: 150000,
      isFree: false,
      imageUrls: ['https://picsum.photos/600/400?random=3'],
    ),
  ];

  final List<Event> _pastEvents = [
    Event(
      id: '4',
      title: 'Tech Conference 2024',
      description: 'Annual technology conference with industry leaders',
      category: EventCategory.networking,
      startTime: DateTime.now().subtract(const Duration(days: 30)),
      endTime: DateTime.now().subtract(const Duration(days: 30, hours: -8)),
      location: const EventLocation(
        name: 'Jakarta Convention Center',
        address: 'Jl. Gatot Subroto, Jakarta',
        latitude: -6.2297,
        longitude: 106.8259,
      ),
      host: const EventHost(
        id: 'host3',
        name: 'Tech Indonesia',
        bio: 'Technology community',
        avatar: 'https://picsum.photos/100/100?random=4',
        rating: 4.9,
        eventsHosted: 50,
        isVerified: true,
      ),
      maxAttendees: 500,
      attendeeIds: List.generate(450, (index) => 'user$index'),
      price: 500000,
      isFree: false,
      imageUrls: ['https://picsum.photos/600/400?random=4'],
      status: EventStatus.ended,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Event Gue',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Ikutan'),
            Tab(text: 'Bikin'),
            Tab(text: 'Udah Lewat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(_attendingEvents, 'attending'),
          _buildEventsList(_hostedEvents, 'hosting'),
          _buildEventsList(_pastEvents, 'past'),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<Event> events, String type) {
    if (events.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return _buildEventCard(events[index], type);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'attending':
        title = 'Belum Ada Event Nih';
        subtitle = 'Lo belum ikutan event apapun. Yuk explore buat cari event seru!';
        icon = Icons.event_available;
        break;
      case 'hosting':
        title = 'Belum Bikin Event';
        subtitle = 'Lo belum bikin event nih. Gas bikin event pertama lo!';
        icon = Icons.add_circle_outline;
        break;
      case 'past':
        title = 'Belum Ada Riwayat';
        subtitle = 'Riwayat event lo bakal muncul di sini';
        icon = Icons.history;
        break;
      default:
        title = 'Belum Ada Event';
        subtitle = 'Event ga ditemukan';
        icon = Icons.event_note;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrls.isNotEmpty)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      event.imageUrls.first,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported, size: 50),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(event, type),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getStatusText(event, type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventDate(event.startTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${event.currentAttendees} orang ikutan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (type == 'hosting')
                        TextButton(
                          onPressed: () => _manageEvent(event),
                          child: const Text(
                            'Kelola',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Event event, String type) {
    if (type == 'past') return Colors.grey;
    if (type == 'hosting') return Colors.blue;

    final now = DateTime.now();
    if (event.startTime.isBefore(now) && event.endTime.isAfter(now)) {
      return Colors.green; // Lagi berlangsung
    } else if (event.startTime.isAfter(now)) {
      return Colors.orange; // Akan datang
    }
    return Colors.grey; // Udah lewat
  }

  String _getStatusText(Event event, String type) {
    if (type == 'past') return 'Udah Ikutan';
    if (type == 'hosting') return 'Bikin';

    final now = DateTime.now();
    if (event.startTime.isBefore(now) && event.endTime.isAfter(now)) {
      return 'Lagi Berlangsung';
    } else if (event.startTime.isAfter(now)) {
      return 'Akan Datang';
    }
    return 'Udah Selesai';
  }

  String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Besok';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lagi';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else if (difference.inDays < 0) {
      final daysPast = -difference.inDays;
      if (daysPast == 1) {
        return 'Kemarin';
      } else if (daysPast < 7) {
        return '$daysPast hari lalu';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else {
      return 'Hari ini';
    }
  }

  void _manageEvent(Event event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(context);
                _editEvent(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Lihat Peserta'),
              onTap: () {
                Navigator.pop(context);
                _viewAttendees(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Event'),
              onTap: () {
                Navigator.pop(context);
                _shareEvent(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Batalkan Event'),
              onTap: () {
                Navigator.pop(context);
                _cancelEvent(event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editEvent(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur edit event lagi dikerjain nih!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewAttendees(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur lihat peserta lagi dikerjain nih!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareEvent(Event event) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur share event lagi dikerjain nih!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Event'),
        content: Text('Lo yakin mau batalin event "${event.title}" nih? Ini ga bisa diundo lho!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tetep Lanjut'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Event berhasil dibatalin'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}