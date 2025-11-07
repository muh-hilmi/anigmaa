import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          '👥 Komunitas',
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
            Tab(text: 'Forum'),
            Tab(text: 'Grup'),
            Tab(text: 'Postingan Gue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForumsTab(),
          _buildGroupsTab(),
          _buildMyPostsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildForumsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildForumCard(
          title: 'Tech Meetups Discussion',
          description: 'Discuss upcoming tech events and share experiences',
          memberCount: 234,
          lastActivity: '2 hours ago',
          isActive: true,
        ),
        _buildForumCard(
          title: 'Sports & Recreation',
          description: 'Find sports partners and discuss fitness activities',
          memberCount: 156,
          lastActivity: '4 hours ago',
          isActive: true,
        ),
        _buildForumCard(
          title: 'Food & Dining',
          description: 'Share restaurant recommendations and food events',
          memberCount: 89,
          lastActivity: '1 day ago',
          isActive: false,
        ),
        _buildForumCard(
          title: 'Art & Creative',
          description: 'Connect with artists and creative professionals',
          memberCount: 67,
          lastActivity: '2 days ago',
          isActive: false,
        ),
        _buildForumCard(
          title: 'Professional Networking',
          description: 'Career discussions and networking opportunities',
          memberCount: 345,
          lastActivity: '5 hours ago',
          isActive: true,
        ),
      ],
    );
  }

  Widget _buildGroupsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildGroupCard(
          name: 'Flutter Developers',
          description: 'A group for Flutter developers to share knowledge and collaborate',
          memberCount: 128,
          isJoined: true,
          image: 'https://picsum.photos/100/100?random=1',
        ),
        _buildGroupCard(
          name: 'Photography Enthusiasts',
          description: 'Share your photography work and learn from others',
          memberCount: 92,
          isJoined: false,
          image: 'https://picsum.photos/100/100?random=2',
        ),
        _buildGroupCard(
          name: 'Hiking Club',
          description: 'Organize hiking trips and outdoor adventures',
          memberCount: 76,
          isJoined: true,
          image: 'https://picsum.photos/100/100?random=3',
        ),
        _buildGroupCard(
          name: 'Book Club',
          description: 'Discuss books and organize reading meetups',
          memberCount: 54,
          isJoined: false,
          image: 'https://picsum.photos/100/100?random=4',
        ),
        _buildGroupCard(
          name: 'Startup Founders',
          description: 'Connect with fellow entrepreneurs and startup founders',
          memberCount: 189,
          isJoined: true,
          image: 'https://picsum.photos/100/100?random=5',
        ),
      ],
    );
  }

  Widget _buildMyPostsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPostCard(
          title: 'Looking for Flutter developers for hackathon',
          content: 'We\'re organizing a Flutter hackathon next month and looking for passionate developers to join our team...',
          timeAgo: '2 hours ago',
          likeCount: 15,
          commentCount: 8,
          isLiked: true,
        ),
        _buildPostCard(
          title: 'Great photography meetup last weekend!',
          content: 'Thank you to everyone who joined the photography walk in Central Park. Here are some highlights...',
          timeAgo: '3 days ago',
          likeCount: 23,
          commentCount: 12,
          isLiked: false,
        ),
        _buildPostCard(
          title: 'Startup pitch event recommendations?',
          content: 'Can anyone recommend good startup pitch events in the city? Looking to network with investors...',
          timeAgo: '1 week ago',
          likeCount: 7,
          commentCount: 5,
          isLiked: false,
        ),
      ],
    );
  }

  Widget _buildForumCard({
    required String title,
    required String description,
    required int memberCount,
    required String lastActivity,
    required bool isActive,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openForum(title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$memberCount anggota',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Aktif terakhir: $lastActivity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard({
    required String name,
    required String description,
    required int memberCount,
    required bool isJoined,
    required String image,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.group),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$memberCount anggota',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _toggleGroupMembership(name, isJoined),
              style: ElevatedButton.styleFrom(
                backgroundColor: isJoined ? Colors.grey.shade200 : Colors.black,
                foregroundColor: isJoined ? Colors.black87 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(80, 36),
              ),
              child: Text(
                isJoined ? 'Udah Join' : 'Join',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required String title,
    required String content,
    required String timeAgo,
    required int likeCount,
    required int commentCount,
    required bool isLiked,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _toggleLike(title),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isLiked ? Colors.red : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likeCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$commentCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openForum(String forumName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buka forum $forumName...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleGroupMembership(String groupName, bool isCurrentlyJoined) {
    setState(() {
      // In a real app, this would make an API call
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCurrentlyJoined
            ? 'Keluar dari $groupName'
            : 'Udah join $groupName nih!'
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleLike(String postTitle) {
    setState(() {
      // In a real app, this would make an API call
    });
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Postingan Baru'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Judul postingan...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Lagi mikirin apa nih?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Postingan berhasil dibuat!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Post'),
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