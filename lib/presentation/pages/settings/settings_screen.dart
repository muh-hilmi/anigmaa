import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../injection_container.dart' as di;
import 'privacy_settings_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'Indonesia 🇮🇩';

  final List<String> _languages = [
    'English',
    'Indonesia 🇮🇩',
    'Español',
    'Français',
    'Deutsch',
    '中文',
    '日本語',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengaturan ⚙️',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              title: 'Preferensi Gue',
              children: [
                // TODO: Dark Mode feature hidden temporarily
                // _buildSwitchTile(
                //   icon: Icons.dark_mode,
                //   title: 'Dark Mode',
                //   subtitle: 'Ganti ke tema gelap biar adem di mata',
                //   value: _darkMode,
                //   onChanged: (value) {
                //     setState(() {
                //       _darkMode = value;
                //     });
                //     _showMessage('Dark mode ${value ? 'udah nyala nih! ✨' : 'dimatiin'}');
                //   },
                // ),
                // TODO: Language feature hidden temporarily
                // _buildLanguageTile(),
                _buildSwitchTile(
                  icon: Icons.location_on,
                  title: 'Layanan Lokasi',
                  subtitle: 'Biar gue tau event seru di sekitar lo',
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Notifikasi 🔔',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications,
                  title: 'Push Notifications',
                  subtitle: 'Dapetin notif langsung di HP lo',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
                // TODO: Email Notifications feature hidden temporarily
                // _buildSwitchTile(
                //   icon: Icons.email,
                //   title: 'Email Notifications',
                //   subtitle: 'Terima notif lewat email',
                //   value: _emailNotifications,
                //   onChanged: (value) {
                //     setState(() {
                //       _emailNotifications = value;
                //     });
                //   },
                // ),
                _buildNavigationTile(
                  icon: Icons.tune,
                  title: 'Atur Notifikasi',
                  subtitle: 'Sesuain notif sesuai keinginan lo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Privasi & Keamanan 🔒',
              children: [
                _buildNavigationTile(
                  icon: Icons.privacy_tip,
                  title: 'Pengaturan Privasi',
                  subtitle: 'Atur siapa aja yang bisa liat info lo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacySettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildNavigationTile(
                  icon: Icons.security,
                  title: 'Keamanan Akun',
                  subtitle: 'Password & autentikasi dua faktor',
                  onTap: _navigateToSecurity,
                ),
                _buildNavigationTile(
                  icon: Icons.block,
                  title: 'User yang Diblokir',
                  subtitle: 'Kelola user yang udah lo blokir',
                  onTap: _navigateToBlockedUsers,
                ),
              ],
            ),
            // TODO: Data & Storage section hidden temporarily
            // _buildSection(
            //   title: 'Data & Storage 💾',
            //   children: [
            //     _buildNavigationTile(
            //       icon: Icons.download,
            //       title: 'Download Data Lo',
            //       subtitle: 'Ekspor semua data akun lo',
            //       onTap: _downloadData,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.storage,
            //       title: 'Storage & Data',
            //       subtitle: 'Kelola penyimpanan & penggunaan data',
            //       onTap: _navigateToStorage,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.clear,
            //       title: 'Bersihin Cache',
            //       subtitle: 'Kosongin space dengan hapus cache',
            //       onTap: _clearCache,
            //     ),
            //   ],
            // ),
            // TODO: Bantuan section hidden temporarily
            // _buildSection(
            //   title: 'Bantuan 💬',
            //   children: [
            //     _buildNavigationTile(
            //       icon: Icons.help,
            //       title: 'Pusat Bantuan',
            //       subtitle: 'Butuh bantuan? Yuk kesini!',
            //       onTap: _navigateToHelp,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.feedback,
            //       title: 'Kirim Feedback',
            //       subtitle: 'Bantu gue tingkatin app ini',
            //       onTap: _sendFeedback,
            //     ),
            //     _buildNavigationTile(
            //       icon: Icons.bug_report,
            //       title: 'Lapor Bug',
            //       subtitle: 'Ada masalah teknis? Kabarin gue!',
            //       onTap: _reportBug,
            //     ),
            //   ],
            // ),
            _buildSection(
              title: 'Tentang App 📱',
              children: [
                _buildNavigationTile(
                  icon: Icons.info,
                  title: 'Tentang flyerr',
                  subtitle: 'Versi 1.0.0',
                  onTap: _showAbout,
                ),
                // TODO: Syarat & Ketentuan hidden temporarily
                // _buildNavigationTile(
                //   icon: Icons.description,
                //   title: 'Syarat & Ketentuan',
                //   subtitle: 'Baca ketentuan penggunaan app',
                //   onTap: _showTerms,
                // ),
                // TODO: Kebijakan Privasi hidden temporarily
                // _buildNavigationTile(
                //   icon: Icons.policy,
                //   title: 'Kebijakan Privasi',
                //   subtitle: 'Baca kebijakan privasi gue',
                //   onTap: _showPrivacyPolicy,
                // ),
              ],
            ),
            _buildSection(
              title: 'Akun 👤',
              children: [
                _buildNavigationTile(
                  icon: Icons.logout,
                  title: 'Keluar',
                  subtitle: 'Logout dari akun lo',
                  onTap: _signOut,
                  isDestructive: true,
                ),
                _buildNavigationTile(
                  icon: Icons.delete_forever,
                  title: 'Hapus Akun',
                  subtitle: 'Hapus akun lo secara permanen',
                  onTap: _deleteAccount,
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.black,
      ),
    );
  }

  Widget _buildNavigationTile({
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
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      leading: const Icon(Icons.language, color: Colors.black87),
      title: const Text(
        'Bahasa',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        _selectedLanguage,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: _showLanguageDialog,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Bahasa'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  _showMessage('Bahasa diganti ke $value ✓');
                },
                fillColor: WidgetStateProperty.all(Colors.black),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _navigateToSecurity() {
    _showMessage('Keamanan Akun segera hadir! 🔜');
  }

  void _navigateToBlockedUsers() {
    _showMessage('Kelola user yang diblokir segera hadir! 🔜');
  }

  void _downloadData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Data Lo'),
        content: const Text(
          'Gue bakal siapin data lo dan kirim link download lewat email. Mungkin perlu beberapa menit ya!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Request ekspor data udah dikirim! ✓');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void _navigateToStorage() {
    _showMessage('Pengaturan storage segera hadir! 🔜');
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bersihin Cache'),
        content: const Text(
          'Ini bakal hapus semua cache termasuk gambar & file sementara. Lo yakin nih?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Cache udah dibersihkan! ✨');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bersihin'),
          ),
        ],
      ),
    );
  }

  void _navigateToHelp() {
    _showMessage('Pusat Bantuan segera hadir! 🔜');
  }

  void _sendFeedback() {
    _showMessage('Form feedback segera hadir! 🔜');
  }

  void _reportBug() {
    _showMessage('Form lapor bug segera hadir! 🔜');
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang flyerr'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 1.0.0+1'),
            SizedBox(height: 16),
            Text(
              'flyerr adalah app lo buat nemuin & bikin event keren di komunitas lo! 🎉',
            ),
            SizedBox(height: 16),
            Text('© 2024 flyerr. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
  }

  void _showTerms() {
    _showMessage('Syarat & Ketentuan segera hadir! 🔜');
  }

  void _showPrivacyPolicy() {
    _showMessage('Kebijakan Privasi segera hadir! 🔜');
  }

  void _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun'),
        content: const Text('Lo yakin mau logout? 🤔'),
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

    if (confirm == true && mounted) {
      // Logout from app (clear tokens and user data)
      final authService = di.sl<AuthService>();
      await authService.logout();

      // Sign out from Google
      final googleAuthService = di.sl<GoogleAuthService>();
      await googleAuthService.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Waduh, ini gabisa dibatalin ya! Semua data lo bakal kehapus permanen. 😱',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Terakhir'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ketik "HAPUS" buat konfirmasi penghapusan akun:'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ketik HAPUS disini',
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
              _showMessage('Request hapus akun udah dikirim 💔');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Akun'),
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