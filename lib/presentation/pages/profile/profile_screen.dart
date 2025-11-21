import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../settings/settings_screen.dart';
import '../tickets/my_tickets_screen.dart';
import '../transactions/transaction_history_screen.dart';
import '../saved/saved_items_screen.dart';
import '../qr/qr_code_screen.dart';
import 'my_events_screen.dart';
import 'edit_profile_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/user/user_event.dart';

/// Modern profile screen with Instagram/TikTok/X style
/// - Reusable for viewing own profile and other users
/// - userId null = own profile, userId provided = other user's profile
class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String? _currentUserId;
  bool _isOwnProfile = false;
  bool _isFollowing = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final authService = di.sl<AuthService>();
    _currentUserId = authService.userId;

    final targetUserId = widget.userId ?? _currentUserId;

    if (targetUserId != null && mounted) {
      setState(() {
        _isOwnProfile = targetUserId == _currentUserId;
        _tabController?.dispose();
        _tabController =
            TabController(length: _isOwnProfile ? 3 : 2, vsync: this);
      });
      context.read<UserBloc>().add(LoadUserById(targetUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF84994F),
              ),
            );
          }

          if (state is UserError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat profil',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _initialize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84994F),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (state is UserLoaded) {
            final user = state.user;

            // Return loading if TabController is not initialized yet
            if (_tabController == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF84994F),
                ),
              );
            }

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: true,
                    pinned: false,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    leading: !_isOwnProfile
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          )
                        : null,
                    title: Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    actions: [
                      if (_isOwnProfile)
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.black),
                          onPressed: () => _showMenuBottomSheet(context),
                        )
                      else
                        IconButton(
                          icon:
                              const Icon(Icons.more_vert, color: Colors.black),
                          onPressed: () => _showUserMenuBottomSheet(context),
                        ),
                    ],
                  ),
                  // Profile Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar + Stats Row
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: (user.avatar != null &&
                                          user.avatar!.isNotEmpty)
                                      ? Image.network(
                                          user.avatar!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stack) =>
                                                  _buildDefaultAvatar(
                                                      user.name),
                                        )
                                      : _buildDefaultAvatar(user.name),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Stats
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatColumn(
                                      state.eventsHosted.toString(),
                                      'Posts',
                                    ),
                                    _buildStatColumn(
                                      _formatNumber(user.stats.followersCount),
                                      'Followers',
                                    ),
                                    _buildStatColumn(
                                      _formatNumber(user.stats.followingCount),
                                      'Following',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name + Verified
                          Row(
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              if (user.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color(0xFF84994F),
                                ),
                              ],
                            ],
                          ),
                          // Bio
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.bio!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.3,
                              ),
                            ),
                          ],
                          // Location
                          if (user.location != null &&
                              user.location!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  user.location!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Action Buttons
                          if (_isOwnProfile)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    label: 'Edit Profile',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const EditProfileScreen(),
                                        ),
                                      );
                                    },
                                    isPrimary: false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildActionButton(
                                    label: 'Share Profile',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const QRCodeScreen(),
                                        ),
                                      );
                                    },
                                    isPrimary: false,
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildActionButton(
                                    label: _isFollowing ? 'Following' : 'Follow',
                                    onTap: () {
                                      setState(() {
                                        _isFollowing = !_isFollowing;
                                      });
                                      if (_isFollowing) {
                                        context
                                            .read<UserBloc>()
                                            .add(FollowUserEvent(user.id));
                                      } else {
                                        context
                                            .read<UserBloc>()
                                            .add(UnfollowUserEvent(user.id));
                                      }
                                    },
                                    isPrimary: !_isFollowing,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildActionButton(
                                    label: 'Message',
                                    onTap: () {
                                      // TODO: Navigate to chat
                                    },
                                    isPrimary: false,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  height: 32,
                                  width: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      Icons.person_add_outlined,
                                      size: 18,
                                      color: Colors.grey[800],
                                    ),
                                    onPressed: () {
                                      // TODO: Suggest to friends
                                    },
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      TabBar(
                        controller: _tabController!,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.black,
                        indicatorWeight: 1,
                        tabs: [
                          const Tab(icon: Icon(Icons.grid_on, size: 24)),
                          const Tab(
                              icon: Icon(Icons.confirmation_number, size: 24)),
                          if (_isOwnProfile)
                            const Tab(icon: Icon(Icons.bookmark_border, size: 24)),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController!,
                children: [
                  _buildEventsGrid(state.eventsHosted),
                  _buildAttendedGrid(state.eventsAttended),
                  if (_isOwnProfile) _buildSavedGrid(),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      color: const Color(0xFF84994F),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF84994F) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: !isPrimary
              ? Border.all(color: Colors.grey[300]!)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsGrid(int eventsCount) {
    if (eventsCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isOwnProfile ? 'Belum ada event' : 'Belum ada event',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_isOwnProfile)
              Text(
                'Buat event pertamamu!',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
          ],
        ),
      );
    }

    // TODO: Replace with actual event grid from events
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: eventsCount,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(Icons.event, color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildAttendedGrid(int attendedCount) {
    if (attendedCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isOwnProfile ? 'Belum pernah attend event' : 'Belum pernah attend event',
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

    // TODO: Replace with actual attended events grid
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: attendedCount,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Icon(Icons.check_circle, color: Colors.grey[400]),
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada item tersimpan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simpan event & post favoritmu di sini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuSheetItem(
              icon: Icons.event,
              title: 'My Events',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyEventsScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.confirmation_number,
              title: 'Tiket Gue',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyTicketsScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.receipt_long,
              title: 'Transaksi',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.bookmark,
              title: 'Tersimpan',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedItemsScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.qr_code,
              title: 'QR Code Gue',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRCodeScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildMenuSheetItem(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showUserMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuSheetItem(
              icon: Icons.share,
              title: 'Share Profile',
              onTap: () {
                Navigator.pop(context);
                // TODO: Share profile
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.block,
              title: 'Block User',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                // TODO: Block user
              },
            ),
            _buildMenuSheetItem(
              icon: Icons.report,
              title: 'Report',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                // TODO: Report user
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[800],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin mau logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _handleLogout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final authService = di.sl<AuthService>();
      final googleAuthService = di.sl<GoogleAuthService>();

      await googleAuthService.signOut();
      await authService.logout();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
