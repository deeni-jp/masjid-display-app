// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/storage_service.dart';
import 'services/user_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_page.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local storage
  await StorageService.init();

  // Preload Google fonts
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.poppins(),
      GoogleFonts.poppins(fontWeight: FontWeight.w600),
      GoogleFonts.poppins(fontWeight: FontWeight.w700),
      GoogleFonts.amiri(),
      GoogleFonts.amiri(fontWeight: FontWeight.w700),
    ]).timeout(const Duration(seconds: 5));
  } catch (_) {
    // If font fetch is slow or fails, continue with system fallback
  }

  runApp(const PrayerApp());
}

class PrayerApp extends StatefulWidget {
  const PrayerApp({super.key});

  @override
  State<PrayerApp> createState() => _PrayerAppState();
}

class _PrayerAppState extends State<PrayerApp> {
  bool _darkMode = false;
  bool _themeManualOverride = false;

  @override
  void initState() {
    super.initState();
    _loadThemePref();
  }

  Future<void> _loadThemePref() async {
    final darkMode = await StorageService.getDarkMode();
    final manual = await StorageService.getDarkModeManual();

    if (mounted) {
      setState(() {
        _darkMode = darkMode;
        _themeManualOverride = manual;
      });
    }
  }

  Future<void> _setDarkMode(bool value, {bool manual = true}) async {
    if (!manual && _themeManualOverride) {
      return;
    }

    await StorageService.setDarkMode(value);

    if (manual) {
      await StorageService.setDarkModeManual(true);
      _themeManualOverride = true;
    }

    if (mounted) {
      setState(() => _darkMode = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Light Theme
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.secondaryGold,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
      ),
    );

    // Dark Theme
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: Brightness.dark,
        primary: AppColors.primaryGreenLight,
        secondary: AppColors.secondaryGold,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
      ),
    );

    return MaterialApp(
      title: AppConstants.appName,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(
        onToggleTheme: _setDarkMode,
        darkMode: _darkMode,
      ),
    );
  }
}

/// Wrapper that handles authentication state
class AuthWrapper extends StatefulWidget {
  final Future<void> Function(bool, {bool manual}) onToggleTheme;
  final bool darkMode;

  const AuthWrapper({
    super.key,
    required this.onToggleTheme,
    required this.darkMode,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if user is already signed in
      final authUser = FirebaseAuth.instance.currentUser;

      if (authUser != null) {
        // Get user data from Firestore
        final user = await UserService.getCurrentUser();

        if (user != null) {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Auth check failed: $e');
      setState(() {
        _currentUser = null;
        _isLoading = false;
      });
    }
  }

  void _onAuthSuccess(AppUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _onSignOut() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mosque,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Show auth screen if not signed in
    if (_currentUser == null) {
      return AuthScreen(
        onAuthSuccess: _onAuthSuccess,
      );
    }

    // Show home page if signed in
    return HomePageWrapper(
      currentUser: _currentUser!,
      onToggleTheme: widget.onToggleTheme,
      darkMode: widget.darkMode,
      onSignOut: _onSignOut,
      onUserChanged: (user) {
        if (user == null) {
          _onSignOut();
        } else {
          setState(() => _currentUser = user);
        }
      },
    );
  }
}

/// Wrapper for HomePage that passes user data
class HomePageWrapper extends StatelessWidget {
  final AppUser currentUser;
  final Future<void> Function(bool, {bool manual}) onToggleTheme;
  final bool darkMode;
  final VoidCallback onSignOut;
  final void Function(AppUser?) onUserChanged;

  const HomePageWrapper({
    super.key,
    required this.currentUser,
    required this.onToggleTheme,
    required this.darkMode,
    required this.onSignOut,
    required this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return HomePage(
      onToggleTheme: onToggleTheme,
      darkMode: darkMode,
      currentUser: currentUser,
      onUserChanged: onUserChanged,
    );
  }
}
