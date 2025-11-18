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
import '../social/followers_screen.dart';
import '../saved/saved_items_screen.dart';
import '../qr/qr_code_screen.dart';

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
                    SliverToBoxAdapter(child: _buildBioSection(state)),
                    SliverPersistentHeader(
                      delegate: _StickyTabBarDelegate(
                        TabBar(
                          labelColor: const Color(0xFF1A1A1A),
                          unselectedLabelColor: Colors.grey[400],
                          indicatorColor: const Color(0xFF84994F),
                          indicatorWeight: 2.5,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showQuickAccessBottomSheet(context);
          },
          backgroundColor: const Color(0xFF84994F),
          child: const Icon(Icons.menu_rounded, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UserLoaded state) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      title: Text(
        state.user.name,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
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
          // Username and action buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${user.email!.split('@')[0]}', // Using email prefix as username
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        _showShareProfileDialog(context, user);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                        minimumSize: const Size(40, 40),
                      ),
                      child: const Icon(Icons.share, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            context: null, // Will be passed from builder
            value: '${state.connections}',
            label: 'Pengikut',
            userId: state.user.id,
          ),
          _buildStatColumn(
            context: null,
            value: '${state.eventsHosted}',
            label: 'Event',
            userId: state.user.id,
          ),
          _buildStatColumn(
            context: null,
            value: '${state.postsCount}',
            label: 'Postingan',
            userId: state.user.id,
          ),
          _buildStatColumn(
            context: null,
            value: '${state.totalInvitedAttendees}',
            label: 'Diajak',
            userId: state.user.id,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required BuildContext? context,
    required String value,
    required String label,
    required String userId,
  }) {
    return Builder(
      builder: (ctx) {
        final effectiveContext = context ?? ctx;
        return GestureDetector(
          onTap: () => _handleStatClick(effectiveContext, label, userId),
          child: Column(
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
          ),
        );
      },
    );
  }

  void _handleStatClick(BuildContext context, String label, String userId) {
    if (label == 'Pengikut') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FollowersScreen(
            userId: userId,
            title: 'Pengikut',
            isFollowers: true,
          ),
        ),
      );
    } else if (label == 'Event') {
      // Switch to Events tab
      DefaultTabController.of(context).animateTo(1);
    } else if (label == 'Postingan') {
      // Switch to Posts tab
      DefaultTabController.of(context).animateTo(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label: $value'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Removed old Edit Profil button - now integrated in header

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

  void _showQuickAccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.dashboard_outlined,
                      size: 20,
                      color: Color(0xFF84994F),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Akses Cepat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick access items
              _buildQuickAccessItem(
                context: context,
                icon: Icons.confirmation_number_outlined,
                label: 'Tiket Gue',
                color: const Color(0xFF84994F),
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
              _buildQuickAccessItem(
                context: context,
                icon: Icons.receipt_long_outlined,
                label: 'Transaksi',
                color: Colors.orange[700]!,
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
              _buildQuickAccessItem(
                context: context,
                icon: Icons.bookmark_outline,
                label: 'Tersimpan',
                color: Colors.blue[700]!,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedItemsScreen(),
                    ),
                  );
                },
              ),
              _buildQuickAccessItem(
                context: context,
                icon: Icons.qr_code_scanner,
                label: 'QR Code',
                color: Colors.purple[700]!,
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QRCodeScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildPostsGrid() {
    // TODO: Load posts from PostsBloc
    // TODO: Backend must implement GET /users/{id}/posts endpoint
    // context.read<PostsBloc>().add(LoadUserPosts(userId));

    final posts = <Map<String, dynamic>>[]; // Empty - ready for API integration

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada postingan nih',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post text content
          if (post['text'] != null && post['text'].isNotEmpty) ...[
            Text(
              post['text'],
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF1a1a1a),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],

          // Post image (if any)
          if (post['image'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Event attachment (always present)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF84994F).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Event icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84994F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: Color(0xFF84994F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['eventTitle'] ?? 'Event Title',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1a1a1a),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post['eventDate'] ?? 'Soon',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.people_outline,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post['attendees'] ?? 0} ikutan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),

          // Engagement stats
          const SizedBox(height: 12),
          Row(
            children: [
              _buildEngagementStat(Icons.star_rounded, post['likes'] ?? 0),
              const SizedBox(width: 16),
              _buildEngagementStat(Icons.chat_bubble_outline_rounded, post['comments'] ?? 0),
              const SizedBox(width: 16),
              _buildEngagementStat(Icons.share_outlined, post['shares'] ?? 0),
              const Spacer(),
              Text(
                post['time'] ?? '1h',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // REMOVED: _generateMockPosts() - no longer needed, ready for API integration

  Widget _buildEventsGrid() {
    // TODO: Load events from EventsBloc
    // TODO: Backend must implement GET /users/{id}/events endpoint
    // context.read<EventsBloc>().add(LoadUserEvents(userId));

    final events = <Map<String, dynamic>>[]; // Empty - ready for API integration

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada event nih',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF84994F).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          if (event['image'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                event['image'],
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF8F5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Icon(
                      Icons.event_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),

          // Event details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84994F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event['category'] ?? 'Event',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF84994F),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Event title
                Text(
                  event['title'] ?? 'Event Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a1a1a),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Event date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event['date'] ?? 'Soon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Event location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event['location'] ?? 'Location',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Attendees
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${event['attendees'] ?? 0} orang ikutan',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    // Price or Free badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event['isFree'] == true
                            ? const Color(0xFF84994F).withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event['isFree'] == true ? 'GRATIS' : 'Rp ${event['price']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: event['isFree'] == true
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
        ],
      ),
    );
  }

  // REMOVED: _generateMockEvents() - no longer needed, ready for API integration

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

  void _showShareProfileDialog(BuildContext context, user) {
    final username = '@${user.email.split('@')[0]}';
    final profileUrl = 'https://anigmaa.app/profile/$username';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bagikan Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF84994F),
                          width: 2,
                        ),
                        image: user.avatar != null
                            ? DecorationImage(
                                image: NetworkImage(user.avatar!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: user.avatar == null
                          ? Icon(Icons.person, size: 24, color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF84994F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: Color(0xFF84994F),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Salin Link Profil',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link profil disalin: $profileUrl'),
                      backgroundColor: const Color(0xFF84994F),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Bagikan ke...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur berbagi sedang dalam pengembangan'),
                      backgroundColor: Color(0xFF84994F),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
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
