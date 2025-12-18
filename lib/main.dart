import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'core/utils/app_logger.dart';
import 'core/observers/navigation_observer.dart';
import 'core/services/auth_service.dart';
import 'core/services/environment_service.dart';
import 'injection_container.dart' as di;
import 'presentation/pages/discover/discover_screen.dart';
import 'presentation/pages/home/home_screen.dart';
import 'presentation/pages/create_event/create_event_conversation.dart';
import 'presentation/bloc/events/events_bloc.dart';
import 'presentation/bloc/user/user_bloc.dart';
import 'presentation/bloc/user/user_event.dart';
import 'presentation/bloc/posts/posts_bloc.dart';
import 'presentation/bloc/posts/posts_event.dart';
import 'presentation/bloc/communities/communities_bloc.dart';
import 'presentation/bloc/communities/communities_event.dart';
import 'presentation/bloc/qna/qna_bloc.dart';
import 'presentation/bloc/tickets/tickets_bloc.dart';
import 'domain/entities/event.dart';
import 'presentation/pages/profile/profile_screen.dart';
import 'presentation/pages/community/new_community_screen.dart';
import 'presentation/pages/calendar/calendar_screen.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/auth/onboarding_screen.dart';
import 'presentation/pages/auth/login_screen.dart';
import 'presentation/pages/auth/complete_profile_screen.dart';
import 'presentation/pages/create_post/create_post_screen.dart';

// Global navigation key for navigating without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await EnvironmentService.initialize();

  // Initialize logger
  AppLogger().init();

  // Set status bar style - Light theme
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
        theme: ThemeData.light(),
        home: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFFF0055),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Inisialisasi App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF666666)),
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
        BlocProvider<EventsBloc>(create: (context) => di.sl<EventsBloc>()),
        BlocProvider<UserBloc>(
          create: (context) => di.sl<UserBloc>()..add(LoadUserProfile()),
        ),
        BlocProvider<PostsBloc>(create: (context) => di.sl<PostsBloc>()),
        BlocProvider<CommunitiesBloc>(
          create: (context) => di.sl<CommunitiesBloc>()..add(LoadCommunities()),
        ),
        BlocProvider<QnABloc>(create: (context) => di.sl<QnABloc>()),
      ],
      child: MaterialApp(
        title: 'flyerr',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [AppNavigationObserver()],
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
            bodyColor: const Color(0xFF000000),
            displayColor: const Color(0xFF000000),
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFBBC863),
            brightness: Brightness.light,
            background: const Color(0xFFFFFFFF),
            surface: const Color(0xFFFAFAFA),
            primary: const Color(0xFFBBC863),
          ),
          primaryColor: const Color(0xFFBBC863),
          scaffoldBackgroundColor: const Color(0xFFFFFFFF),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFFFFFFFF),
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFFBBC863)),
            titleTextStyle: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF000000),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFFAFAFA),
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFFFFFF),
            selectedItemColor: Color(0xFFBBC863),
            unselectedItemColor: Color(0xFF666666),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const MainNavigationWrapper(),
          '/login': (context) => const LoginScreen(),
          '/complete-profile': (context) => const CompleteProfileScreen(),
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
  int _homeTabIndex =
      0; // Track which tab is active in HomeScreen (0=Feed, 1=Events)
  final GlobalKey<DiscoverScreenState> _discoverKey =
      GlobalKey<DiscoverScreenState>();
  bool _isSpeedDialOpen = false;

  void _onHomeTabChanged(int tabIndex) {
    final oldTab = _homeTabIndex == 0 ? 'Feed' : 'Events';
    final newTab = tabIndex == 0 ? 'Feed' : 'Events';
    AppLogger().info('Home sub-tab changed: $oldTab -> $newTab');
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

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Discover';
      case 2:
        return 'Communities';
      case 3:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: const Color(0xFFFFFFFF),
              title: const Text(
                'Keluar dari App',
                style: TextStyle(color: Color(0xFF000000)),
              ),
              content: const Text(
                'Yakin mau keluar?',
                style: TextStyle(color: Color(0xFF666666)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(color: Color(0xFFBBC863)),
                  ),
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
            // Use IndexedStack to keep all pages alive and prevent rebuilds
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onTabChanged: _onHomeTabChanged,
                ), // Home with Feed/Events tabs
                DiscoverScreen(key: _discoverKey), // Redesigned Discover Page
                const NewCommunityScreen(),
                ProfileScreen(), // Removed const to allow refresh
              ],
            ),
            // Backdrop overlay when speed dial is open
            if (_isSpeedDialOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSpeedDial,
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
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
                  Flexible(
                    child: _buildNavItem(
                      LucideIcons.home,
                      LucideIcons.home,
                      'Beranda',
                      0,
                    ),
                  ),
                  Flexible(
                    child: _buildNavItem(
                      LucideIcons.compass,
                      LucideIcons.compass,
                      'Jelajah',
                      1,
                    ),
                  ),
                  Flexible(
                    child: _buildNavItem(
                      LucideIcons.users,
                      LucideIcons.users,
                      'Komunitas',
                      2,
                    ),
                  ),
                  Flexible(
                    child: _buildNavItem(
                      LucideIcons.user,
                      LucideIcons.user,
                      'Profil',
                      3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton:
            (_currentIndex == 0 && _homeTabIndex == 1) ||
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
                      icon: LucideIcons.calendar,
                      onTap: () async {
                        _closeSpeedDial();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateEventConversation(),
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
                      icon: LucideIcons.filePlus,
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
                      icon: LucideIcons.calendarDays,
                      onTap: () {
                        _closeSpeedDial();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (_) => di.sl<TicketsBloc>(),
                              child: const CalendarScreen(),
                            ),
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
                    backgroundColor: const Color(0xFFBBC863),
                    elevation: _isSpeedDialOpen ? 8 : 6,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isSpeedDialOpen ? 0.125 : 0,
                      child: Icon(
                        _isSpeedDialOpen ? LucideIcons.x : LucideIcons.plus,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData outlineIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () {
        AppLogger().info(
          'Tab changed: ${_getTabName(_currentIndex)} -> ${_getTabName(index)}',
        );

        // Reload feed posts when returning to Home tab (index 0)
        // This fixes bug where saved posts from profile pollute home feed
        if (index == 0 && _currentIndex != 0) {
          context.read<PostsBloc>().add(LoadPosts());
        }

        // Force reload current user profile when tapping Profile tab (index 3)
        // This fixes bug where visiting other user's profile pollutes navbar profile
        if (index == 3) {
          final authService = di.sl<AuthService>();
          final currentUserId = authService.userId;

          // Load current user profile and posts
          context.read<UserBloc>().add(LoadUserProfile());
          if (currentUserId != null) {
            context.read<UserBloc>().add(LoadUserPostsEvent(currentUserId));
          }
        }

        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              outlineIcon,
              color: isActive
                  ? const Color(0xFFBBC863)
                  : const Color(0xFF000000),
              size: 28,
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 3,
              width: 22,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFBBC863) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFBBC863),
                    width: 1.5,
                  ),
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
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFF000000), size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
