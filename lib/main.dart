// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'models/text_size.dart';
import 'models/theme_setting.dart';
import 'models/user_model.dart';
import 'services/storage_service.dart';
import 'services/user_service.dart';
import 'services/push_notification_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_page.dart';
import 'utils/constants.dart';
import 'utils/env_config.dart';
import 'widgets/masjid_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  await EnvConfig.initialize();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Attest that requests come from this app (Firebase App Check)
  await _activateAppCheck();

  // Initialize local storage
  await StorageService.init();

  runApp(const PrayerApp());
}

/// Turns on Firebase App Check, which attaches a token to Firebase requests
/// proving they come from this app (not a script). It's in monitoring mode:
/// Firebase only *records* missing/invalid tokens until enforcement is turned
/// on in the Firebase Console (see README → App Check). Failures here must
/// never stop the app.
Future<void> _activateAppCheck() async {
  try {
    if (kIsWeb) {
      final siteKey = EnvConfig.appCheckWebSiteKey;
      if (siteKey.isEmpty) {
        debugPrint('App Check: no APP_CHECK_WEB_SITE_KEY in .env; skipped');
        return;
      }
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(siteKey),
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        // Debug builds use the debug provider: its token is printed in the
        // log and must be registered in Firebase Console → App Check.
        providerAndroid:
            kDebugMode
                ? const AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
        providerApple:
            kDebugMode
                ? const AppleDebugProvider()
                : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    }
  } catch (e) {
    debugPrint('App Check activation failed (app continues): $e');
  }
}

class PrayerApp extends StatefulWidget {
  const PrayerApp({super.key});

  @override
  State<PrayerApp> createState() => _PrayerAppState();
}

class _PrayerAppState extends State<PrayerApp> {
  ThemeSetting _themeSetting = ThemeSetting.auto;

  /// Night (sunset to sunrise), reported by the home page; used in Auto
  bool _isNight = false;

  bool get _darkMode =>
      _themeSetting == ThemeSetting.dark ||
      (_themeSetting == ThemeSetting.auto && _isNight);

  @override
  void initState() {
    super.initState();
    _loadThemePref();
  }

  TextSize _textSize = TextSize.normal;

  Future<void> _loadThemePref() async {
    final setting = await StorageService.getThemeSetting();
    final isNight = await StorageService.getDarkMode();
    var textSize = await StorageService.getTextSize();

    // The masjid display opens the app with ?textSize=<choice from setup>.
    if (kIsWeb) {
      final requested = Uri.base.queryParameters['textSize'];
      final fromSetup = textSizeFromSetup(
        requested: requested,
        lastApplied: await StorageService.getTextSizeSetup(),
      );
      if (fromSetup != null) {
        textSize = fromSetup;
        await StorageService.setTextSize(fromSetup);
        await StorageService.setTextSizeSetup(requested!);
      }
    }

    if (mounted) {
      setState(() {
        _themeSetting = setting;
        _isNight = isNight;
        _textSize = textSize;
      });
    }
  }

  Future<void> _setTextSize(TextSize value) async {
    await StorageService.setTextSize(value);
    if (mounted) {
      setState(() => _textSize = value);
    }
  }

  Future<void> _setThemeSetting(ThemeSetting value) async {
    await StorageService.setThemeSetting(value);
    if (mounted) {
      setState(() => _themeSetting = value);
    }
  }

  Future<void> _setIsNight(bool value) async {
    if (value == _isNight) return;
    await StorageService.setDarkMode(value);
    if (mounted) {
      setState(() => _isNight = value);
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
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
      // Text size setting, on top of the device's own font size.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final deviceScale = media.textScaler.scale(14) / 14;
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(deviceScale * _textSize.factor),
          ),
          child: child!,
        );
      },
      home: AuthWrapper(
        themeSetting: _themeSetting,
        onThemeSettingChanged: _setThemeSetting,
        textSize: _textSize,
        onTextSizeChanged: _setTextSize,
        onNightChanged: _setIsNight,
        darkMode: _darkMode,
      ),
    );
  }
}

/// Wrapper that handles authentication state
class AuthWrapper extends StatefulWidget {
  final ThemeSetting themeSetting;
  final Future<void> Function(ThemeSetting) onThemeSettingChanged;
  final TextSize textSize;
  final Future<void> Function(TextSize) onTextSizeChanged;
  final Future<void> Function(bool) onNightChanged;
  final bool darkMode;

  const AuthWrapper({
    super.key,
    required this.themeSetting,
    required this.onThemeSettingChanged,
    required this.textSize,
    required this.onTextSizeChanged,
    required this.onNightChanged,
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
          // Initialize push notifications after successful authentication
          await _initializePushNotifications();

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

  Future<void> _initializePushNotifications() async {
    // Web push isn't set up (it needs a service worker and VAPID key), so
    // don't ask browsers for notification permission. Web users see notices
    // in the app itself.
    if (kIsWeb) return;

    try {
      final pushService = PushNotificationService();
      await pushService.initialize();

      // Subscribe to the mosque-wide notifications topic
      await pushService.subscribeToTopic('mosque_notifications');

      debugPrint('Push notifications initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  void _onAuthSuccess(AppUser user) async {
    // Initialize push notifications after successful login
    await _initializePushNotifications();

    setState(() {
      _currentUser = user;
    });
  }

  void _onSignOut() async {
    // Clean up push notification token on sign out
    if (!kIsWeb) {
      try {
        final pushService = PushNotificationService();
        await pushService.unsubscribeFromTopic('mosque_notifications');
        await pushService.deleteToken();
      } catch (e) {
        debugPrint('Failed to clean up push notifications: $e');
      }
    }

    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MasjidLogo(size: 110),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // Show auth screen if not signed in
    if (_currentUser == null) {
      return AuthScreen(onAuthSuccess: _onAuthSuccess);
    }

    // Show home page if signed in
    return HomePageWrapper(
      currentUser: _currentUser!,
      themeSetting: widget.themeSetting,
      onThemeSettingChanged: widget.onThemeSettingChanged,
      textSize: widget.textSize,
      onTextSizeChanged: widget.onTextSizeChanged,
      onNightChanged: widget.onNightChanged,
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
  final ThemeSetting themeSetting;
  final Future<void> Function(ThemeSetting) onThemeSettingChanged;
  final TextSize textSize;
  final Future<void> Function(TextSize) onTextSizeChanged;
  final Future<void> Function(bool) onNightChanged;
  final bool darkMode;
  final VoidCallback onSignOut;
  final void Function(AppUser?) onUserChanged;

  const HomePageWrapper({
    super.key,
    required this.currentUser,
    required this.themeSetting,
    required this.onThemeSettingChanged,
    required this.textSize,
    required this.onTextSizeChanged,
    required this.onNightChanged,
    required this.darkMode,
    required this.onSignOut,
    required this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return HomePage(
      themeSetting: themeSetting,
      onThemeSettingChanged: onThemeSettingChanged,
      textSize: textSize,
      onTextSizeChanged: onTextSizeChanged,
      onNightChanged: onNightChanged,
      darkMode: darkMode,
      currentUser: currentUser,
      onUserChanged: onUserChanged,
    );
  }
}
