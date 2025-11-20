import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../data/models/event_model.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_state.dart';
import '../../widgets/location_picker.dart';

class CreateEventModern extends StatefulWidget {
  const CreateEventModern({super.key});

  @override
  State<CreateEventModern> createState() => _CreateEventModernState();
}

class _CreateEventModernState extends State<CreateEventModern> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _priceController = TextEditingController();
  final _requirementsController = TextEditingController();

  // Form data
  EventCategory _selectedCategory = EventCategory.meetup;
  EventPrivacy _selectedPrivacy = EventPrivacy.public;
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;
  bool _isFree = true;
  double _price = 0;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  LocationData? _selectedLocationData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _maxAttendeesController.dispose();
    _priceController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitEvent();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _selectedStartDate != null &&
             _selectedStartTime != null &&
             _selectedLocationData != null;
    } else {
      return _titleController.text.trim().isNotEmpty &&
             _descriptionController.text.trim().isNotEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Event',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWhenAndWhereStep(),
                _buildDetailsStep(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(2, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Container(
                  height: 3,
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
          Text(
            _currentStep == 0 ? 'Kapan & Dimana?' : 'Ceritain Eventnya',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF84994F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentStep == 0
                ? 'Tentuin waktu dan lokasi event kamu'
                : 'Kasih detail menarik biar orang tertarik!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhenAndWhereStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // When section
          _buildSectionHeader('📅 Kapan acaranya?', 'Pilih tanggal dan waktu'),
          const SizedBox(height: 16),

          // Start date and time
          Row(
            children: [
              Expanded(
                child: _buildDateTimePicker(
                  label: 'Mulai',
                  date: _selectedStartDate,
                  time: _selectedStartTime,
                  onDateTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedStartDate = date);
                    }
                  },
                  onTimeTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 19, minute: 0),
                    );
                    if (time != null) {
                      setState(() => _selectedStartTime = time);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimePicker(
                  label: 'Selesai',
                  date: _selectedEndDate,
                  time: _selectedEndTime,
                  onDateTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedStartDate?.add(const Duration(hours: 2)) ??
                                   DateTime.now().add(const Duration(days: 1)),
                      firstDate: _selectedStartDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedEndDate = date);
                    }
                  },
                  onTimeTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: (_selectedStartTime?.hour ?? 19) + 2,
                        minute: _selectedStartTime?.minute ?? 0,
                      ),
                    );
                    if (time != null) {
                      setState(() => _selectedEndTime = time);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Where section
          _buildSectionHeader('📍 Dimana tempatnya?', 'Pilih lokasi event'),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _selectLocation(),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedLocationData != null
                      ? const Color(0xFF84994F)
                      : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDDA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF84994F),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLocationData?.name ?? 'Pilih Lokasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedLocationData != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        if (_selectedLocationData != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedLocationData!.address,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
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
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Tambah foto event',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _titleController,
            label: 'Nama Event',
            hint: 'Kasih nama yang catchy!',
            icon: Icons.event,
          ),

          const SizedBox(height: 16),

          _buildTextField(
            controller: _descriptionController,
            label: 'Deskripsi',
            hint: 'Ceritain apa yang bikin event kamu seru...',
            icon: Icons.description,
            maxLines: 5,
          ),

          const SizedBox(height: 24),

          _buildCategorySelector(),

          const SizedBox(height: 24),

          _buildPrivacySelector(),

          const SizedBox(height: 24),

          _buildPriceSelector(),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _maxAttendeesController,
            label: 'Kapasitas Peserta',
            hint: 'Maksimal berapa orang?',
            icon: Icons.people,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required TimeOfDay? time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onDateTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? DateFormat('dd MMM yyyy').format(date) : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null ? Colors.black : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTimeTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    time != null ? time.format(context) : 'Pilih waktu',
                    style: TextStyle(
                      fontSize: 13,
                      color: time != null ? Colors.black : Colors.grey[500],
                      fontWeight: FontWeight.w500,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
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
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF84994F)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF84994F), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EventCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF84994F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF84994F) : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  EventCategoryUtils.getCategoryDisplayName(category),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrivacySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: EventPrivacy.values.map((privacy) {
            final isSelected = _selectedPrivacy == privacy;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPrivacy = privacy),
                child: Container(
                  margin: EdgeInsets.only(right: privacy == EventPrivacy.public ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF84994F) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF84994F) : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    privacy == EventPrivacy.public ? 'Publik' : 'Private',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isFree ? 'Event Gratis' : 'Event Berbayar',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Switch(
              value: !_isFree,
              onChanged: (value) => setState(() => _isFree = !value),
              activeColor: const Color(0xFF84994F),
            ),
          ],
        ),
        if (!_isFree) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Harga tiket',
              prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF84994F)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF84994F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF84994F),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: canProceed ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF84994F),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 1 ? 'Buat Event' : 'Lanjut',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectLocation() async {
    final result = await showModalBottomSheet<LocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPicker(
        onLocationSelected: (locationData) {
          Navigator.pop(context, locationData);
        },
      ),
    );

    if (result != null) {
      setState(() => _selectedLocationData = result);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _submitEvent() {
    if (!_canProceed()) return;

    // TODO: Implement event submission
    AppLogger().info('Submit event');
    Navigator.pop(context);
  }
}
