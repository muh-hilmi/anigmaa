import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../domain/entities/event_category.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/event_category_utils.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../widgets/location_picker.dart';
import 'components/chat_message_model.dart';
import 'components/message_bubble.dart';
import 'components/typing_indicator.dart';
import 'components/event_preview_card.dart';
import 'components/category_selector.dart';
import 'components/price_selector.dart';
import 'components/image_options_selector.dart';

class CreateEventConversation extends StatefulWidget {
  const CreateEventConversation({super.key});

  @override
  State<CreateEventConversation> createState() =>
      _CreateEventConversationState();
}

class _CreateEventConversationState extends State<CreateEventConversation>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  ConversationStep _currentStep = ConversationStep.greeting;
  bool _isTyping = false;
  bool _waitingForInput = false;
  List<String> _activeQuickReplies = [];

  // Event data
  String _eventTitle = '';
  String _eventDescription = '';
  DateTime? _startDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  LocationData? _location;
  EventCategory _category = EventCategory.meetup;
  bool _isFree = true;
  double _price = 0;
  int _capacity = 50;
  EventPrivacy _privacy = EventPrivacy.public;
  File? _coverImage;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _startConversation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage('Halo! 👋\n\nYuk bikin event bareng. Siap?');
      Future.delayed(const Duration(milliseconds: 1500), () {
        _showQuickReplies(['Siap! 🚀', 'Gasss 🔥']);
      });
    });
  }

  void _addBotMessage(String text, {Widget? customWidget}) {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: text, isBot: true, customWidget: customWidget),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isBot: false));
      _waitingForInput = false;
    });
    _scrollToBottom();
    _inputController.clear();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickReplies(List<String> replies) {
    setState(() {
      _waitingForInput = true;
      _activeQuickReplies = replies;
    });
  }

  void _handleQuickReply(String reply) {
    setState(() {
      _activeQuickReplies = [];
    });

    // Handle retry buttons for pickers
    if (reply == 'Pilih Tanggal 📅') {
      _addUserMessage(reply);
      _showDatePicker(isStart: true);
      return;
    } else if (reply == 'Pilih Jam Mulai 🕐') {
      _addUserMessage(reply);
      _showTimePicker(isStart: true);
      return;
    } else if (reply == 'Pilih Jam Selesai 🕐') {
      _addUserMessage(reply);
      _showTimePicker(isStart: false);
      return;
    } else if (reply == 'Pilih Lokasi 📍') {
      _addUserMessage(reply);
      _showLocationPicker();
      return;
    }

    // Normal flow
    _addUserMessage(reply);
    _moveToNextStep();
  }

  void _moveToNextStep() {
    Future.delayed(const Duration(milliseconds: 500), () {
      switch (_currentStep) {
        case ConversationStep.greeting:
          _currentStep = ConversationStep.askStartDate;
          _addBotMessage('Keren! 🎉\n\nKapan eventnya dimulai?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showDatePicker(isStart: true);
          });
          break;

        case ConversationStep.askStartDate:
          _currentStep = ConversationStep.askStartTime;
          String dateStr = DateFormat('dd MMMM yyyy').format(_startDate!);
          _addBotMessage('Oke tanggal $dateStr 📅\n\nJam berapa mulainya?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showTimePicker(isStart: true);
          });
          break;

        case ConversationStep.askStartTime:
          _currentStep = ConversationStep.askEndTime;
          _addBotMessage('Sip! 🕐\n\nSampai jam berapa eventnya?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showTimePicker(isStart: false);
          });
          break;

        case ConversationStep.askEndTime:
          _currentStep = ConversationStep.askLocation;
          _addBotMessage('Perfect! 🕐\n\nDimana tempatnya nih?');
          // Add delay so user can read the message before picker appears
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _showLocationPicker();
          });
          break;

        case ConversationStep.askLocation:
          _currentStep = ConversationStep.askName;
          _addBotMessage('Lokasi oke! 📍\n\nSekarang, apa nama eventnya?');
          _waitForTextInput();
          break;

        case ConversationStep.askName:
          _currentStep = ConversationStep.askDescription;
          _addBotMessage(
            'Nice! "$_eventTitle" 🔥\n\nCeritain dong, eventnya tentang apa?',
          );
          _waitForTextInput(multiline: true);
          break;

        case ConversationStep.askDescription:
          _currentStep = ConversationStep.askCategory;
          _addBotMessage('Mantap! 📝\n\nMasuk kategori apa nih eventnya?');
          _showCategorySelector();
          break;

        case ConversationStep.askCategory:
          _currentStep = ConversationStep.askPrice;
          String categoryName = EventCategoryUtils.getCategoryDisplayName(
            _category,
          );
          _addBotMessage(
            '$categoryName ya! ✨\n\nEvent ini gratis atau berbayar?',
          );
          _showPriceSelector();
          break;

        case ConversationStep.askPrice:
          _currentStep = ConversationStep.askCapacity;
          if (_isFree) {
            _addBotMessage(
              'Gratis! Asik banget 🎁\n\nBisa muat berapa orang nih?',
            );
          } else {
            String priceStr = CurrencyFormatter.formatToRupiah(_price);
            _addBotMessage(
              'Harga $priceStr per orang 💰\n\nBisa muat berapa orang nih?',
            );
          }
          _waitForNumberInput();
          break;

        case ConversationStep.askCapacity:
          _currentStep = ConversationStep.askPrivacy;
          _addBotMessage(
            'Oke kapasitas $_capacity orang! 👥\n\nMau publik atau private?',
          );
          _showQuickReplies(['Publik 🌍', 'Private 🔒']);
          break;

        case ConversationStep.askPrivacy:
          _currentStep = ConversationStep.askImage;
          String privacyStr = _privacy == EventPrivacy.public
              ? 'Publik'
              : 'Private';
          _addBotMessage(
            '$privacyStr event ya! 🎯\n\nTerakhir, mau tambahin foto cover?',
          );
          _showImageOptions();
          break;

        case ConversationStep.askImage:
          _currentStep = ConversationStep.preview;
          _addBotMessage('Perfect! Ini preview eventnya:');
          _showPreview();
          break;

        default:
          break;
      }
    });
  }

  void _waitForTextInput({bool multiline = false}) {
    setState(() => _waitingForInput = true);
  }

  void _waitForNumberInput() {
    setState(() => _waitingForInput = true);
  }

  void _handleTextInput(String text) {
    if (text.trim().isEmpty) return;

    switch (_currentStep) {
      case ConversationStep.askName:
        _eventTitle = text.trim();
        break;
      case ConversationStep.askDescription:
        _eventDescription = text.trim();
        break;
      case ConversationStep.askCapacity:
        _capacity = int.tryParse(text) ?? 50;
        break;
      default:
        break;
    }

    _addUserMessage(text);
    _moveToNextStep();
  }

  void _showDatePicker({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFBBC863)),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _activeQuickReplies = [];
      });
      _startDate = date;
      String dateStr = DateFormat('dd MMMM yyyy').format(date);
      _addUserMessage(dateStr);
      _moveToNextStep();
    } else {
      // User canceled, show retry option
      _addBotMessage(
        'Oke, kalau udah siap pilih tanggalnya, klik tombol ini ya! 📅',
      );
      _showQuickReplies(['Pilih Tanggal 📅']);
    }
  }

  void _showTimePicker({required bool isStart}) async {
    // Calculate initial end time (start time + 2 hours)
    TimeOfDay initialEndTime = const TimeOfDay(hour: 21, minute: 0);
    if (_startTime != null) {
      int endHour = (_startTime!.hour + 2) % 24;
      initialEndTime = TimeOfDay(hour: endHour, minute: _startTime!.minute);
    }

    final time = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 19, minute: 0)
          : initialEndTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFFBBC863)),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time != null) {
      // Validate end time
      if (!isStart && _startTime != null) {
        final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
        final endMinutes = time.hour * 60 + time.minute;

        if (endMinutes == startMinutes) {
          _addBotMessage(
            'Oops! ⏰ Jam mulai dan selesai tidak boleh sama. Event minimal harus ada durasinya dong!',
          );
          _showQuickReplies(['Pilih Jam Selesai 🕐']);
          return;
        }
      }

      setState(() {
        _activeQuickReplies = [];
      });
      if (isStart) {
        _startTime = time;
      } else {
        _endTime = time;
      }

      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      final timeStr = DateFormat('HH:mm').format(dt);
      _addUserMessage(timeStr);
      _moveToNextStep();
    } else {
      // User canceled, show retry option
      String message = isStart
          ? 'Oke, kalau udah siap pilih jam mulainya, klik tombol ini ya! 🕐'
          : 'Oke, kalau udah siap pilih jam selesainya, klik tombol ini ya! 🕐';
      _addBotMessage(message);
      _showQuickReplies(
        isStart ? ['Pilih Jam Mulai 🕐'] : ['Pilih Jam Selesai 🕐'],
      );
    }
  }

  void _showLocationPicker() async {
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
      setState(() {
        _activeQuickReplies = [];
      });
      _location = result;
      _addUserMessage('📍 ${result.name}');
      _moveToNextStep();
    } else {
      // User canceled, show retry option
      _addBotMessage(
        'Oke, kalau udah siap pilih lokasinya, klik tombol ini ya! 📍',
      );
      _showQuickReplies(['Pilih Lokasi 📍']);
    }
  }

  void _showCategorySelector() {
    setState(() => _waitingForInput = true);
  }

  void _showPriceSelector() {
    setState(() => _waitingForInput = true);
  }

  void _showImageOptions() {
    setState(() => _waitingForInput = true);
  }

  void _showPriceInput() async {
    final priceController = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harga Tiket'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Harga (Rp)',
            hintText: 'Contoh: 50000',
            prefixText: 'Rp ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price != null && price > 0) {
                Navigator.pop(context, price);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      _price = result;
      String priceStr = CurrencyFormatter.formatToRupiah(_price);
      _addUserMessage(priceStr);
      _moveToNextStep();
    }
  }

  void _showPreview() {
    // Show preview card in chat
    final previewWidget = EventPreviewCard(
      title: _eventTitle,
      description: _eventDescription,
      startDate: _startDate!,
      startTime: _startTime!,
      endTime: _endTime!,
      locationName: _location?.name ?? 'Lokasi',
      category: _category,
      isFree: _isFree,
      price: _price,
      capacity: _capacity,
      privacy: _privacy,
      coverImage: _coverImage,
    );

    _addBotMessage('', customWidget: previewWidget);
    setState(() => _waitingForInput = true);
  }

  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Batalkan Event?'),
            content: const Text(
              'Progress kamu bakal ilang nih kalau keluar sekarang. Yakin?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Nggak Jadi'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Ya, Keluar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handleBackNavigation() async {
    final shouldPop = await _showExitConfirmationDialog();
    if (shouldPop && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFBBC863)),
            onPressed: _handleBackNavigation,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Buat Event Baru',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Isi detail event kamu',
                style: TextStyle(
                  color: Color(0xFFBBC863),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          toolbarHeight: 64,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: _messages[index]);
                    },
                  ),
                ),
              ],
            ),
            if (_waitingForInput && _activeQuickReplies.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activeQuickReplies
                        .map((reply) => _buildQuickReply(reply))
                        .toList(),
                  ),
                ),
              ),
            if (_waitingForInput && _activeQuickReplies.isEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(child: _buildInputArea()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    Widget inputWidget;

    // If there are active quick replies, show them
    if (_activeQuickReplies.isNotEmpty) {
      inputWidget = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _activeQuickReplies
            .map((reply) => _buildQuickReply(reply))
            .toList(),
      );
    } else {
      switch (_currentStep) {
        case ConversationStep.greeting:
          inputWidget = Wrap(
            spacing: 8,
            children: [
              _buildQuickReply('Siap! 🚀'),
              _buildQuickReply('Gasss 🔥'),
            ],
          );
          break;

        case ConversationStep.askCategory:
          inputWidget = CategorySelector(
            onCategorySelected: (category) {
              _category = category;
              String categoryName = EventCategoryUtils.getCategoryDisplayName(
                category,
              );
              _addUserMessage(categoryName);
              _moveToNextStep();
            },
          );
          break;

        case ConversationStep.askPrice:
          inputWidget = PriceSelector(
            onOptionSelected: (isFree) {
              _isFree = isFree;
              if (isFree) {
                _price = 0;
                _addUserMessage('Gratis 🎁');
                _moveToNextStep();
              } else {
                _showPriceInput();
              }
            },
          );
          break;

        case ConversationStep.askPrivacy:
          inputWidget = Wrap(
            spacing: 8,
            children: [
              _buildQuickReply('Publik 🌍'),
              _buildQuickReply('Private 🔒'),
            ],
          );
          break;

        case ConversationStep.askImage:
          inputWidget = ImageOptionsSelector(
            onOptionSelected: (source) async {
              if (source == null) {
                _addUserMessage('Skip foto');
                _moveToNextStep();
              } else {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: source);
                if (image != null) {
                  _coverImage = File(image.path);
                  _addUserMessage('Foto terupload! ✅');
                  _moveToNextStep();
                }
              }
            },
          );
          break;

        case ConversationStep.preview:
          inputWidget = _buildPreviewActions();
          break;

        default:
          inputWidget = _buildTextInput();
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(top: false, child: inputWidget),
    );
  }

  Widget _buildQuickReply(String text) {
    return GestureDetector(
      onTap: () {
        if (text.contains('Publik')) {
          _privacy = EventPrivacy.public;
        } else if (text.contains('Private')) {
          _privacy = EventPrivacy.private;
        }
        _handleQuickReply(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFBBC863),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            maxLines: _currentStep == ConversationStep.askDescription ? 3 : 1,
            keyboardType: _currentStep == ConversationStep.askCapacity
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: _getInputHint(),
              filled: true,
              fillColor: const Color(0xFFFCFCFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            onSubmitted: (_) => _handleTextInput(_inputController.text),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _handleTextInput(_inputController.text),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFBBC863),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  String _getInputHint() {
    switch (_currentStep) {
      case ConversationStep.askName:
        return 'Nama event kamu...';
      case ConversationStep.askDescription:
        return 'Ceritain eventnya...';
      case ConversationStep.askCapacity:
        return 'Jumlah peserta...';
      default:
        return 'Ketik disini...';
    }
  }

  Widget _buildPreviewActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleBackNavigation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFBBC863)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBBC863),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _submitEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBBC863),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Buat Event! 🎉',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submitEvent() {
    // TODO: Implement event submission
    AppLogger().info('Submit event: $_eventTitle');
    Navigator.pop(context);
  }
}
