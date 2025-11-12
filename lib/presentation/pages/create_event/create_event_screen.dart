import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/event_category.dart';
import '../../../data/models/event_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../bloc/events/events_bloc.dart';
import '../../bloc/events/events_state.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
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

  // Hashtag data
  final List<String> _defaultHashtags = [
    '#meetup', '#sports', '#workshop', '#networking', '#music',
    '#gaming', '#ngopi', '#hangout', '#learning', '#fun'
  ];
  final Set<String> _selectedHashtags = {};
  final TextEditingController _hashtagController = TextEditingController();

  // Validation states
  String? _titleError;
  String? _descriptionError;
  String? _locationError;
  String? _maxAttendeesError;
  String? _priceError;
  String? _requirementsError;

  // Get similar events from bloc based on selected category
  List<Event> _getSimilarEvents() {
    final eventsState = context.read<EventsBloc>().state;
    if (eventsState is EventsLoaded) {
      final categoryEvents = eventsState.events
          .where((event) => event.category == _selectedCategory)
          .toList();
      // Take up to 3 events from the same category
      return categoryEvents.take(3).toList();
    }
    return [];
  }

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
    _slideAnimation = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Color(0xFF000000), size: 22),
        ),
        title: const Text(
          'Bikin Acara Lo ✨',
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                'Balik',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
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
                    _buildSettingsAndPublishStep(),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final steps = ['Info Acara', 'Pengaturan & Publish'];

    return Container(
      color: const Color(0xFFFAF8F5),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thin progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Step indicator
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF84994F)
                        : isCompleted
                            ? Colors.grey[700]
                            : Colors.grey[400],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Step title with subtitle
          Text(
            _getStepSubtitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF000000),
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Info Acara - All essential event information
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Event Title
          _buildTextField(
            controller: _titleController,
            label: 'Nama Acara',
            hint: 'Kasih nama acara lo, biar gampang dicari 🤟',
            required: true,
            errorText: _titleError,
            onChanged: _validateTitle,
          ),
          const SizedBox(height: 24),

          // Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Deskripsi',
            hint: 'Ceritain dikit tentang acaranya 🔥',
            maxLines: 4,
            required: true,
            errorText: _descriptionError,
            onChanged: _validateDescription,
          ),
          const SizedBox(height: 24),

          // Date & Time
          _buildDateTimePicker(),
          const SizedBox(height: 24),

          // Location
          _buildTextField(
            controller: _locationController,
            label: 'Lokasi',
            hint: 'Dimana nih tempatnya? 📍',
            required: true,
            prefixIcon: Icons.location_on_outlined,
            errorText: _locationError,
            onChanged: _validateLocation,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Step 2: Settings & Publish - Privacy, capacity, pricing, and preview
  Widget _buildSettingsAndPublishStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Image Upload
          _buildImageUploadSection(),
          const SizedBox(height: 24),

          // Privacy
          _buildSectionTitle('Ramean atau Eksklusif?'),
          const SizedBox(height: 8),
          _buildPrivacySelector(),
          const SizedBox(height: 24),

          // Max Attendees & Pricing in Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _maxAttendeesController,
                  label: 'Kapasitas',
                  hint: 'Muat berapa?',
                  keyboardType: TextInputType.number,
                  required: true,
                  errorText: _maxAttendeesError,
                  onChanged: _validateMaxAttendees,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Harga'),
                    const SizedBox(height: 8),
                    _buildCompactPricingToggle(),
                  ],
                ),
              ),
            ],
          ),

          if (!_isFree) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              onChanged: (value) {
                _validatePrice(value);
                setState(() {
                  _price = double.tryParse(value) ?? 0;
                });
              },
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Masukkin harga (Rp)',
                prefixText: 'Rp ',
                errorText: _priceError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _priceError != null ? Colors.red : Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _priceError != null ? Colors.red : const Color(0xFF84994F),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Requirements (Optional)
          _buildTextField(
            controller: _requirementsController,
            label: 'Persyaratan (Opsional)',
            hint: 'Apa yang perlu dibawa peserta? 📝',
            maxLines: 3,
            required: false,
            errorText: _requirementsError,
            onChanged: _validateRequirements,
          ),
          const SizedBox(height: 24),

          // Preview Card
          _buildPreviewCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Compact Image Upload Section
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Foto Cover (Opsional)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _selectedImage == null ? Colors.white : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
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
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.grey[400],
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap buat upload cover image',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
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

  // Compact Pricing Toggle
  Widget _buildCompactPricingToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isFree = true;
                _price = 0;
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: _isFree ? const Color(0xFF84994F) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Gratis',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _isFree ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isFree = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_isFree ? const Color(0xFF84994F) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Berbayar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: !_isFree ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Preview Card
  Widget _buildPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Preview Acara'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titleController.text.isNotEmpty
                    ? _titleController.text
                    : 'Nama Acara',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000000),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _locationController.text.isNotEmpty
                          ? _locationController.text
                          : 'Lokasi acara',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    _selectedPrivacy == EventPrivacy.public
                        ? Icons.public
                        : Icons.lock_outline,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedPrivacy == EventPrivacy.public ? 'Publik' : 'Privat',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _isFree ? 'GRATIS' : 'Rp ${_price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isFree ? const Color(0xFF84994F) : Colors.grey[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildReviewStepOld() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Cek dulu sebelum publish',
  //           style: TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.w700,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         const SizedBox(height: 24),

  //         // Event Preview Card
  //         Container(
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(12),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.05),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Image placeholder
  //               GestureDetector(
  //                 onTap: _pickImage,
  //                 child: Container(
  //                   height: 140,
  //                   decoration: BoxDecoration(
  //                     borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
  //                     gradient: _selectedImage == null ? LinearGradient(
  //                       colors: [
  //                         AppColors.getCategoryColor(_selectedCategory).withValues(alpha: 0.3),
  //                         AppColors.getCategoryColor(_selectedCategory).withValues(alpha: 0.6),
  //                       ],
  //                     ) : null,
  //                     image: _selectedImage != null ? DecorationImage(
  //                       image: FileImage(_selectedImage!),
  //                       fit: BoxFit.cover,
  //                     ) : null,
  //                   ),
  //                 child: Stack(
  //                   children: [
  //                     Positioned(
  //                       top: 12,
  //                       left: 12,
  //                       child: Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 8,
  //                           vertical: 4,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: AppColors.getCategoryColor(_selectedCategory),
  //                           borderRadius: BorderRadius.circular(6),
  //                         ),
  //                         child: Text(
  //                           EventCategoryUtils.getCategoryName(_selectedCategory),
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 11,
  //                             fontWeight: FontWeight.w600,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                     if (!_isFree)
  //                       Positioned(
  //                         top: 12,
  //                         right: 12,
  //                         child: Container(
  //                           padding: const EdgeInsets.symmetric(
  //                             horizontal: 8,
  //                             vertical: 4,
  //                           ),
  //                           decoration: BoxDecoration(
  //                             color: Colors.black.withValues(alpha: 0.7),
  //                             borderRadius: BorderRadius.circular(6),
  //                           ),
  //                           child: Text(
  //                             'Rp ${_price.toStringAsFixed(0)}',
  //                             style: const TextStyle(
  //                               color: Colors.white,
  //                               fontSize: 11,
  //                               fontWeight: FontWeight.w600,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     if (_selectedImage == null)
  //                       const Center(
  //                         child: Column(
  //                           mainAxisAlignment: MainAxisAlignment.center,
  //                           children: [
  //                             Icon(
  //                               Icons.add_photo_alternate_outlined,
  //                               color: Colors.white,
  //                               size: 40,
  //                             ),
  //                             SizedBox(height: 8),
  //                             Text(
  //                               'Tap buat tambah cover image',
  //                               style: TextStyle(
  //                                 color: Colors.white,
  //                                 fontSize: 14,
  //                                 fontWeight: FontWeight.w500,
  //                               ),
  //                             ),
  //                           ],
  //                         ),
  //                       ),
  //                     if (_selectedImage != null)
  //                       Positioned(
  //                         top: 8,
  //                         right: 8,
  //                         child: GestureDetector(
  //                           onTap: () => setState(() => _selectedImage = null),
  //                           child: Container(
  //                             padding: const EdgeInsets.all(4),
  //                             decoration: BoxDecoration(
  //                               color: Colors.black.withValues(alpha: 0.7),
  //                               borderRadius: BorderRadius.circular(12),
  //                             ),
  //                             child: const Icon(
  //                               Icons.close,
  //                               color: Colors.white,
  //                               size: 16,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                   ],
  //                 ),),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.all(16),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       _titleController.text.isNotEmpty
  //                         ? _titleController.text
  //                         : 'Judul Acara',
  //                       style: const TextStyle(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w700,
  //                         color: Colors.black87,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Text(
  //                       'Punya Lo',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: Colors.grey[600],
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     Text(
  //                       _descriptionController.text.isNotEmpty
  //                         ? _descriptionController.text
  //                         : 'Deskripsi acara bakal nongol di sini...',
  //                       style: TextStyle(
  //                         fontSize: 13,
  //                         color: _descriptionController.text.isNotEmpty
  //                           ? Colors.grey[700]
  //                           : Colors.grey[500],
  //                         height: 1.4,
  //                       ),
  //                       maxLines: 2,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                     const SizedBox(height: 12),
  //                     Row(
  //                       children: [
  //                         Icon(
  //                           Icons.access_time,
  //                           size: 14,
  //                           color: Colors.grey[500],
  //                         ),
  //                         const SizedBox(width: 4),
  //                         Text(
  //                           _formatDateTime(),
  //                           style: TextStyle(
  //                             fontSize: 12,
  //                             color: Colors.grey[600],
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: Row(
  //                             children: [
  //                               Icon(
  //                                 Icons.location_on_outlined,
  //                                 size: 14,
  //                                 color: Colors.grey[500],
  //                               ),
  //                               const SizedBox(width: 4),
  //                               Expanded(
  //                                 child: Text(
  //                                   _locationController.text.isNotEmpty
  //                                     ? _locationController.text
  //                                     : 'Lokasi Acara',
  //                                   style: TextStyle(
  //                                     fontSize: 12,
  //                                     color: _locationController.text.isNotEmpty
  //                                       ? Colors.grey[600]
  //                                       : Colors.grey[500],
  //                                     fontWeight: FontWeight.w500,
  //                                   ),
  //                                   maxLines: 1,
  //                                   overflow: TextOverflow.ellipsis,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                         TextButton(
  //                           onPressed: () {},
  //                           style: TextButton.styleFrom(
  //                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                             minimumSize: const Size(0, 0),
  //                           ),
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               Icon(
  //                                 Icons.directions,
  //                                 size: 14,
  //                                 color: Colors.blue[600],
  //                               ),
  //                               const SizedBox(width: 4),
  //                               Text(
  //                                 'Maps 🗺️',
  //                                 style: TextStyle(
  //                                   fontSize: 11,
  //                                   color: Colors.blue[600],
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //               ),
  //               ),
                
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 24),

  //         // Terms notice
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: Colors.blue[50],
  //             borderRadius: BorderRadius.circular(12),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Icon(
  //                     Icons.info_outline,
  //                     color: Colors.blue[600],
  //                     size: 20,
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Siap publish acara lo?',
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: Colors.blue[800],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Acara lo bakal kelihatan sama semua orang di area lo. Pastiin semua detail udah bener ya',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.blue[700],
  //                   height: 1.4,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 24),

  //         // Similar Events Section
  //         _buildSimilarEventsSection(),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSimilarEventsSection() {
    final similarEvents = _getSimilarEvents();
    final categoryName = EventCategoryUtils.getCategoryName(_selectedCategory);

    if (similarEvents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Events dengan $categoryName serupa',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similarEvents.length,
            itemBuilder: (context, index) {
              return _buildSimilarEventCard(similarEvents[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarEventCard(Event event) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: NetworkImage(
                  event.imageUrls.isNotEmpty
                    ? event.imageUrls.first
                    : 'https://doodleipsum.com/600x400/abstract'
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getCategoryColor(event.category),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      EventCategoryUtils.getCategoryName(event.category),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                if (event.isPrivate)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                if (!event.isPrivate)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${event.startTime.difference(DateTime.now()).inHours}h',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Event details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${event.currentAttendees}/${event.maxAttendees}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = false,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, required: required),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: prefixIcon != null ? Icon(
                prefixIcon,
                size: 20,
                color: errorText != null ? Colors.red : Colors.grey[600],
              ) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red.withValues(alpha: 0.3) : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: errorText != null ? Colors.red : const Color(0xFF84994F),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: prefixIcon != null ? 12 : 20,
                vertical: maxLines > 1 ? 20 : 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: required ? [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red[600]),
          ),
        ] : null,
      ),
    );
  }

  Widget _buildPrivacySelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPrivacy = EventPrivacy.public),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedPrivacy == EventPrivacy.public ? const Color(0xFF84994F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPrivacy == EventPrivacy.public ? const Color(0xFF84994F) : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    color: _selectedPrivacy == EventPrivacy.public ? Colors.white : Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semua bisa join langsung 🚀',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedPrivacy == EventPrivacy.public ? Colors.white : const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Buka untuk semua orang',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _selectedPrivacy == EventPrivacy.public ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
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
            onTap: () => setState(() => _selectedPrivacy = EventPrivacy.private),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedPrivacy == EventPrivacy.private ? const Color(0xFF84994F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPrivacy == EventPrivacy.private ? const Color(0xFF84994F) : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: _selectedPrivacy == EventPrivacy.private ? Colors.white : Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Harus lo approve dulu 🙌',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _selectedPrivacy == EventPrivacy.private ? Colors.white : const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Eksklusif, lo yang kontrol',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _selectedPrivacy == EventPrivacy.private ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
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

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tanggal & Jam', required: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildPricingSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _buildSectionTitle('Harga'),
  //       const SizedBox(height: 8),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   _isFree = true;
  //                   _price = 0;
  //                 });
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: _isFree ? const Color(0xFF84994F) : Colors.white,
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(
  //                     color: _isFree ? const Color(0xFF84994F) : Colors.grey[300]!,
  //                     width: _isFree ? 2 : 1,
  //                   ),
  //                 ),
  //                 child: Text(
  //                   'Gratis',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w700,
  //                     color: _isFree ? Colors.white : const Color(0xFF000000),
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: GestureDetector(
  //               onTap: () {
  //                 setState(() {
  //                   _isFree = false;
  //                 });
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.all(16),
  //                 decoration: BoxDecoration(
  //                   color: !_isFree ? const Color(0xFF84994F) : Colors.white,
  //                   borderRadius: BorderRadius.circular(12),
  //                   border: Border.all(
  //                     color: !_isFree ? const Color(0xFF84994F) : Colors.grey[300]!,
  //                     width: !_isFree ? 2 : 1,
  //                   ),
  //                 ),
  //                 child: Text(
  //                   'Berbayar',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w700,
  //                     color: !_isFree ? Colors.white : const Color(0xFF000000),
  //                   ),
  //                   textAlign: TextAlign.center,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       if (!_isFree) ...[
  //         const SizedBox(height: 12),
  //         TextField(
  //           controller: _priceController,
  //           onChanged: (value) {
  //             _validatePrice(value);
  //             setState(() {
  //               _price = double.tryParse(value) ?? 0;
  //             });
  //           },
  //           keyboardType: TextInputType.number,
  //           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  //           decoration: InputDecoration(
  //             hintText: 'Masukkin harga (Rp)',
  //             prefixText: 'Rp ',
  //             errorText: _priceError,
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(color: _priceError != null ? Colors.red : Colors.grey[300]!),
  //             ),
  //             enabledBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(color: _priceError != null ? Colors.red : Colors.grey[300]!),
  //             ),
  //             focusedBorder: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(12),
  //               borderSide: BorderSide(color: _priceError != null ? Colors.red : const Color(0xFF84994F)),
  //             ),
  //             filled: true,
  //             fillColor: Colors.white,
  //             contentPadding: const EdgeInsets.all(16),
  //           ),
  //         ),
  //       ],
  //     ],
  //   );
  // }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canProceed() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF84994F),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              _currentStep == 1 ? 'Publish Acara 🚀' : 'Lanjut',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _titleController.text.isNotEmpty &&
               _descriptionController.text.isNotEmpty &&
               _locationController.text.isNotEmpty;
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

        // Haptic feedback
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

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _createEvent() {
    // IMPORTANT: This ID is temporary and will be replaced by backend
    // Unlike Post, EventModel.toJson() DOES send ID to backend
    // Backend MUST ignore this temp ID and generate its own real ID
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
        _selectedTime.hour + 2, // Default 2 hours duration
        _selectedTime.minute,
      ),
      location: EventLocationModel(
        name: _locationController.text,
        address: _locationController.text,
        latitude: -6.2088,
        longitude: 106.8456,
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
      requirements: _requirementsController.text.isNotEmpty ? _requirementsController.text : null,
      privacy: _selectedPrivacy,
    );

    // Show success and navigate back with the new event
    Navigator.pop(context, newEvent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Acara lo udah live! Gas share ke temen 🔥'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime() {
    final date = _formatDate(_selectedDate);
    final time = _selectedTime.format(context);
    return '$date at $time';
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Mulai dari info dasar acaranya';
      case 1:
        return 'Atur kapasitas, harga, dan detail lainnya';
      default:
        return '';
    }
  }

  // Helper methods removed - using utility classes instead

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
      // Requirements are optional, so only check if there's content
      if (value.isNotEmpty && value.length < 5) {
        _requirementsError = 'Persyaratan minimal 5 karakter kalo diisi';
      } else {
        _requirementsError = null;
      }
    });
  }

  void _validateLocation(String value) {
    setState(() {
      if (value.isEmpty) {
        _locationError = 'Lokasi wajib diisi';
      } else {
        _locationError = null;
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
        } else if (number > 1000) {
          _maxAttendeesError = 'Maksimal 1000 orang';
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
        _validateLocation(_locationController.text);
        return _titleError == null && _descriptionError == null && _locationError == null;
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

  // Widget _buildHashtagSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       _buildSectionTitle('Tambah vibes pake hashtag ✨'),
  //       const SizedBox(height: 4),
  //       Text(
  //         'Pilih dari list atau bikin hashtag lo sendiri 🤟',
  //         style: TextStyle(
  //           fontSize: 12,
  //           color: Colors.grey[600],
  //           fontWeight: FontWeight.w400,
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       _buildHashtagGrid(),
  //       const SizedBox(height: 16),
  //       _buildHashtagInput(),
  //     ],
  //   );
  // }

  Widget _buildHashtagGrid() {
    // Combine default and custom hashtags
    final allHashtags = [..._defaultHashtags, ..._selectedHashtags.where((tag) => !_defaultHashtags.contains(tag))];

    return SizedBox(
      height: 70, // Height for 2 rows
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          direction: Axis.vertical,
          spacing: 8,
          runSpacing: 8,
          children: allHashtags.map((hashtag) {
            final isSelected = _selectedHashtags.contains(hashtag);
            final isDefault = _defaultHashtags.contains(hashtag);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedHashtags.remove(hashtag);
                  } else {
                    _selectedHashtags.add(hashtag);
                  }
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hashtag,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    if (!isDefault && isSelected) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedHashtags.remove(hashtag);
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHashtagInput() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _hashtagController,
        onSubmitted: _addCustomHashtag,
        decoration: InputDecoration(
          hintText: 'Contoh: #sports #ngumpul #mabar 🎮',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.tag,
            size: 20,
            color: Colors.grey[600],
          ),
          suffixIcon: IconButton(
            onPressed: () => _addCustomHashtag(_hashtagController.text),
            icon: Icon(
              Icons.add_circle,
              color: const Color(0xFF6366F1),
              size: 22,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF6366F1),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _addCustomHashtag(String input) {
    if (input.trim().isEmpty) return;

    final hashtags = input.trim().split(RegExp(r'\s+'));

    for (String hashtag in hashtags) {
      String cleanTag = hashtag.trim();
      if (cleanTag.isNotEmpty) {
        // Add # if not present
        if (!cleanTag.startsWith('#')) {
          cleanTag = '#$cleanTag';
        }

        // Add to selected hashtags if not already present
        if (!_selectedHashtags.contains(cleanTag) && cleanTag.length > 1) {
          setState(() {
            _selectedHashtags.add(cleanTag);
          });
        }
      }
    }

    _hashtagController.clear();
    HapticFeedback.lightImpact();
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
    _locationController.dispose();
    _maxAttendeesController.dispose();
    _priceController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }
}