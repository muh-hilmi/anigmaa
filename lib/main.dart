import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/utils/app_logger.dart';
import 'injection_container.dart' as di;
import 'presentation/pages/discover/discover_screen.dart';
import 'presentation/pages/home/home_screen.dart';
import 'presentation/pages/create_event/create_event_screen.dart';
import 'presentation/bloc/events/events_bloc.dart';
import 'presentation/bloc/user/user_bloc.dart';
import 'presentation/bloc/user/user_event.dart';
import 'presentation/bloc/posts/posts_bloc.dart';
import 'presentation/bloc/communities/communities_bloc.dart';
import 'presentation/bloc/communities/communities_event.dart';
import 'domain/entities/event.dart';
import 'presentation/pages/profile/profile_screen.dart';
import 'presentation/pages/community/new_community_screen.dart';
import 'presentation/pages/calendar/calendar_screen.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/auth/onboarding_screen.dart';
import 'presentation/pages/auth/login_screen.dart';
import 'presentation/pages/create_post/create_post_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger().init();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    await di.init();
    runApp(const NotionSocialApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Inisialisasi App',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotionSocialApp extends StatelessWidget {
  const NotionSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EventsBloc>(
          create: (context) => di.sl<EventsBloc>(),
        ),
        BlocProvider<UserBloc>(
          create: (context) => di.sl<UserBloc>()..add(LoadUserProfile()),
        ),
        BlocProvider<PostsBloc>(
          create: (context) => di.sl<PostsBloc>(),
        ),
        BlocProvider<CommunitiesBloc>(
          create: (context) => di.sl<CommunitiesBloc>()..add(LoadCommunities()),
        ),
      ],
      child: MaterialApp(
        title: 'Anigmaa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF84994F),
            brightness: Brightness.light,
          ),
          primaryColor: const Color(0xFF84994F),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF84994F)),
            titleTextStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const MainNavigationWrapper(),
          '/login': (context) => const LoginScreen(),
        },
      ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  int _homeTabIndex = 0; // Track which tab is active in HomeScreen (0=Feed, 1=Events)
  final GlobalKey<DiscoverScreenState> _discoverKey = GlobalKey<DiscoverScreenState>();
  bool _isSpeedDialOpen = false;

  void _onHomeTabChanged(int tabIndex) {
    setState(() {
      _homeTabIndex = tabIndex;
    });
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  void _closeSpeedDial() {
    setState(() {
      _isSpeedDialOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = HomeScreen(onTabChanged: _onHomeTabChanged); // Home with Feed/Events tabs
        break;
      case 1:
        currentScreen = DiscoverScreen(key: _discoverKey); // Redesigned Discover Page
        break;
      case 2:
        currentScreen = const NewCommunityScreen();
        break;
      case 3:
        currentScreen = const ProfileScreen();
        break;
      default:
        currentScreen = HomeScreen(onTabChanged: _onHomeTabChanged);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Close speed dial if open
        if (_isSpeedDialOpen) {
          _closeSpeedDial();
          return;
        }

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Keluar dari App'),
              content: const Text('Yakin mau keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Keluar'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            currentScreen,
            // Backdrop overlay when speed dial is open
            if (_isSpeedDialOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSpeedDial,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(child: _buildNavItem(
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Beranda',
                  0
                )),
                Flexible(child: _buildNavItem(
                  Icons.explore_outlined,
                  Icons.explore,
                  'Jelajah',
                  1
                )),
                Flexible(child: _buildNavItem(
                  Icons.people_outline,
                  Icons.people,
                  'Komunitas',
                  2
                )),
                Flexible(child: _buildNavItem(
                  Icons.person_outline,
                  Icons.person,
                  'Profil',
                  3
                )),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: (_currentIndex == 0 && _homeTabIndex == 1) ||
                                _currentIndex == 2 ||
                                _currentIndex == 3
        ? null // Hide FAB on: Home Events tab, Communities, and Profile
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Speed dial options
              if (_isSpeedDialOpen) ...[
                _buildSpeedDialOption(
                  label: 'Bikin Event',
                  icon: Icons.event,
                  onTap: () async {
                    _closeSpeedDial();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateEventScreen(),
                      ),
                    );
                    if (result != null && result is Event) {
                      _discoverKey.currentState?.addNewEvent(result);
                      setState(() {
                        _currentIndex = 0;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildSpeedDialOption(
                  label: 'Bikin Post',
                  icon: Icons.post_add,
                  onTap: () {
                    _closeSpeedDial();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSpeedDialOption(
                  label: 'Kalender',
                  icon: Icons.calendar_today,
                  onTap: () {
                    _closeSpeedDial();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CalendarScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              // Main FAB
              FloatingActionButton(
                heroTag: "main_fab",
                onPressed: _toggleSpeedDial,
                backgroundColor: const Color(0xFF84994F),
                elevation: _isSpeedDialOpen ? 8 : 6,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isSpeedDialOpen ? 0.125 : 0,
                  child: Icon(
                    _isSpeedDialOpen ? Icons.close : Icons.add,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          isActive ? filledIcon : outlineIcon,
          color: isActive ? const Color(0xFF84994F) : Colors.grey[600],
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSpeedDialOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedScale(
      scale: _isSpeedDialOpen ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isSpeedDialOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF84994F),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}