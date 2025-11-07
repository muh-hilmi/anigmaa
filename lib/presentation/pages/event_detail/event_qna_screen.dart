import 'package:flutter/material.dart';

class EventQnAScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventQnAScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventQnAScreen> createState() => _EventQnAScreenState();
}

class _EventQnAScreenState extends State<EventQnAScreen> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  // TODO: Replace with real data from BLoC/Repository
  final List<QnAItem> _mockQnA = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    _mockQnA.addAll([
      QnAItem(
        id: 'q1',
        question: 'Ada parkir ga di venue-nya?',
        answer: 'Ada! Parkir gratis di basement. Langsung aja turun pas masuk gedung.',
        askedBy: 'Budi',
        answeredBy: 'Event Organizer',
        askedAt: DateTime.now().subtract(const Duration(days: 2)),
        answeredAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
        upvotes: 15,
        isUpvoted: false,
      ),
      QnAItem(
        id: 'q2',
        question: 'Boleh bawa temen yang ga daftar?',
        answer: 'Maaf ya, semua peserta harus daftar dulu karena kuota terbatas. Ajak temen lo buat daftar online!',
        askedBy: 'Sarah',
        answeredBy: 'Event Organizer',
        askedAt: DateTime.now().subtract(const Duration(days: 1)),
        answeredAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
        upvotes: 8,
        isUpvoted: true,
      ),
      QnAItem(
        id: 'q3',
        question: 'Harus bawa apa nih ke eventnya?',
        answer: 'Bawa ID card, tiket (bisa di HP), sama semangat buat networking! Makanan & minuman disediain kok.',
        askedBy: 'Andi',
        answeredBy: 'Event Organizer',
        askedAt: DateTime.now().subtract(const Duration(hours: 12)),
        answeredAt: DateTime.now().subtract(const Duration(hours: 10)),
        upvotes: 12,
        isUpvoted: false,
      ),
      QnAItem(
        id: 'q4',
        question: 'Dress code nya casual atau formal?',
        answer: 'Smart casual aja! Ga perlu terlalu formal, yang penting rapi dan nyaman.',
        askedBy: 'Dina',
        answeredBy: 'Event Organizer',
        askedAt: DateTime.now().subtract(const Duration(hours: 5)),
        answeredAt: DateTime.now().subtract(const Duration(hours: 4)),
        upvotes: 5,
        isUpvoted: false,
      ),
      QnAItem(
        id: 'q5',
        question: 'Ada certificate nya ga?',
        answer: 'Ada! Certificate of attendance bakal dikirim via email H+3 setelah event selesai.',
        askedBy: 'Eko',
        answeredBy: 'Event Organizer',
        askedAt: DateTime.now().subtract(const Duration(hours: 3)),
        answeredAt: DateTime.now().subtract(const Duration(hours: 2)),
        upvotes: 20,
        isUpvoted: true,
      ),
      QnAItem(
        id: 'q6',
        question: 'Bisa refund ga kalau ga jadi dateng?',
        answer: null, // Unanswered question
        askedBy: 'Fitri',
        answeredBy: null,
        askedAt: DateTime.now().subtract(const Duration(hours: 1)),
        answeredAt: null,
        upvotes: 3,
        isUpvoted: false,
      ),
    ]);
  }

  List<QnAItem> get _filteredQnA {
    var filtered = _mockQnA;

    // Filter by status
    switch (_selectedFilter) {
      case 'answered':
        filtered = filtered.where((q) => q.answer != null).toList();
        break;
      case 'unanswered':
        filtered = filtered.where((q) => q.answer == null).toList();
        break;
      case 'popular':
        filtered = List.from(filtered)..sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((q) =>
        q.question.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        (q.answer?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false)
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Q&A',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF000000),
              ),
            ),
            Text(
              widget.eventTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000000)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari pertanyaan...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF84994F)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 12),
          // Q&A List
          Expanded(
            child: _filteredQnA.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredQnA.length,
                    itemBuilder: (context, index) {
                      return _buildQnACard(_filteredQnA[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _askQuestion,
        backgroundColor: const Color(0xFF84994F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tanya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('Semua', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Dijawab', 'answered'),
          const SizedBox(width: 8),
          _buildFilterChip('Belum Dijawab', 'unanswered'),
          const SizedBox(width: 8),
          _buildFilterChip('Populer', 'popular'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF84994F),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF84994F) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildQnACard(QnAItem qna) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Color(0xFF84994F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qna.question,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ditanya oleh ${qna.askedBy} · ${_formatTime(qna.askedAt)}',
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

          // Answer section
          if (qna.answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Color(0xFF84994F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        qna.answeredBy!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF84994F),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(qna.answeredAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    qna.answer!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Menunggu jawaban dari organizer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Upvote section
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (qna.isUpvoted) {
                      qna.upvotes--;
                      qna.isUpvoted = false;
                    } else {
                      qna.upvotes++;
                      qna.isUpvoted = true;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: qna.isUpvoted
                        ? const Color(0xFF84994F).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: qna.isUpvoted
                          ? const Color(0xFF84994F)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        qna.isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 14,
                        color: qna.isUpvoted ? const Color(0xFF84994F) : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${qna.upvotes}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: qna.isUpvoted ? const Color(0xFF84994F) : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                qna.upvotes == 1 ? '1 orang merasa terbantu' : '${qna.upvotes} orang merasa terbantu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    if (_searchController.text.isNotEmpty) {
      message = 'Ga ada hasil untuk "${_searchController.text}"';
    } else if (_selectedFilter == 'answered') {
      message = 'Belum ada pertanyaan yang dijawab';
    } else if (_selectedFilter == 'unanswered') {
      message = 'Semua pertanyaan sudah dijawab!';
    } else {
      message = 'Belum ada pertanyaan nih.\nJadi yang pertama nanya yuk!';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🤔',
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _askQuestion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  const Text(
                    'Mau Tanya Apa Nih? 🤔',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Host bakal jawab pertanyaan lo tentang "${widget.eventTitle}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Question input
                  TextField(
                    autofocus: true,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tulis pertanyaan lo di sini...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAF8F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text('Pertanyaan terkirim! ✅'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF84994F),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84994F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kirim Pertanyaan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}h lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m lalu';
    } else {
      return 'Baru saja';
    }
  }
}

// Model
class QnAItem {
  final String id;
  final String question;
  String? answer;
  final String askedBy;
  String? answeredBy;
  final DateTime askedAt;
  DateTime? answeredAt;
  int upvotes;
  bool isUpvoted;

  QnAItem({
    required this.id,
    required this.question,
    this.answer,
    required this.askedBy,
    this.answeredBy,
    required this.askedAt,
    this.answeredAt,
    required this.upvotes,
    required this.isUpvoted,
  });
}
