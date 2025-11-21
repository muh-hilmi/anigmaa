import 'package:flutter/material.dart';
import '../profile/profile_screen.dart';

class DiscoverPeopleScreen extends StatefulWidget {
  const DiscoverPeopleScreen({super.key});

  @override
  State<DiscoverPeopleScreen> createState() => _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends State<DiscoverPeopleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<DiscoverUser> _suggestedUsers = [];
  final List<DiscoverUser> _nearbyUsers = [];
  final List<DiscoverUser> _trendingUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  void _loadUsers() {
    // Suggested users
    _suggestedUsers.addAll([
      DiscoverUser(
        id: 'user1',
        name: 'Sarah Photography',
        avatar: 'https://picsum.photos/100/100?random=1',
        bio: 'Professional photographer specializing in events',
        followers: 1250,
        events: 45,
        isVerified: true,
        mutualConnections: 12,
        interests: ['Photography', 'Events', 'Art'],
        reason: 'Populer di area lo',
      ),
      DiscoverUser(
        id: 'user2',
        name: 'Tech Meetup Jakarta',
        avatar: 'https://picsum.photos/100/100?random=2',
        bio: 'Organizing tech meetups and workshops',
        followers: 3400,
        events: 89,
        isVerified: true,
        mutualConnections: 8,
        interests: ['Technology', 'Networking'],
        reason: 'Minat yang sama nih',
      ),
      DiscoverUser(
        id: 'user3',
        name: 'Food Explorer',
        avatar: 'https://picsum.photos/100/100?random=3',
        bio: 'Food blogger and culinary event organizer',
        followers: 892,
        events: 23,
        mutualConnections: 5,
        interests: ['Food', 'Cooking', 'Travel'],
        reason: 'Di-follow temen lo',
      ),
    ]);

    // Nearby users
    _nearbyUsers.addAll([
      DiscoverUser(
        id: 'user4',
        name: 'Jakarta Sports Club',
        avatar: 'https://picsum.photos/100/100?random=4',
        bio: 'Community sports events and fitness activities',
        followers: 567,
        events: 34,
        distance: '2.1 km',
        interests: ['Sports', 'Fitness'],
        reason: 'Deket lokasi lo',
      ),
      DiscoverUser(
        id: 'user5',
        name: 'Creative Minds',
        avatar: 'https://picsum.photos/100/100?random=5',
        bio: 'Art workshops and creative meetups',
        followers: 423,
        events: 19,
        distance: '3.5 km',
        interests: ['Art', 'Creative', 'Workshop'],
        reason: 'Populer di sekitar sini',
      ),
    ]);

    // Trending users
    _trendingUsers.addAll([
      DiscoverUser(
        id: 'user6',
        name: 'Startup Founder',
        avatar: 'https://picsum.photos/100/100?random=6',
        bio: 'Building the future of event technology',
        followers: 5670,
        events: 67,
        isVerified: true,
        trending: true,
        interests: ['Business', 'Technology', 'Startup'],
        reason: 'Trending minggu ini',
      ),
      DiscoverUser(
        id: 'user7',
        name: 'Music Festival Organizer',
        avatar: 'https://picsum.photos/100/100?random=7',
        bio: 'Bringing amazing music experiences to life',
        followers: 8934,
        events: 156,
        isVerified: true,
        trending: true,
        interests: ['Music', 'Festival', 'Entertainment'],
        reason: 'Lagi hits banget',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cari Temen Baru',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _showSearchDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Rekomendasi'),
            Tab(text: 'Deket Sini'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersList(_suggestedUsers, 'suggested'),
          _buildUsersList(_nearbyUsers, 'nearby'),
          _buildUsersList(_trendingUsers, 'trending'),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<DiscoverUser> users, String type) {
    if (users.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(users[index]);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'suggested':
        title = 'Belum Ada Rekomendasi';
        subtitle = 'Gue bakal rekomendasiin orang berdasarkan aktivitas lo';
        icon = Icons.people_outline;
        break;
      case 'nearby':
        title = 'Belum Ada User Deket';
        subtitle = 'Aktifin lokasi buat cari orang di sekitar lo';
        icon = Icons.location_on_outlined;
        break;
      case 'trending':
        title = 'Belum Ada yang Trending';
        subtitle = 'Cek lagi nanti ya buat liat siapa yang lagi hits';
        icon = Icons.trending_up;
        break;
      default:
        title = 'Gak Ada User';
        subtitle = 'User gak ditemukan';
        icon = Icons.person_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
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
    );
  }

  Widget _buildUserCard(DiscoverUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(
                userId: user.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(user.avatar),
                      ),
                      if (user.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (user.trending)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.orange[600],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.bio,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${user.followers} followers',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.event, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '${user.events} event',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (user.distance != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                user.distance!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _followUser(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isFollowing ? Colors.grey[200] : Colors.black,
                      foregroundColor: user.isFollowing ? Colors.black87 : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      user.isFollowing ? 'Udah Follow' : 'Follow',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (user.reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (user.mutualConnections > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${user.mutualConnections} temen yang sama',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              if (user.interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _followUser(DiscoverUser user) {
    setState(() {
      user.isFollowing = !user.isFollowing;
      if (user.isFollowing) {
        user.followers++;
      } else {
        user.followers--;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isFollowing ? 'Udah follow ${user.name} nih!' : 'Unfollow ${user.name}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari Orang'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Masukkin nama atau username...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch(_searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lagi nyari "$query"...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class DiscoverUser {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  int followers;
  final int events;
  final bool isVerified;
  final int mutualConnections;
  final List<String> interests;
  final String reason;
  final String? distance;
  final bool trending;
  bool isFollowing;

  DiscoverUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.followers,
    required this.events,
    this.isVerified = false,
    this.mutualConnections = 0,
    this.interests = const [],
    this.reason = '',
    this.distance,
    this.trending = false,
    this.isFollowing = false,
  });
}