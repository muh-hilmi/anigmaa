import 'package:flutter/material.dart';
import 'user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  final String title;
  final bool isFollowers; // true for followers, false for following

  const FollowersScreen({
    super.key,
    required this.userId,
    required this.title,
    this.isFollowers = true,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<UserFollow> _users = [];
  List<UserFollow> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _users = _generateMockUsers();
      _filteredUsers = _users;
      _isLoading = false;
    });
  }

  List<UserFollow> _generateMockUsers() {
    return List.generate(20, (index) {
      return UserFollow(
        id: 'user_$index',
        name: _getRandomName(index),
        avatar: 'https://picsum.photos/100/100?random=$index',
        bio: _getRandomBio(index),
        isFollowing: index % 3 != 0,
        isVerified: index % 5 == 0,
        mutualFollowers: index % 4 == 0 ? ['mutual1', 'mutual2'] : [],
      );
    });
  }

  String _getRandomName(int index) {
    final names = [
      'Sarah Chen', 'Mike Johnson', 'Jessica Wong', 'David Kim',
      'Emily Rodriguez', 'Alex Thompson', 'Maria Garcia', 'James Wilson',
      'Lisa Anderson', 'Chris Lee', 'Amanda Davis', 'Kevin Brown',
      'Sophie Taylor', 'Daniel Martinez', 'Rachel Green', 'Ryan Clark',
      'Michelle White', 'Justin Harris', 'Jennifer Lewis', 'Michael Scott'
    ];
    return names[index % names.length];
  }

  String _getRandomBio(int index) {
    final bios = [
      'Photography enthusiast 📸',
      'Tech lover & coffee addict ☕',
      'Event organizer & community builder',
      'Travel blogger ✈️',
      'Fitness coach & wellness advocate',
      'Foodie & cooking enthusiast 🍳',
      'Music lover & event planner 🎵',
      'Startup founder & entrepreneur',
      'Designer & creative thinker',
      'Developer & tech speaker',
    ];
    return bios[index % bios.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari ${widget.isFollowers ? 'followers' : 'following'}...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterUsers();
          });
        },
      ),
    );
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = _users;
    } else {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.bio.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Belum ada ${widget.isFollowers ? 'followers' : 'following'} nih'
                  : 'Gak ada user yang ditemukan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Yuk mulai connect dengan orang lain!'
                  : 'Coba cari yang lain deh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_filteredUsers[index]);
      },
    );
  }

  Widget _buildUserCard(UserFollow user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(user.avatar),
            ),
            if (user.isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.mutualFollowers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${user.mutualFollowers.length} temen sama',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user.bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (user.mutualFollowers.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Di-follow sama temen lo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        trailing: SizedBox(
          width: 80,
          child: ElevatedButton(
            onPressed: () => _toggleFollow(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isFollowing ? Colors.grey[200] : Colors.black,
              foregroundColor: user.isFollowing ? Colors.black87 : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: Text(
              user.isFollowing ? 'Udah Follow' : 'Follow',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: user.id,
                userName: user.name,
              ),
            ),
          );
        },
      ),
    );
  }

  void _toggleFollow(UserFollow user) {
    setState(() {
      user.isFollowing = !user.isFollowing;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class UserFollow {
  final String id;
  final String name;
  final String avatar;
  final String bio;
  bool isFollowing;
  final bool isVerified;
  final List<String> mutualFollowers;

  UserFollow({
    required this.id,
    required this.name,
    required this.avatar,
    required this.bio,
    this.isFollowing = false,
    this.isVerified = false,
    this.mutualFollowers = const [],
  });
}