import 'package:flutter/material.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../domain/entities/event_location.dart';
import '../../../domain/entities/event_host.dart';
import '../event_detail/event_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoading = false;

  // Mock user data
  late User _user;
  late List<Event> _userEvents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    _user = User(
      id: widget.userId,
      email: 'user@example.com',
      name: widget.userName,
      bio: 'Event enthusiast and community builder. Love connecting with like-minded people and creating memorable experiences. Always excited for the next adventure! 🎉',
      avatar: 'https://picsum.photos/200/200?random=${widget.userId.hashCode}',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      interests: ['Technology', 'Photography', 'Travel', 'Food', 'Music'],
      settings: const UserSettings(),
      stats: const UserStats(
        eventsAttended: 45,
        eventsCreated: 12,
        followersCount: 234,
        followingCount: 189,
        reviewsGiven: 32,
        averageRating: 4.6,
      ),
      privacy: const UserPrivacy(),
    );

    _userEvents = [
      Event(
        id: 'event1',
        title: 'Street Photography Workshop',
        description: 'Learn the art of street photography with professional tips',
        category: EventCategory.creative,
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 3)),
        location: const EventLocation(
          name: 'Kota Tua Jakarta',
          address: 'Jakarta Barat',
          latitude: -6.1352,
          longitude: 106.8133,
        ),
        host: EventHost(
          id: widget.userId,
          name: widget.userName,
          bio: 'Photography enthusiast',
          avatar: 'https://picsum.photos/200/200?random=${widget.userId.hashCode}',
          rating: 4.6,
          eventsHosted: 12,
          isVerified: true,
        ),
        maxAttendees: 15,
        attendeeIds: ['user1', 'user2', 'user3'],
        price: 75000,
        isFree: false,
        imageUrls: ['https://picsum.photos/600/400?random=101'],
      ),
      Event(
        id: 'event2',
        title: 'Tech Meetup: Flutter Development',
        description: 'Monthly Flutter developer meetup and networking',
        category: EventCategory.meetup,
        startTime: DateTime.now().add(const Duration(days: 12)),
        endTime: DateTime.now().add(const Duration(days: 12, hours: 2)),
        location: const EventLocation(
          name: 'Tech Hub Jakarta',
          address: 'Sudirman, Jakarta',
          latitude: -6.2088,
          longitude: 106.8456,
        ),
        host: EventHost(
          id: widget.userId,
          name: widget.userName,
          bio: 'Flutter developer',
          avatar: 'https://picsum.photos/200/200?random=${widget.userId.hashCode}',
          rating: 4.6,
          eventsHosted: 12,
          isVerified: true,
        ),
        maxAttendees: 50,
        attendeeIds: List.generate(32, (index) => 'user$index'),
        isFree: true,
        imageUrls: ['https://picsum.photos/600/400?random=102'],
      ),
    ];

    _isFollowing = [true, false, true][widget.userId.hashCode % 3] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileInfo(),
                _buildStatsSection(),
                _buildTabSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      expandedHeight: 120,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: _showMoreOptions,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_user.avatar ?? ''),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (_user.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: Colors.blue[600],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gabung sejak ${_formatJoinDate(_user.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_user.bio != null) ...[
            const SizedBox(height: 16),
            Text(
              _user.bio!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          if (_user.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _user.interests.take(5).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? Colors.grey[200] : Colors.black,
                    foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isFollowing ? 'Udah Follow' : 'Follow',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _sendMessage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pesan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Event\nDihadiri', _user.stats.eventsAttended.toString()),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem('Event\nDibuat', _user.stats.eventsCreated.toString()),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem('Followers', _user.stats.followersCount.toString()),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem('Following', _user.stats.followingCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return GestureDetector(
      onTap: () => _showStatDetail(label, value),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: const [
              Tab(text: 'Event'),
              Tab(text: 'Review'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_userEvents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada event nih',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userEvents.length,
      itemBuilder: (context, index) {
        return _buildEventCard(_userEvents[index]);
      },
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  event.imageUrls.isNotEmpty
                      ? event.imageUrls.first
                      : 'https://picsum.photos/100/100',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatEventDate(event.startTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.currentAttendees} ikutan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildReviewCard(index);
      },
    );
  }

  Widget _buildReviewCard(int index) {
    final reviews = [
      {
        'event': 'Tech Conference 2024',
        'rating': 5,
        'comment': 'Amazing event! Great speakers and networking opportunities.',
        'date': '2 weeks ago',
      },
      {
        'event': 'Photography Workshop',
        'rating': 4,
        'comment': 'Learned a lot about composition and lighting techniques.',
        'date': '1 month ago',
      },
      {
        'event': 'Food Festival',
        'rating': 5,
        'comment': 'Incredible variety of food and great atmosphere!',
        'date': '2 months ago',
      },
    ];

    final review = reviews[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review['event'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      starIndex < (review['rating'] as int)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review['comment'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              review['date'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Besok';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari lagi';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } else {
      return 'Hari ini';
    }
  }

  void _toggleFollow() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isFollowing = !_isFollowing;
      _isLoading = false;

      if (_isFollowing) {
        _user = _user.copyWith(
          stats: _user.stats.copyWith(
            followersCount: _user.stats.followersCount + 1,
          ),
        );
      } else {
        _user = _user.copyWith(
          stats: _user.stats.copyWith(
            followersCount: _user.stats.followersCount - 1,
          ),
        );
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Udah follow ${_user.name} nih!' : 'Unfollow ${_user.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur pesan masih dalam pengembangan nih!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profil'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Blokir User'),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Laporkan User'),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link profil udah dicopy nih!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blokir User'),
        content: Text('Yakin mau blokir ${_user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_user.name} udah diblokir')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Blokir'),
          ),
        ],
      ),
    );
  }

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_user.name} udah dilaporin nih'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showStatDetail(String label, String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label: $value'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}