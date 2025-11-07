import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _eventsVisible = true;
  bool _allowFollowers = true;
  bool _showEmail = false;
  bool _showLocation = true;
  bool _showOnlineStatus = true;

  String _profileVisibility = 'Publik';
  String _eventVisibility = 'Temen Aja';
  String _whoCanMessage = 'Semua Orang';
  String _whoCanInvite = 'Temen Aja';

  final List<String> _visibilityOptions = ['Publik', 'Temen Aja', 'Privat'];
  final List<String> _messageOptions = ['Semua Orang', 'Temen Aja', 'Gaada'];
  final List<String> _inviteOptions = ['Semua Orang', 'Temen Aja', 'Gaada'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengaturan Privasi 🔒',
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
              title: 'Visibilitas Profil 👀',
              subtitle: 'Atur siapa aja yang bisa liat info profil lo',
              children: [
                _buildDropdownTile(
                  title: 'Visibilitas Profil',
                  subtitle: 'Siapa yang bisa liat profil lo',
                  value: _profileVisibility,
                  options: _visibilityOptions,
                  onChanged: (value) {
                    setState(() {
                      _profileVisibility = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Tampilin Email',
                  subtitle: 'Munculin email lo di profil',
                  value: _showEmail,
                  onChanged: (value) {
                    setState(() {
                      _showEmail = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Tampilin Lokasi',
                  subtitle: 'Munculin lokasi lo di profil',
                  value: _showLocation,
                  onChanged: (value) {
                    setState(() {
                      _showLocation = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Tampilin Status Online',
                  subtitle: 'Biar orang tau kapan lo lagi online',
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    setState(() {
                      _showOnlineStatus = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Privasi Event 🎉',
              subtitle: 'Atur siapa yang bisa liat event & aktivitas lo',
              children: [
                _buildDropdownTile(
                  title: 'Visibilitas Event',
                  subtitle: 'Siapa yang bisa liat event yang lo ikutin',
                  value: _eventVisibility,
                  options: _visibilityOptions,
                  onChanged: (value) {
                    setState(() {
                      _eventVisibility = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Tampilin Event di Profil',
                  subtitle: 'Munculin event lo di profil',
                  value: _eventsVisible,
                  onChanged: (value) {
                    setState(() {
                      _eventsVisible = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Interaksi Sosial 💬',
              subtitle: 'Atur gimana orang bisa interaksi sama lo',
              children: [
                _buildSwitchTile(
                  title: 'Izinkan Followers',
                  subtitle: 'Biar orang bisa follow profil lo',
                  value: _allowFollowers,
                  onChanged: (value) {
                    setState(() {
                      _allowFollowers = value;
                    });
                  },
                ),
                _buildDropdownTile(
                  title: 'Siapa yang Bisa DM Lo',
                  subtitle: 'Atur siapa yang bisa kirim pesan ke lo',
                  value: _whoCanMessage,
                  options: _messageOptions,
                  onChanged: (value) {
                    setState(() {
                      _whoCanMessage = value;
                    });
                  },
                ),
                _buildDropdownTile(
                  title: 'Siapa yang Bisa Ngundang Lo',
                  subtitle: 'Atur siapa yang bisa ngundang lo ke event',
                  value: _whoCanInvite,
                  options: _inviteOptions,
                  onChanged: (value) {
                    setState(() {
                      _whoCanInvite = value;
                    });
                  },
                ),
              ],
            ),
            _buildSection(
              title: 'Privasi Data 📊',
              subtitle: 'Atur gimana data lo dipake',
              children: [
                _buildNavigationTile(
                  title: 'Penggunaan Data',
                  subtitle: 'Liat gimana data lo dipake',
                  onTap: _showDataUsage,
                ),
                _buildNavigationTile(
                  title: 'Download Data Lo',
                  subtitle: 'Dapetin copy data lo',
                  onTap: _downloadData,
                ),
                _buildNavigationTile(
                  title: 'Hapus Data Akun',
                  subtitle: 'Hapus semua data lo dari server gue',
                  onTap: _deleteAccountData,
                  isDestructive: true,
                ),
              ],
            ),
            _buildSection(
              title: 'Data Aktivitas 📍',
              subtitle: 'Atur data aktivitas apa aja yang dikumpulin',
              children: [
                _buildNavigationTile(
                  title: 'Riwayat Lokasi',
                  subtitle: 'Kelola data lokasi lo',
                  onTap: _manageLocationHistory,
                ),
                _buildNavigationTile(
                  title: 'Riwayat Pencarian',
                  subtitle: 'Liat & hapus riwayat pencarian lo',
                  onTap: _manageSearchHistory,
                ),
                _buildNavigationTile(
                  title: 'Riwayat Event',
                  subtitle: 'Kelola data partisipasi event lo',
                  onTap: _manageEventHistory,
                ),
              ],
            ),
            _buildSection(
              title: 'User yang Diblokir 🚫',
              subtitle: 'Kelola user yang udah lo blokir',
              children: [
                _buildNavigationTile(
                  title: 'Daftar User yang Diblokir',
                  subtitle: 'Liat & kelola user yang lo blokir',
                  onTap: _viewBlockedUsers,
                ),
                _buildNavigationTile(
                  title: 'Pengaturan Auto-Block',
                  subtitle: 'Otomatis blokir user berdasarkan kriteria',
                  onTap: _manageAutoBlock,
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
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
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
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
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

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
        ],
      ),
      onTap: () => _showOptionsDialog(title, value, options, onChanged),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
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

  void _showOptionsDialog(
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: currentValue,
                onChanged: (value) {
                  onChanged(value!);
                  Navigator.pop(context);
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

  void _showDataUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Penggunaan Data'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gue pake data lo buat:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Kasih rekomendasi event yang cocok buat lo'),
              Text('• Tingkatin fitur app & pengalaman user'),
              Text('• Kirim notif yang relevan'),
              Text('• Nyambungin lo sama orang yang satu vibe'),
              SizedBox(height: 16),
              Text(
                'Yang GABAKAL gue lakuin:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Jual data pribadi lo ke pihak ketiga'),
              Text('• Share lokasi lo tanpa izin'),
              Text('• Akses data device lo tanpa persetujuan'),
            ],
          ),
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

  void _downloadData() {
    _showMessage('Request download data udah dikirim. Lo bakal dapet email sebentar lagi! 📧');
  }

  void _deleteAccountData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Akun'),
        content: const Text(
          'Ini bakal hapus SEMUA data lo termasuk profil, event, & koneksi secara permanen. Gabisa dibatalin ya! 😱',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showMessage('Request hapus akun udah dikirim 💔');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _manageLocationHistory() {
    _showMessage('Kelola riwayat lokasi segera hadir! 🔜');
  }

  void _manageSearchHistory() {
    _showMessage('Kelola riwayat pencarian segera hadir! 🔜');
  }

  void _manageEventHistory() {
    _showMessage('Kelola riwayat event segera hadir! 🔜');
  }

  void _viewBlockedUsers() {
    _showMessage('Daftar user yang diblokir segera hadir! 🔜');
  }

  void _manageAutoBlock() {
    _showMessage('Pengaturan auto-block segera hadir! 🔜');
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