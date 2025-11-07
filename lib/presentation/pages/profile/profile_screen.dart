import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../injection_container.dart' as di;
import '../../bloc/user/user_bloc.dart';
import '../../bloc/user/user_state.dart';
import '../../bloc/user/user_event.dart';
import 'edit_profile_screen.dart';
import '../settings/settings_screen.dart';
import '../tickets/my_tickets_screen.dart';
import '../transactions/transaction_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UserLoaded) {
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    _buildAppBar(context, state),
                    SliverToBoxAdapter(child: _buildProfileHeader(context, state)),
                    SliverToBoxAdapter(child: _buildStatsRow(state)),
                    SliverToBoxAdapter(child: _buildActionButtons(context)),
                    SliverToBoxAdapter(child: _buildBioSection(state)),
                    SliverPersistentHeader(
                      delegate: _StickyTabBarDelegate(
                        TabBar(
                          labelColor: const Color(0xFF1A1A1A),
                          unselectedLabelColor: Colors.grey[400],
                          indicatorColor: const Color(0xFF1A1A1A),
                          indicatorWeight: 1.5,
                          tabs: const [
                            Tab(icon: Icon(Icons.grid_on_rounded)),
                            Tab(icon: Icon(Icons.event_rounded)),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    _buildPostsGrid(),
                    _buildEventsGrid(),
                  ],
                ),
              );
            }

            return _buildErrorState(context);
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserLoaded state) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      title: Row(
        children: [
          Text(
            state.user.name,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_box_outlined, color: Color(0xFF1A1A1A)),
          onPressed: () {
            // TODO: Create post/event
          },
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF1A1A1A)),
          onPressed: () {
            _showMenuBottomSheet(context);
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserLoaded state) {
    final user = state.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF84994F),
                width: 2,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFAF8F5),
                image: user.avatar != null
                    ? DecorationImage(
                        image: NetworkImage(user.avatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.avatar == null
                  ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Spacer to push content
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('${state.eventsHosted}', 'Postingan'),
          _buildStatColumn('${state.connections}', 'Pengikut'),
          _buildStatColumn('${state.eventsAttended}', 'Diikutin'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              child: const Text(
                'Edit Profil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Share profile
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              child: const Text(
                'Share Profil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              // TODO: Suggested people
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.grey[300]!, width: 1),
              minimumSize: const Size(0, 0),
            ),
            child: const Icon(Icons.person_add_outlined, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(UserLoaded state) {
    final user = state.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          if (user.bio != null) ...[
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
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.interests.take(3).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPostsGrid() {
    // TODO: Replace with actual posts data
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(
              Icons.photo_library_outlined,
              color: Colors.grey[500],
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsGrid() {
    // TODO: Replace with actual events data
    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(
              Icons.event_outlined,
              color: Colors.grey[500],
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Waduh... profil gagal dimuat nih',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<UserBloc>().add(LoadUserProfile());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Coba Lagi'),
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
            _buildMenuSheetItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Pengaturan',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              context: context,
              icon: Icons.confirmation_number_outlined,
              title: 'Tiket Gue',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyTicketsScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Transaksi',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
            ),
            _buildMenuSheetItem(
              context: context,
              icon: Icons.bookmark_outline,
              title: 'Tersimpan',
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur ini coming soon yaa!')),
                );
              },
            ),
            _buildMenuSheetItem(
              context: context,
              icon: Icons.qr_code_scanner,
              title: 'QR Code',
              onTap: () {
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur QR Code lagi on progress nih!')),
                );
              },
            ),
            const Divider(height: 1),
            _buildMenuSheetItem(
              context: context,
              icon: Icons.logout,
              title: 'Keluar',
              isDestructive: true,
              onTap: () {
                Navigator.pop(sheetContext);
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSheetItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF1A1A1A),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: isDestructive ? Colors.red : const Color(0xFF1A1A1A),
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text('Lo yakin mau keluar nih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Logout from app (clear tokens and user data)
      final authService = di.sl<AuthService>();
      await authService.logout();

      // Sign out from Google
      final googleAuthService = di.sl<GoogleAuthService>();
      await googleAuthService.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
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
