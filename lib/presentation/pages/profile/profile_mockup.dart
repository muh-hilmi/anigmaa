import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'my_events_screen.dart';
import '../social/followers_screen.dart';
import '../social/discover_people_screen.dart';
import '../settings/settings_screen.dart';
import '../../../core/services/auth_service.dart';
import '../../../injection_container.dart' as di;

class ProfileMockupScreen extends StatefulWidget {
  const ProfileMockupScreen({super.key});

  @override
  State<ProfileMockupScreen> createState() => _ProfileMockupScreenState();
}

class _ProfileMockupScreenState extends State<ProfileMockupScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _emailUpdatesEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '👤 Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildStatsSection(),
          const SizedBox(height: 16),
          _buildQuickActions(),
            const SizedBox(height: 20),
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => _changeProfilePicture(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'John Doe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'john.doe@email.com',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Event enthusiast and community builder',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _editProfile(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: _navigateToMyEvents,
            child: _buildStatItem('Events Joined', '24'),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          GestureDetector(
            onTap: _navigateToMyEvents,
            child: _buildStatItem('Events Created', '8'),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          GestureDetector(
            onTap: () => _navigateToFollowers(false),
            child: _buildStatItem('Following', '156'),
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          GestureDetector(
            onTap: () => _navigateToFollowers(true),
            child: _buildStatItem('Followers', '89'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
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
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.calendar_today,
            title: 'My Events',
            subtitle: 'View your upcoming and past events',
            onTap: () => _navigateToMyEvents(),
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Favorites',
            subtitle: 'Events you\'ve saved for later',
            onTap: () => _navigateToFavorites(),
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Event History',
            subtitle: 'View your event participation history',
            onTap: () => _navigateToHistory(),
          ),
          _buildMenuItem(
            icon: Icons.people,
            title: 'Friends',
            subtitle: 'Manage your connections',
            onTap: () => _navigateToFriends(),
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () => _navigateToNotifications(),
          ),
          _buildMenuItem(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Account security settings',
            onTap: () => _navigateToPrivacy(),
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () => _navigateToHelp(),
          ),
          _buildMenuItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App information and terms',
            onTap: () => _navigateToAbout(),
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _signOut(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Camera functionality not implemented yet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Gallery functionality not implemented yet');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                _showMessage('Photo removed');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _navigateToMyEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyEventsScreen(),
      ),
    );
  }

  void _navigateToFavorites() {
    _showMessage('Favorites screen coming soon!');
  }

  void _navigateToHistory() {
    _showMessage('Event History screen coming soon!');
  }

  Widget _buildQuickActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.people_outline,
              label: 'Discover People',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiscoverPeopleScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.group_add,
              label: 'Find Friends',
              onTap: _navigateToFriends,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFollowers(bool isFollowers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowersScreen(
          userId: 'current_user',
          title: isFollowers ? 'Followers' : 'Following',
          isFollowers: isFollowers,
        ),
      ),
    );
  }

  void _navigateToFriends() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiscoverPeopleScreen(),
      ),
    );
  }

  void _navigateToNotifications() {
    _showMessage('Notifications settings coming soon!');
  }

  void _navigateToPrivacy() {
    _showMessage('Privacy settings coming soon!');
  }

  void _navigateToHelp() {
    _showMessage('Help & Support coming soon!');
  }

  void _navigateToAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Anigmaa'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Anigmaa is your go-to app for discovering and creating amazing events in your community.'),
            SizedBox(height: 16),
            Text('© 2024 Anigmaa. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Logout user
      final authService = di.sl<AuthService>();
      await authService.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Receive push notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Enable dark theme'),
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
                Navigator.pop(context);
                _showMessage('Dark mode coming soon!');
              },
            ),
            SwitchListTile(
              title: const Text('Email Updates'),
              subtitle: const Text('Receive email notifications'),
              value: _emailUpdatesEnabled,
              onChanged: (value) {
                setState(() {
                  _emailUpdatesEnabled = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}