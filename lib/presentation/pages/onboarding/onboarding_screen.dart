import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Cari Acara Seru di Sekitar Lo 🎉',
      description: 'Dari ngopi bareng sampe workshop kece, semua ada di sini. Gas temuin yang cocok sama vibe lo!',
      image: 'https://doodleipsum.com/300x200/abstract',
      icon: Icons.explore_outlined,
    ),
    OnboardingPage(
      title: 'RSVP Sekali Klik, Langsung Gas! 🚀',
      description: 'Tinggal tap, udah terdaftar. Plus bisa langsung ditambahin ke kalender biar ga lupa.',
      image: 'https://doodleipsum.com/300x200/abstract',
      icon: Icons.event_available_outlined,
    ),
    OnboardingPage(
      title: 'Bikin Acara Lo Sendiri ✨',
      description: 'Cuma 3 langkah doang! Ajak temen-temen nongkrong bareng dan bikin komunitas lo makin rame.',
      image: 'https://doodleipsum.com/300x200/abstract',
      icon: Icons.groups_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo/App name
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF84994F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.event,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Anigmaa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF000000),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Lewatin',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom section with dots and button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentPage == index ? const Color(0xFF84994F) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentPage == _pages.length - 1
                          ? _completeOnboarding
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF84994F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Gas Mulai! 🚀' : 'Lanjut',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  if (_currentPage < _pages.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: const Text(
                        'Nanti aja deh',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 48,
              color: const Color(0xFF84994F),
            ),
          ),

          // Title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF000000),
              height: 1.2,
              letterSpacing: -0.8,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.5,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  void _completeOnboarding() {
    // In a real app, you'd save that onboarding is complete
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}