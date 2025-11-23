// lib/screens/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prayer_time.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/prayer_service.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'home_tab.dart';
import 'prayers_tab.dart';
import 'notifications_tab.dart';
import 'more_tab.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/blackout_overlay.dart';

class HomePage extends StatefulWidget {
  final Future<void> Function(bool, {bool manual}) onToggleTheme;
  final bool darkMode;
  final AppUser currentUser;
  final void Function(AppUser?) onUserChanged;

  const HomePage({
    super.key,
    required this.onToggleTheme,
    required this.darkMode,
    required this.currentUser,
    required this.onUserChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _loading = true;

  // Location data
  LocationData? _locationData;

  // Prayer data
  PrayerSchedule? _prayerSchedule;
  bool _usingRemoteIqama = false;

  // Next prayer tracking
  Timer? _countdownTimer;
  PrayerTime? _nextPrayer;
  Duration _timeToNext = Duration.zero;

  // Notification data (new list-based)
  List<MosqueNotification> _notifications = [];
  bool _notifLoaded = false;

  // Firestore listeners
  StreamSubscription<Map<String, String>>? _iqamaSub;
  StreamSubscription<List<MosqueNotification>>? _notifSub;

  // Notification cleanup timer
  Timer? _cleanupTimer;

  // Full-screen overlays
  bool _showFullScreenCountdown = false;
  bool _blackoutActive = false;
  DateTime? _blackoutEndsAt;
  Timer? _blackoutTimer;

  // Permission helpers based on user role
  // Moderator AND Admin can now manage iqama times
  bool get canManageIqama =>
      widget.currentUser.isAdmin || widget.currentUser.isModerator;
  bool get canManageAnnouncements => widget.currentUser.canManageAnnouncements;
  bool get canManageUsers => widget.currentUser.canManageUsers;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _iqamaSub?.cancel();
    _notifSub?.cancel();
    _cleanupTimer?.cancel();
    _blackoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Load cached data first
    await _loadCachedData();

    // Start Firestore listeners
    _startIqamaListener();
    _startNotificationListener();

    // Fetch fresh data
    await _fetchPrayerTimes();

    // Start countdown
    _startCountdownLoop();

    // Start notification cleanup timer
    _startCleanupTimer();

    // Migrate legacy notification if exists
    _migrateLegacyData();
  }

  // ============ DATA LOADING ============

  Future<void> _loadCachedData() async {
    try {
      final cachedIqama = await StorageService.getIqamaTimes();
      final cachedNotifications = await StorageService.getNotifications();

      setState(() {
        if (cachedIqama.isNotEmpty) {
          _prayerSchedule = PrayerSchedule(
            timings: cachedIqama,
            iqamaMap: cachedIqama,
          );
        }
        _notifications = cachedNotifications;
        _notifLoaded = true;
      });
    } catch (e) {
      debugPrint('Failed to load cached data: $e');
    }
  }

  Future<void> _migrateLegacyData() async {
    try {
      // Migrate legacy local notification
      await StorageService.migrateLegacyNotification();

      // Migrate legacy Firestore notification
      await FirebaseService.migrateLegacyNotification();
    } catch (e) {
      debugPrint('Legacy migration failed (non-critical): $e');
    }
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() => _loading = true);

    try {
      // Get location
      final locationData = await LocationService.getCurrentLocation();

      // Fetch prayer times
      final schedule = await PrayerService.fetchByCoordinates(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );

      // Merge with cached iqama times if available
      final cachedIqama = await StorageService.getIqamaTimes();
      final mergedSchedule = PrayerSchedule(
        timings: schedule.timings,
        iqamaMap: cachedIqama.isNotEmpty ? cachedIqama : schedule.iqamaMap,
      );

      setState(() {
        _locationData = locationData;
        _prayerSchedule = mergedSchedule;
        _loading = false;
      });

      // Save to cache
      await StorageService.saveIqamaTimes(mergedSchedule.iqamaMap);

      // Apply theme based on sunset
      await _applyThemeBySunset();
    } catch (e) {
      setState(() => _loading = false);

      // Try fallback location
      await _tryFallbackLocation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load prayer times: $e')),
        );
      }
    }
  }

  Future<void> _tryFallbackLocation() async {
    try {
      // Try default location first
      final defaultLocation = await StorageService.getDefaultLocation();
      if (defaultLocation.isNotEmpty) {
        setState(() {
          _locationData = LocationData(
            latitude: 0,
            longitude: 0,
            city: defaultLocation,
            country: '',
          );
        });
        return;
      }

      // Try IP-based location
      final locationInfo = await LocationService.getLocationByIP();
      setState(() {
        _locationData = LocationData(
          latitude: 0,
          longitude: 0,
          city: locationInfo.city,
          country: locationInfo.country,
        );
      });
    } catch (e) {
      debugPrint('Fallback location failed: $e');
    }
  }

  // ============ FIRESTORE LISTENERS ============

  void _startIqamaListener() {
    try {
      _iqamaSub = FirebaseService.listenToIqamaTimes().listen(
        (iqamaMap) async {
          if (iqamaMap.isNotEmpty && _prayerSchedule != null) {
            setState(() {
              _prayerSchedule = PrayerSchedule(
                timings: _prayerSchedule!.timings,
                iqamaMap: iqamaMap,
              );
              _usingRemoteIqama = true;
            });
            await StorageService.saveIqamaTimes(iqamaMap);
          }
        },
        onError: (e) => debugPrint('Iqama listener error: $e'),
      );
    } catch (e) {
      debugPrint('Failed to start iqama listener: $e');
    }
  }

  void _startNotificationListener() {
    try {
      _notifSub = FirebaseService.listenToNotifications().listen(
        (notifications) async {
          setState(() {
            _notifications = notifications;
            _notifLoaded = true;
          });
          await StorageService.saveNotifications(notifications);

          // Check for high priority alerts and trigger vibration
          _checkForAlerts(notifications);
        },
        onError: (e) => debugPrint('Notification listener error: $e'),
      );
    } catch (e) {
      debugPrint('Failed to start notification listener: $e');
    }
  }

  void _checkForAlerts(List<MosqueNotification> notifications) {
    // Check if there are any new high-priority alerts
    final alerts = notifications
        .where((n) => n.isAlert && n.isHighPriority && n.shouldShow)
        .toList();

    if (alerts.isNotEmpty) {
      // Vibrate for alerts
      HapticFeedback.vibrate();
    }
  }

  // ============ NOTIFICATION CLEANUP ============

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      AppConstants.notificationCleanupInterval,
      (_) => _cleanupExpiredNotifications(),
    );

    // Also run cleanup immediately
    _cleanupExpiredNotifications();
  }

  Future<void> _cleanupExpiredNotifications() async {
    try {
      // Clean up local cache
      final localCleaned = await StorageService.cleanupExpiredNotifications();
      if (localCleaned > 0) {
        debugPrint('Cleaned up $localCleaned expired notifications from cache');
      }

      // Clean up Firestore (only if admin/moderator)
      if (canManageAnnouncements) {
        final remoteCleaned =
            await FirebaseService.cleanupExpiredNotifications();
        if (remoteCleaned > 0) {
          debugPrint(
              'Cleaned up $remoteCleaned expired notifications from Firestore');
        }
      }

      // Refresh local state
      final freshNotifications = await StorageService.getNotifications();
      if (mounted && freshNotifications.length != _notifications.length) {
        setState(() {
          _notifications = freshNotifications;
        });
      }
    } catch (e) {
      debugPrint('Notification cleanup failed: $e');
    }
  }

  // ============ COUNTDOWN & OVERLAYS ============

  void _startCountdownLoop() {
    _countdownTimer?.cancel();
    _updateNextPrayer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateNextPrayer();
    });
  }

  void _updateNextPrayer() {
    if (_prayerSchedule == null) return;

    final nextPrayer = _prayerSchedule!.getNextPrayer();
    final timeToNext = _prayerSchedule!.getTimeToNextPrayer();

    if (nextPrayer != null) {
      final remainingSeconds = timeToNext.inSeconds;

      // Check if we should show countdown overlay (60s before iqama)
      if (remainingSeconds <= 60 && remainingSeconds > 5 && !_blackoutActive) {
        if (!_showFullScreenCountdown) {
          setState(() => _showFullScreenCountdown = true);
        }
      } else if (remainingSeconds <= 5 && !_blackoutActive) {
        // Start blackout mode
        setState(() {
          _showFullScreenCountdown = false;
          _blackoutActive = true;
          _blackoutEndsAt = DateTime.now().add(AppConstants.blackoutDuration);
        });
        _startBlackoutTimer();
      } else if (remainingSeconds > 60 && _showFullScreenCountdown) {
        setState(() => _showFullScreenCountdown = false);
      }
    }

    // Check if blackout ended
    if (_blackoutActive &&
        _blackoutEndsAt != null &&
        DateTime.now().isAfter(_blackoutEndsAt!)) {
      setState(() {
        _blackoutActive = false;
        _blackoutEndsAt = null;
      });
    }

    if (mounted) {
      setState(() {
        _nextPrayer = nextPrayer;
        _timeToNext = timeToNext;
      });
    }
  }

  void _startBlackoutTimer() {
    _blackoutTimer?.cancel();
    final endsAt = _blackoutEndsAt;
    if (endsAt == null) return;

    final remaining = endsAt.difference(DateTime.now());
    if (remaining.isNegative) {
      setState(() {
        _blackoutActive = false;
        _blackoutEndsAt = null;
      });
      return;
    }

    _blackoutTimer = Timer(remaining, () {
      if (mounted) {
        setState(() {
          _blackoutActive = false;
          _blackoutEndsAt = null;
        });
      }
    });
  }

  // ============ THEME MANAGEMENT ============

  Future<void> _applyThemeBySunset() async {
    if (_prayerSchedule == null) return;

    try {
      final maghrib = _prayerSchedule!.getPrayerByName('Maghrib');
      final sunrise = _prayerSchedule!.getPrayerByName('Sunrise');

      if (maghrib == null || sunrise == null) return;

      final maghribTime = maghrib.getWaqtTime();
      final sunriseTime = sunrise.getWaqtTime();

      if (maghribTime == null || sunriseTime == null) return;

      final now = DateTime.now();
      final shouldDark = now.isAfter(maghribTime) || now.isBefore(sunriseTime);

      await widget.onToggleTheme(shouldDark, manual: false);
    } catch (e) {
      debugPrint('Failed to apply theme by sunset: $e');
    }
  }

  // ============ UI CALLBACKS ============

  Future<void> onRefresh() async {
    await _fetchPrayerTimes();
    await _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    try {
      final notifications = await FirebaseService.getNotifications();
      setState(() {
        _notifications = notifications;
      });
      await StorageService.saveNotifications(notifications);
    } catch (e) {
      debugPrint('Failed to refresh notifications: $e');
    }
  }

  void onIqamaUpdated(String prayerName, String newIqama) {
    if (_prayerSchedule == null) return;
    setState(() {
      _prayerSchedule = _prayerSchedule!.updateIqama(prayerName, newIqama);
    });
  }

  void onNotificationsUpdated(List<MosqueNotification> notifications) {
    setState(() {
      _notifications = notifications;
    });
  }

  void _navigateToNotificationsTab() {
    setState(() {
      _selectedIndex = 2; // Notifications tab index
    });
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: _loading && _prayerSchedule == null
                ? const Center(child: CircularProgressIndicator())
                : IndexedStack(
                    index: _selectedIndex,
                    children: [
                      HomeTab(
                        locationData: _locationData,
                        prayerSchedule: _prayerSchedule,
                        nextPrayer: _nextPrayer,
                        timeToNext: _timeToNext,
                        notifications: _notifications,
                        darkMode: widget.darkMode,
                        onRefresh: onRefresh,
                        currentUser: widget.currentUser,
                        onUserChanged: widget.onUserChanged,
                        onNotificationTap: _navigateToNotificationsTab,
                      ),
                      PrayersTab(
                        prayerSchedule: _prayerSchedule,
                        nextPrayer: _nextPrayer,
                        adminMode: canManageIqama, // Admin & Moderator can edit
                        onRefresh: onRefresh,
                        onIqamaUpdated: onIqamaUpdated,
                      ),
                      NotificationsTab(
                        notifications: _notifications,
                        notifLoaded: _notifLoaded,
                        adminMode: canManageAnnouncements, // Admin & Moderator
                        onNotificationsUpdated: onNotificationsUpdated,
                      ),
                      MoreTab(
                        locationData: _locationData,
                        usingRemoteIqama: _usingRemoteIqama,
                        currentUser: widget.currentUser,
                        darkMode: widget.darkMode,
                        onToggleTheme: widget.onToggleTheme,
                        onUserChanged: widget.onUserChanged,
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),

        // Full-screen countdown overlay
        if (_showFullScreenCountdown && !_blackoutActive && _nextPrayer != null)
          CountdownOverlay(
            prayerName: _nextPrayer!.name,
            timeRemaining: _timeToNext,
          ),

        // Blackout overlay
        if (_blackoutActive)
          BlackoutOverlay(
            endsAt: _blackoutEndsAt,
          ),
      ],
    );
  }

  Widget _buildBottomNav() {
    // Count active notifications for badge
    final activeCount = _notifications.activeOnly.length;
    final hasHighPriority = _notifications.highPriorityOnly.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text(activeCount.toString()),
              backgroundColor: hasHighPriority
                  ? AppColors.priorityHigh
                  : Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeCount > 0,
              label: Text(activeCount.toString()),
              backgroundColor: hasHighPriority
                  ? AppColors.priorityHigh
                  : Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.notifications),
            ),
            label: 'Notices',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
