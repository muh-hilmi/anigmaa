import 'package:flutter/material.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/review.dart';
import '../social/user_profile_screen.dart';

class EventReviewsScreen extends StatefulWidget {
  final Event event;

  const EventReviewsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventReviewsScreen> createState() => _EventReviewsScreenState();
}

class _EventReviewsScreenState extends State<EventReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedRatingFilter = 0;

  final List<Review> _mockReviews = [
    Review(
      id: '1',
      userId: 'user1',
      userName: 'Sarah Chen',
      userAvatar: 'https://picsum.photos/100/100?random=1',
      eventId: 'event1',
      rating: 5,
      comment: 'Event keren abis! Rapih banget dan banyak ilmu yang gue dapet. Venue-nya pas banget dan networking-nya seru poll. Bakal ikut event dari organizer ini lagi deh!',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      images: ['https://picsum.photos/300/200?random=10'],
      helpfulCount: 12,
      isVerifiedAttendee: true,
    ),
    Review(
      id: '2',
      userId: 'user2',
      userName: 'Mike Johnson',
      userAvatar: 'https://picsum.photos/100/100?random=2',
      eventId: 'event1',
      rating: 4,
      comment: 'Overall bagus sih. Speaker-nya pinter-pinter tapi venue-nya agak penuh. Tapi makanannya enak banget!',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 8,
      isVerifiedAttendee: true,
    ),
    Review(
      id: '3',
      userId: 'user3',
      userName: 'Jessica Wong',
      userAvatar: 'https://picsum.photos/100/100?random=3',
      eventId: 'event1',
      rating: 5,
      comment: 'Suka banget! Ketemu banyak orang menarik dan kontennya pas banget sama yang gue cari.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      images: ['https://picsum.photos/300/200?random=11', 'https://picsum.photos/300/200?random=12'],
      helpfulCount: 15,
      isVerifiedAttendee: true,
    ),
    Review(
      id: '4',
      userId: 'user4',
      userName: 'David Kim',
      userAvatar: 'https://picsum.photos/100/100?random=4',
      eventId: 'event1',
      rating: 3,
      comment: 'Lumayan sih. Gue ngarep lebih banyak sesi interaktif tapi kebanyakan presentasi aja. Tapi tetep dapet ilmu baru kok.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      helpfulCount: 3,
      isVerifiedAttendee: true,
    ),
    Review(
      id: '5',
      userId: 'user5',
      userName: 'Emily Rodriguez',
      userAvatar: 'https://picsum.photos/100/100?random=5',
      eventId: 'event1',
      rating: 4,
      comment: 'Kesempatan networking yang keren! Organizer-nya jago banget ngumpulin orang-orang yang se-vibe.',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      helpfulCount: 6,
      isVerifiedAttendee: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final averageRating = _calculateAverageRating();
    final ratingCounts = _calculateRatingCounts();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review & Rating ⭐',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Semua Review'),
            Tab(text: 'Tulis Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsTab(averageRating, ratingCounts),
          _buildWriteReviewTab(),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(double averageRating, Map<int, int> ratingCounts) {
    final filteredReviews = _getFilteredReviews();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRatingSummary(averageRating, ratingCounts),
          _buildRatingFilter(),
          _buildReviewsList(filteredReviews),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(double averageRating, Map<int, int> ratingCounts) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < averageRating.floor()
                                  ? Icons.star
                                  : index < averageRating
                                      ? Icons.star_half
                                      : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_mockReviews.length} review',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final rating = 5 - index;
                final count = ratingCounts[rating] ?? 0;
                final percentage = _mockReviews.isEmpty ? 0.0 : count / _mockReviews.length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Semua', 0),
            const SizedBox(width: 8),
            _buildFilterChip('5 ⭐', 5),
            const SizedBox(width: 8),
            _buildFilterChip('4 ⭐', 4),
            const SizedBox(width: 8),
            _buildFilterChip('3 ⭐', 3),
            const SizedBox(width: 8),
            _buildFilterChip('2 ⭐', 2),
            const SizedBox(width: 8),
            _buildFilterChip('1 ⭐', 1),
            const SizedBox(width: 8),
            _buildFilterChip('Pake Foto 📸', -1),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int rating) {
    final isSelected = _selectedRatingFilter == rating;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRatingFilter = selected ? rating : 0;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontSize: 12,
      ),
    );
  }

  Widget _buildReviewsList(List<Review> reviews) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada review nih 😕',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ganti filter lo deh',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewCard(reviews[index]);
      },
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: review.userId,
                        userName: review.userName,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(review.userAvatar),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (review.isVerifiedAttendee) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(review.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(review.images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _toggleHelpful(review.id),
                icon: Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                label: Text(
                  'Membantu (${review.helpfulCount})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              TextButton(
                onPressed: () => _reportReview(review.id),
                child: Text(
                  'Laporin',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.event.imageUrls.isNotEmpty
                            ? widget.event.imageUrls.first
                            : 'https://picsum.photos/100/100',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatEventDate(widget.event.startTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gimana Pengalaman Lo? 🤔',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRatingSelector(),
                const SizedBox(height: 20),
                const Text(
                  'Ceritain Dong 💭',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Ceritain pengalaman lo di event ini...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tambahin Foto (opsional) 📷',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPhotoUpload(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kirim Review! 🚀',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _selectedRating = 0;

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = index + 1;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              index < _selectedRating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPhotoUpload() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: InkWell(
        onTap: _selectPhotos,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 32,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap buat tambahin foto',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateAverageRating() {
    if (_mockReviews.isEmpty) return 0.0;
    final sum = _mockReviews.fold(0, (sum, review) => sum + review.rating);
    return sum / _mockReviews.length;
  }

  Map<int, int> _calculateRatingCounts() {
    final counts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      counts[i] = _mockReviews.where((review) => review.rating == i).length;
    }
    return counts;
  }

  List<Review> _getFilteredReviews() {
    if (_selectedRatingFilter == 0) {
      return _mockReviews;
    } else if (_selectedRatingFilter == -1) {
      return _mockReviews.where((review) => review.images.isNotEmpty).toList();
    } else {
      return _mockReviews.where((review) => review.rating == _selectedRatingFilter).toList();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${difference.inMinutes} menit yang lalu';
    }
  }

  String _formatEventDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  void _toggleHelpful(String reviewId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Makasih udah kasih feedback! 🙏'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _reportReview(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporin Review'),
        content: const Text('Kenapa mau laporin review ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Gajadi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Review udah dilaporin ✅')),
              );
            },
            child: const Text('Laporin'),
          ),
        ],
      ),
    );
  }

  void _selectPhotos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bentar lagi bisa pilih foto! 📸'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitReview() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih rating dulu dong! ⭐'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Terkirim! 🎉'),
        content: const Text('Makasih udah kasih review ya! Review lo bakal bantu orang lain nemuin event keren.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Oke Siap! 👍'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}