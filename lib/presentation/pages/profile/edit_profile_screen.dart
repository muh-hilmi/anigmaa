import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../domain/entities/user.dart';

class EditProfileScreen extends StatefulWidget {
  final User? user;

  const EditProfileScreen({
    super.key,
    this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<String> _selectedInterests = [];
  String? _selectedAvatarUrl;
  File? _selectedImageFile;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableInterests = [
    {'name': 'Technology', 'icon': Icons.computer},
    {'name': 'Sports', 'icon': Icons.sports_soccer},
    {'name': 'Music', 'icon': Icons.music_note},
    {'name': 'Art', 'icon': Icons.palette},
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Travel', 'icon': Icons.flight},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Reading', 'icon': Icons.book},
    {'name': 'Gaming', 'icon': Icons.sports_esports},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Cooking', 'icon': Icons.restaurant_menu},
    {'name': 'Dancing', 'icon': Icons.music_video},
    {'name': 'Movies', 'icon': Icons.movie},
    {'name': 'Nature', 'icon': Icons.nature},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Volunteering', 'icon': Icons.volunteer_activism},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameController.text = widget.user!.name;
      _bioController.text = widget.user!.bio ?? '';
      _selectedInterests = List.from(widget.user!.interests);
      _selectedAvatarUrl = widget.user!.avatar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfilePhoto(),
                  const SizedBox(height: 24),
                  _buildPersonalInfo(),
                  const SizedBox(height: 16),
                  _buildSocialLinks(),
                  const SizedBox(height: 16),
                  _buildInterests(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF84994F),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF84994F),
                const Color(0xFF84994F).withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              // Profile image with beautiful border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF84994F),
                      const Color(0xFF84994F).withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!)
                        : (_selectedAvatarUrl != null
                            ? NetworkImage(_selectedAvatarUrl!)
                            : null) as ImageProvider?,
                    child: (_selectedImageFile == null && _selectedAvatarUrl == null)
                        ? Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.grey[400],
                          )
                        : null,
                  ),
                ),
              ),
              // Camera button
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF84994F), Color(0xFF6B7D3F)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Ganti Foto Profil',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPG, PNG atau GIF (Maks 5MB)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF84994F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Info Pribadi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            hint: 'Tulis nama lengkap lo',
            icon: Icons.badge_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama wajib diisi yaa!';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Ceritain tentang lo dong...',
            icon: Icons.info_outline,
            maxLines: 4,
            maxLength: 150,
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _locationController,
            label: 'Lokasi',
            hint: 'Kota, Negara',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.link,
                  color: Color(0xFF84994F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Link Sosmed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _websiteController,
            label: 'Website',
            hint: 'https://website-lo.com',
            icon: Icons.language,
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFF84994F), size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF84994F), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: maxLength != null ? null : '',
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildInterests() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  color: Color(0xFF84994F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Minat & Hobi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pilih minimal 3 biar kita bisa rekomendasiin event yang cocok buat lo',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest['name']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest['name']);
                    } else {
                      _selectedInterests.add(interest['name']);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF84994F), Color(0xFF6B7D3F)],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF84994F) : Colors.grey.shade300,
                      width: isSelected ? 0 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF84994F).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        interest['icon'],
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        interest['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF84994F),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedInterests.length} minat udah kepilih',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF84994F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF84994F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
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
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _buildPhotoOption(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil Foto',
                subtitle: 'Pake kamera buat foto sekarang',
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              _buildPhotoOption(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri',
                subtitle: 'Pilih dari foto lo',
                onTap: () {
                  Navigator.pop(context);
                  _chooseFromGallery();
                },
              ),
              if (_selectedAvatarUrl != null || _selectedImageFile != null)
                _buildPhotoOption(
                  icon: Icons.delete_rounded,
                  title: 'Hapus Foto',
                  subtitle: 'Pake avatar default',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedAvatarUrl = null;
                      _selectedImageFile = null;
                    });
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (color ?? const Color(0xFF84994F)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color ?? const Color(0xFF84994F),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color ?? Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImageFile = File(photo.path);
          _selectedAvatarUrl = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Foto berhasil diambil!'),
                ],
              ),
              backgroundColor: const Color(0xFF84994F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waduh error nih: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          _selectedAvatarUrl = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Foto berhasil dipilih!'),
                ],
              ),
              backgroundColor: const Color(0xFF84994F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Waduh error nih: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedInterests.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Pilih minimal satu minat dulu dong!'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Profil berhasil diupdate!'),
              ],
            ),
            backgroundColor: const Color(0xFF84994F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Return updated data
        Navigator.pop(context, {
          'name': _nameController.text,
          'bio': _bioController.text,
          'location': _locationController.text,
          'interests': _selectedInterests,
          'avatar': _selectedImageFile?.path ?? _selectedAvatarUrl,
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}
