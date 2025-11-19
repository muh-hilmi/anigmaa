import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../../data/datasources/event_remote_datasource.dart';
import '../../../injection_container.dart' as di;
import '../../../domain/usecases/get_user_by_id.dart';
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../widgets/modern_post_card.dart';
import '../event_detail/event_detail_screen.dart';
import 'edit_profile_screen.dart';

/// Reusable profile screen that can show current user or other users
/// Pass userId to show other user's profile, null shows current user
class UserProfileScreen extends StatefulWidget {
  final String? userId; // null = show current user profile

  const UserProfileScreen({super.key, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _profileUser;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  String? _errorMessage;

  // Separate lists for user's posts and events
  List<Post> _userPosts = [];
  List<Event> _userEvents = [];
  bool _isLoadingPosts = true;
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user from bloc
      final currentUserState = context.read<UserBloc>().state;
      if (currentUserState is! UserLoaded) {
        throw Exception('User not loaded');
      }

      final currentUser = currentUserState.user;

      // Determine if showing current user or other user
      _isCurrentUser = widget.userId == null || widget.userId == currentUser.id;

      if (_isCurrentUser) {
        // Show current user's profile
        setState(() {
          _profileUser = currentUser;
          _isLoading = false;
        });
      } else {
        // Fetch other user's profile
        final getUserById = di.sl<GetUserById>();
        final result = await getUserById(GetUserByIdParams(userId: widget.userId!));

        result.fold(
          (failure) {
            setState(() {
              _errorMessage = 'Gagal memuat profil: ${failure.message}';
              _isLoading = false;
            });
          },
          (user) {
            setState(() {
              _profileUser = user;
              _isLoading = false;
            });
          },
        );
      }

      // Load user's posts and events
      if (_profileUser != null) {
        // Log user data to verify API response
        print('[UserProfileScreen] ===== USER DATA FROM API =====');
        print('[UserProfileScreen] User ID: ${_profileUser!.id}');
        print('[UserProfileScreen] Name: ${_profileUser!.name}');
        print('[UserProfileScreen] Email: ${_profileUser!.email}');
        print('[UserProfileScreen] Bio: ${_profileUser!.bio ?? "(null/empty)"}');
        print('[UserProfileScreen] Avatar: ${_profileUser!.avatar ?? "(null)"}');
        print('[UserProfileScreen] Interests: ${_profileUser!.interests}');
        print('[UserProfileScreen] ================================');

        _loadUserPosts();
        _loadUserEvents();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPosts() async {
    if (_profileUser == null) return;

    setState(() => _isLoadingPosts = true);

    try {
      final postRepo = di.sl<PostRepository>();
      // Use widget.userId if available, otherwise use user's id
      final userIdentifier = widget.userId ?? _profileUser!.id;
      final result = await postRepo.getUserPosts(userIdentifier, limit: 20, offset: 0);

      result.fold(
        (failure) {
          setState(() {
            _userPosts = [];
            _isLoadingPosts = false;
          });
        },
        (paginatedResponse) {
          setState(() {
            _userPosts = paginatedResponse.data;
            _isLoadingPosts = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _userPosts = [];
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadUserEvents() async {
    if (_profileUser == null) return;

    setState(() => _isLoadingEvents = true);

    try {
      // Use widget.userId if available, otherwise use user's id
      final userId = widget.userId ?? _profileUser!.id;

      final eventDataSource = di.sl<EventRemoteDataSource>();
      final eventModels = await eventDataSource.getUserEventsByUsername(userId, limit: 20, offset: 0);

      // Convert models to entities
      final events = eventModels.map((model) => (model as dynamic).toEntity() as Event).toList();

      setState(() {
        _userEvents = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      print('[UserProfileScreen] Error loading events: $e');
      setState(() {
        _userEvents = [];
        _isLoadingEvents = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF84994F),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84994F),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profileUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: Text('User not found')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildProfileHeader()),
              SliverToBoxAdapter(child: _buildStatsRow()),
              SliverToBoxAdapter(child: _buildBioSection()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverPersistentHeader(
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF1A1A1A),
                    unselectedLabelColor: Colors.grey[400],
                    indicatorColor: const Color(0xFF84994F),
                    indicatorWeight: 2.5,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Postingan'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Event'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsList(),
              _buildEventsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final username = '@${_profileUser!.email?.split('@')[0] ?? 'user'}';

    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        username,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final username = '@${_profileUser!.email?.split('@')[0] ?? 'user'}';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF84994F),
                  const Color(0xFF84994F).withOpacity(0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFAF8F5),
                image: _profileUser!.avatar != null
                    ? DecorationImage(
                        image: NetworkImage(_profileUser!.avatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileUser!.avatar == null
                  ? Center(
                      child: Text(
                        _profileUser!.name.isNotEmpty
                            ? _profileUser!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF84994F),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          // Name and Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileUser!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    // TODO: Get actual stats from API
    final stats = [
      {'label': 'Pengikut', 'value': '${_profileUser?.stats.followersCount ?? 0}', 'index': -1},
      {'label': 'Event', 'value': '${_userEvents.length}', 'index': 1},
      {'label': 'Postingan', 'value': '${_userPosts.length}', 'index': 0},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) {
          final index = stat['index']! as int;
          return InkWell(
            onTap: () {
              if (index >= 0) {
                // Switch to the tab (0 = Posts, 1 = Events)
                _tabController.animateTo(index);
              } else {
                // Navigate to followers screen (index -1 = Pengikut)
                // TODO: Implement followers screen navigation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur followers coming soon!')),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(
                    stat['value']! as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat['label']! as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBioSection() {
    if (_profileUser!.bio == null || _profileUser!.bio!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _profileUser!.bio!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          // Hidden: Interests/Category section removed per user request
          // if (_profileUser!.interests.isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   Wrap(
          //     spacing: 8,
          //     runSpacing: 8,
          //     children: _profileUser!.interests.map((interest) {
          //       return Container(
          //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //         decoration: BoxDecoration(
          //           color: const Color(0xFFFAF8F5),
          //           borderRadius: BorderRadius.circular(20),
          //           border: Border.all(
          //             color: const Color(0xFF84994F).withOpacity(0.3),
          //             width: 1,
          //           ),
          //         ),
          //         child: Text(
          //           interest,
          //           style: const TextStyle(
          //             fontSize: 12,
          //             color: Color(0xFF84994F),
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       );
          //     }).toList(),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: _isCurrentUser
            ? [
                // Edit Profile button for current user
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(user: _profileUser),
                        ),
                      );
                      // Reload profile after edit
                      _loadProfileData();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Share Profile button
                OutlinedButton.icon(
                  onPressed: _shareProfile,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Bagikan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ]
            : [
                // Follow button for other users
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement follow/unfollow
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur follow akan segera hadir!'),
                          backgroundColor: Color(0xFF84994F),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Ikuti'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84994F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Message button
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement messaging
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur pesan akan segera hadir!'),
                        backgroundColor: Color(0xFF84994F),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Pesan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF84994F)),
      );
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isCurrentUser
                  ? 'Belum ada postingan nih'
                  : 'User ini belum punya postingan',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserPosts,
      color: const Color(0xFF84994F),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          return ModernPostCard(post: _userPosts[index]);
        },
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoadingEvents) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF84994F)),
      );
    }

    if (_userEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isCurrentUser
                  ? 'Belum ada event nih'
                  : 'User ini belum punya event',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserEvents,
      color: const Color(0xFF84994F),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _userEvents.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_userEvents[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF84994F).withOpacity(0.2),
            width: 1,
          ),
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
            // Event image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: const Color(0xFFFAF8F5),
                  image: event.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(event.imageUrls.first),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: event.imageUrls.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.event_rounded,
                          size: 40,
                          color: const Color(0xFF84994F).withOpacity(0.3),
                        ),
                      )
                    : null,
              ),
            ),
            // Event details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${event.currentAttendees} orang',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.isFree
                                ? const Color(0xFF84994F).withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.isFree ? 'GRATIS' : 'Rp ${event.price?.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: event.isFree
                                  ? const Color(0xFF84994F)
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    final username = '@${_profileUser!.email?.split('@')[0] ?? 'user'}';
    final profileUrl = 'https://anigmaa.app/profile/$username';

    Clipboard.setData(ClipboardData(text: profileUrl));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Link profil disalin!\n$profileUrl'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF84994F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Color(0xFF1A1A1A)),
              title: const Text('Bagikan Profil'),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareProfile();
              },
            ),
            if (!_isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.red),
                title: const Text('Laporkan', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur laporan akan segera hadir'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined, color: Colors.red),
                title: const Text('Blokir', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur blokir akan segera hadir'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Sticky TabBar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
