import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../data/models/event_model.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_state.dart';
import '../../widgets/location_picker.dart';

// Note: Buat redesign yang lebih modern dari create event screen yang ada
// Fokus pada: better visual hierarchy, smooth animations, modern UI elements

class CreateEventScreenRedesigned extends StatefulWidget {
  const CreateEventScreenRedesigned({super.key});

  @override
  State<CreateEventScreenRedesigned> createState() => _CreateEventScreenRedesignedState();
}

class _CreateEventScreenRedesignedState extends State<CreateEventScreenRedesigned>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _priceController = TextEditingController();
  final _requirementsController = TextEditingController();

  // Form data
  EventCategory _selectedCategory = EventCategory.meetup;
  EventPrivacy _selectedPrivacy = EventPrivacy.public;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isFree = true;
  double _price = 0;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  LocationData? _selectedLocationData;

  // Validation states
  String? _titleError;
  String? _descriptionError;
  String? _maxAttendeesError;
  String? _priceError;
  String? _requirementsError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFAF8F5),
                  _currentStep == 0
                      ? const Color(0xFF84994F).withValues(alpha: 0.08)
                      : const Color(0xFF6366F1).withValues(alpha: 0.08),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildModernProgressIndicator(),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildInfoStep(),
                          _buildSettingsStep(),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildModernBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.close, color: Colors.black, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Bikin Acara 🎉',
        style: TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
      ),
      actions: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Balik'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildModernProgressIndicator() {
    final steps = ['Info Dasar', 'Pengaturan'];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress dots
          Row(
            children: List.generate(2, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? const Color(0xFF84994F)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Step title
          Text(
            steps[_currentStep],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF84994F),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getStepSubtitle(),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Ceritain detail acaranya dulu yuk!';
      case 1:
        return 'Atur harga, kapasitas, dan final touch';
      default:
        return '';
    }
  }

  // Step 1: Info Step
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field with icon
          _buildModernTextField(
            controller: _titleController,
            label: 'Nama Acara',
            hint: 'Cth: Ngopi Bareng Startup Founders ☕',
            icon: Icons.celebration_outlined,
            required: true,
            errorText: _titleError,
            onChanged: _validateTitle,
          ),
          const SizedBox(height: 20),

          // Description
          _buildModernTextField(
            controller: _descriptionController,
            label: 'Deskripsi',
            hint: 'Ceritain detail acara, apa yang bakal dilakukan, dll.',
            icon: Icons.notes_outlined,
            maxLines: 4,
            required: true,
            errorText: _descriptionError,
            onChanged: _validateDescription,
          ),
          const SizedBox(height: 20),

          // Date & Time
          _buildSectionHeader('Kapan nih?', Icons.calendar_today_outlined),
          const SizedBox(height: 12),
          _buildModernDateTimePicker(),
          const SizedBox(height: 24),

          // Location
          _buildSectionHeader('Di mana lokasinya?', Icons.location_on_outlined),
          const SizedBox(height: 12),
          LocationPicker(
            onLocationSelected: (locationData) {
              setState(() {
                _selectedLocationData = locationData;
              });
              AppLogger().info('Location selected: ${locationData.name}');
            },
            initialLocation: _selectedLocationData,
          ),
        ],
      ),
    );
  }

  // Step 2: Settings Step
  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Upload
          _buildModernImageUpload(),
          const SizedBox(height: 24),

          // Privacy Selector
          _buildSectionHeader('Siapa aja yang bisa join?', Icons.public_outlined),
          const SizedBox(height: 12),
          _buildModernPrivacySelector(),
          const SizedBox(height: 24),

          // Capacity & Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildModernTextField(
                  controller: _maxAttendeesController,
                  label: 'Kapasitas (Maks 100)',
                  hint: '50',
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                  required: true,
                  errorText: _maxAttendeesError,
                  onChanged: _validateMaxAttendees,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Harga', Icons.payments_outlined, small: true),
                    const SizedBox(height: 8),
                    _buildModernPricingToggle(),
                  ],
                ),
              ),
            ],
          ),

          if (!_isFree) ...[
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _priceController,
              label: 'Nominal Harga',
              hint: '50000',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              errorText: _priceError,
              onChanged: (value) {
                _validatePrice(value);
                setState(() {
                  _price = double.tryParse(value) ?? 0;
                });
              },
            ),
          ],

          const SizedBox(height: 24),

          // Requirements (Optional)
          _buildModernTextField(
            controller: _requirementsController,
            label: 'Persyaratan (Opsional)',
            hint: 'Contoh: Bawa laptop, notebook, dll.',
            icon: Icons.checklist_outlined,
            maxLines: 3,
            errorText: _requirementsError,
            onChanged: _validateRequirements,
          ),
          const SizedBox(height: 24),

          // Preview Card
          _buildModernPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool small = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF84994F).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF84994F),
            size: small ? 18 : 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: small ? 15 : 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text.rich(
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: required
                    ? [
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: Icon(icon, size: 22),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.grey[200]!,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : const Color(0xFF84994F),
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84994F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF84994F),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84994F).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Color(0xFF84994F),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime.format(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cover Image (Optional)', Icons.image_outlined),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: _selectedImage == null
                  ? const Color(0xFF84994F).withValues(alpha: 0.05)
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF84994F).withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF84994F).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF84994F),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap untuk upload foto',
                        style: TextStyle(
                          color: Color(0xFF84994F),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ukuran max: 5MB',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernPrivacySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPrivacyOption(
            title: 'Publik',
            subtitle: 'Semua bisa join',
            icon: Icons.public_outlined,
            isSelected: _selectedPrivacy == EventPrivacy.public,
            onTap: () => setState(() => _selectedPrivacy = EventPrivacy.public),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPrivacyOption(
            title: 'Privat',
            subtitle: 'Harus approve',
            icon: Icons.lock_outline,
            isSelected: _selectedPrivacy == EventPrivacy.private,
            onTap: () => setState(() => _selectedPrivacy = EventPrivacy.private),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF84994F).withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF84994F)
                : Colors.grey[200]!,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF84994F).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF84994F) : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF84994F) : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF84994F).withValues(alpha: 0.8)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPricingToggle() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildPriceOption('Gratis', _isFree, () {
              setState(() {
                _isFree = true;
                _price = 0;
              });
            }),
          ),
          Expanded(
            child: _buildPriceOption('Berbayar', !_isFree, () {
              setState(() => _isFree = false);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF84994F) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF84994F).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF84994F).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF84994F).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: const Color(0xFF84994F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF84994F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _titleController.text.isNotEmpty ? _titleController.text : 'Nama Acara',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(Icons.calendar_today, _formatDateTime()),
          const SizedBox(height: 8),
          _buildPreviewRow(
            Icons.location_on_outlined,
            _selectedLocationData?.name ?? 'Lokasi acara',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPreviewRow(
                _selectedPrivacy == EventPrivacy.public
                    ? Icons.public
                    : Icons.lock_outline,
                _selectedPrivacy == EventPrivacy.public ? 'Publik' : 'Privat',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isFree
                      ? const Color(0xFF84994F).withValues(alpha: 0.2)
                      : Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isFree ? 'GRATIS' : CurrencyFormatter.formatToCompact(_price),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isFree ? const Color(0xFF84994F) : const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomActions() {
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton(
                  onPressed: canProceed ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF84994F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 1 ? 'Publish Acara' : 'Lanjut',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == 1 ? Icons.check_circle_outline : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.isNotEmpty &&
            _descriptionController.text.isNotEmpty &&
            _selectedLocationData != null;
      case 1:
        return _maxAttendeesController.text.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 1) {
        _slideController.reset();
        _slideController.forward();

        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        HapticFeedback.lightImpact();
      } else {
        _createEvent();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _slideController.reset();
      _slideController.forward();

      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      HapticFeedback.lightImpact();
    }
  }

  void _createEvent() {
    final newEvent = EventModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      startTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      endTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour + 2,
        _selectedTime.minute,
      ),
      location: EventLocationModel(
        name: _selectedLocationData?.name ?? 'Unknown Location',
        address: _selectedLocationData?.address ?? 'Unknown Address',
        latitude: _selectedLocationData?.latitude ?? -6.2088,
        longitude: _selectedLocationData?.longitude ?? 106.8456,
      ),
      host: const EventHostModel(
        id: 'current_user',
        name: 'You',
        avatar: 'https://doodleipsum.com/100x100/avatar',
        bio: 'Event organizer',
      ),
      imageUrls: const ['https://doodleipsum.com/600x400/abstract'],
      maxAttendees: int.tryParse(_maxAttendeesController.text) ?? 10,
      price: _isFree ? null : _price,
      isFree: _isFree,
      requirements: _requirementsController.text.isNotEmpty
          ? _requirementsController.text
          : null,
      privacy: _selectedPrivacy,
    );

    Navigator.pop(context, newEvent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Acara lo udah live! Gas share ke temen 🔥'),
        backgroundColor: const Color(0xFF84994F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Liat',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime() {
    final date = _formatDate(_selectedDate);
    final time = _selectedTime.format(context);
    return '$date at $time';
  }

  // Validation methods
  void _validateTitle(String value) {
    setState(() {
      if (value.isEmpty) {
        _titleError = 'Nama acara wajib diisi';
      } else if (value.length < 3) {
        _titleError = 'Nama acara minimal 3 karakter';
      } else {
        _titleError = null;
      }
    });
  }

  void _validateDescription(String value) {
    setState(() {
      if (value.isEmpty) {
        _descriptionError = 'Deskripsi acara wajib diisi';
      } else if (value.length < 10) {
        _descriptionError = 'Deskripsi minimal 10 karakter';
      } else {
        _descriptionError = null;
      }
    });
  }

  void _validateRequirements(String value) {
    setState(() {
      if (value.isNotEmpty && value.length < 5) {
        _requirementsError = 'Persyaratan minimal 5 karakter kalo diisi';
      } else {
        _requirementsError = null;
      }
    });
  }

  void _validateMaxAttendees(String value) {
    setState(() {
      if (value.isEmpty) {
        _maxAttendeesError = 'Kapasitas wajib diisi';
      } else {
        final number = int.tryParse(value);
        if (number == null || number < 1) {
          _maxAttendeesError = 'Harus angka dan lebih dari 0';
        } else if (number > 100) {
          _maxAttendeesError = 'Maksimal 100 orang untuk v1';
        } else {
          _maxAttendeesError = null;
        }
      }
    });
  }

  void _validatePrice(String value) {
    setState(() {
      if (!_isFree && value.isEmpty) {
        _priceError = 'Harga wajib diisi untuk acara berbayar';
      } else if (!_isFree) {
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          _priceError = 'Harga harus lebih dari 0';
        } else if (price > 10000000) {
          _priceError = 'Harganya terlalu mahal deh';
        } else {
          _priceError = null;
        }
      } else {
        _priceError = null;
      }
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        _validateTitle(_titleController.text);
        _validateDescription(_descriptionController.text);
        return _titleError == null &&
            _descriptionError == null &&
            _selectedLocationData != null;
      case 1:
        _validateMaxAttendees(_maxAttendeesController.text);
        if (!_isFree) {
          _validatePrice(_priceController.text);
          return _maxAttendeesError == null && _priceError == null;
        }
        return _maxAttendeesError == null;
      default:
        return false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        HapticFeedback.selectionClick();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ambil gambar: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _maxAttendeesController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
