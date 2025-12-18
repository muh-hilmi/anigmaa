import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../injection_container.dart' as di;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'Menyiapkan...';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Show splash for at least 1.5 seconds for better UX
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authService = di.sl<AuthService>();

    // FAST PATH: Check if user already has valid tokens
    if (await authService.hasValidToken) {
      setState(() {
        _statusText = 'Selamat datang kembali!';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
      return;
    }

    // SLOW PATH: Try silent Google sign-in (auto-login)
    setState(() {
      _statusText = 'Mengecek akun...';
    });

    try {
      final googleAuthService = di.sl<GoogleAuthService>();
      final googleAccount = await googleAuthService.signInSilently();

      if (googleAccount != null) {
        // Silent sign-in succeeded, authenticate with backend
        setState(() {
          _statusText = 'Login otomatis...';
        });

        final idToken = await googleAuthService.getIdToken();

        if (idToken != null) {
          final authDataSource = di.sl<AuthRemoteDataSource>();
          final authResponse = await authDataSource.loginWithGoogle(idToken);

          await authService.saveAuthData(
            userId: authResponse.user.id,
            email: authResponse.user.email ?? '',
            name: authResponse.user.name,
            accessToken: authResponse.accessToken,
            refreshToken: authResponse.refreshToken,
          );

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }
    } catch (e) {
      // Silent sign-in failed, this is normal
      // User will need to login manually
    }

    // NO AUTH: Route based on onboarding status
    if (!mounted) return;

    String route;
    if (authService.hasSeenOnboarding) {
      // User has seen onboarding, go to login
      route = '/login';
    } else {
      // First time user, show onboarding
      route = '/onboarding';
    }

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFBBC863),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.event,
                color: Color(0xff000000),
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            // App Name
            const Text(
              'flyerr',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF000000),
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cari acara seru di sekitar lo 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xff0000000),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 48),
            // Loading Indicator
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBBC863),),
              ),
            ),
            const SizedBox(height: 16),
            // Status Text
            Text(
              _statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
