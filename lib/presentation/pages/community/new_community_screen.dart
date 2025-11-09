import 'package:flutter/material.dart';
import '../../../domain/entities/community.dart';
import '../../../domain/entities/community_category.dart';
import 'community_detail_screen.dart';

class NewCommunityScreen extends StatefulWidget {
  const NewCommunityScreen({super.key});

  @override
  State<NewCommunityScreen> createState() => _NewCommunityScreenState();
}

class _NewCommunityScreenState extends State<NewCommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLocation = 'Jakarta';
  CommunityCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  // Mock data - nanti diganti dengan BLoC
  final List<Community> _allCommunities = [
    Community(
      id: '1',
      name: 'Boyolali Developers',
      description: 'Komunitas developer lokal yang suka sharing & ngumpul bareng',
      category: CommunityCategory.tech,
      location: 'Boyolali',
      memberCount: 89,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      isVerified: true,
      icon: '💻',
    ),
    Community(
      id: '2',
      name: 'Jakarta Football Club',
      description: 'Main bola bareng tiap weekend. Open untuk semua level!',
      category: CommunityCategory.sports,
      location: 'Jakarta',
      memberCount: 234,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      isVerified: true,
      icon: '⚽',
    ),
    Community(
      id: '3',
      name: 'Bandung Photography',
      description: 'Komunitas fotografer Bandung. From beginner to pro!',
      category: CommunityCategory.creative,
      location: 'Bandung',
      memberCount: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      icon: '📸',
    ),
    Community(
      id: '4',
      name: 'Surabaya Foodies',
      description: 'Pecinta kuliner Surabaya. Explore makanan baru bareng!',
      category: CommunityCategory.food,
      location: 'Surabaya',
      memberCount: 312,
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      isVerified: true,
      icon: '🍜',
    ),
    Community(
      id: '5',
      name: 'Jakarta Startup Founders',
      description: 'Komunitas entrepreneur & startup founders di Jakarta',
      category: CommunityCategory.professional,
      location: 'Jakarta',
      memberCount: 189,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      isVerified: true,
      icon: '💼',
    ),
    Community(
      id: '6',
      name: 'Yogyakarta Hikers',
      description: 'Suka hiking? Join kami explore gunung-gunung di Jogja!',
      category: CommunityCategory.sports,
      location: 'Yogyakarta',
      memberCount: 145,
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      icon: '🏔️',
    ),
  ];

  List<Community> _joinedCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Mock: user sudah join beberapa communities
    _joinedCommunities = [_allCommunities[0], _allCommunities[1]];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Community> get _filteredCommunities {
    var filtered = _allCommunities;

    // Filter by location
    filtered = filtered.where((c) => c.location == _selectedLocation).toList();

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((c) => c.category == _selectedCategory).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '👥 Communities',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF84994F),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Jelajah'),
            Tab(text: 'Joined'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildJoinedTab(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _filteredCommunities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCommunities.length,
                  itemBuilder: (context, index) {
                    return _buildCommunityCard(_filteredCommunities[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJoinedTab() {
    if (_joinedCommunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Kamu belum join community',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore dan join community sekarang!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84994F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Jelajah Communities',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _joinedCommunities.length,
      itemBuilder: (context, index) {
        return _buildCommunityCard(_joinedCommunities[index], isJoined: true);
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: '🔍 Cari community...',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Location selector
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Color(0xFF84994F)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: ['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Boyolali']
                      .map((location) => DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('Semua', null),
                const SizedBox(width: 8),
                ...CommunityCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      '${category.emoji} ${category.displayName}',
                      category,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, CommunityCategory? category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF84994F).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF84994F) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF84994F) : Colors.transparent,
        width: 1.5,
      ),
    );
  }

  Widget _buildCommunityCard(Community community, {bool isJoined = false}) {
    final bool userJoined = _joinedCommunities.any((c) => c.id == community.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              community: community,
              isJoined: userJoined,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon/Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF84994F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      community.icon ?? community.category.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (community.isVerified)
                            const Icon(
                              Icons.verified,
                              size: 18,
                              color: Color(0xFF84994F),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberCount} members',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            community.location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              community.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (userJoined) {
                      _joinedCommunities.removeWhere((c) => c.id == community.id);
                    } else {
                      _joinedCommunities.add(community);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: userJoined
                      ? Colors.grey[200]
                      : const Color(0xFF84994F),
                  foregroundColor: userJoined ? Colors.black87 : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  userJoined ? 'Joined ✓' : 'Join Community',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Ga ada community yang cocok',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau lokasi',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
