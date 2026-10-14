// lib/screens/home_page.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_time.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/hijri_date.dart';
import '../models/prayer_windows.dart';
import '../models/theme_setting.dart';
import '../services/prayer_service.dart';
import '../services/hijri_calendar_service.dart';
import '../services/location_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/design.dart';
import 'home_tab.dart';
import 'prayers_tab.dart';
import 'notifications_tab.dart';
import 'more_tab.dart';
import 'qibla_tab.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/blackout_overlay.dart';
import '../widgets/prayer_started_overlay.dart';
import '../widgets/notification_card.dart';
import '../widgets/masjid_logo.dart';

class HomePage extends StatefulWidget {
  final ThemeSetting themeSetting;
  final Future<void> Function(ThemeSetting) onThemeSettingChanged;

  /// Reports night (sunset to sunrise) for the Auto theme
  final Future<void> Function(bool) onNightChanged;
  final bool darkMode;
  final AppUser currentUser;
  final void Function(AppUser?) onUserChanged;

  const HomePage({
    super.key,
    required this.themeSetting,
    required this.onThemeSettingChanged,
    required this.onNightChanged,
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
  bool _showLoadingOverlay = false;

  // Location data
  LocationData? _locationData;

  // Hijri calendar data
  HijriDate? _hijriDate;

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

  // Fires once at the next sunrise, sunset or midnight (see
  // _scheduleThemeEvents)
  Timer? _themeTimer;

  // Full-screen sequence around iqamah: countdown -> prayer time started
  // -> prayer in progress (see prayer_windows.dart).
  PrayerPhaseState? _prayerPhase;

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
    _themeTimer?.cancel();
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
      final cachedHijri = await HijriCalendarService.getCachedHijriDate();

      setState(() {
        if (cachedIqama.isNotEmpty) {
          _prayerSchedule = PrayerSchedule(
            timings: cachedIqama,
            iqamaMap: cachedIqama,
          );
        }
        _notifications = cachedNotifications;
        _notifLoaded = true;
        _hijriDate = cachedHijri;
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

  /// [silent] (the midnight refresh): no loading overlay, and on failure no
  /// error message or fallback location; the current data stays on screen.
  Future<void> _fetchPrayerTimes({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _showLoadingOverlay = true;
      });
    }

    try {
      // Get location
      final locationData = await LocationService.getCurrentLocation();

      // Fetch prayer times (Waqt times from API)
      final schedule = await PrayerService.fetchByCoordinates(
        latitude: locationData.latitude,
        longitude: locationData.longitude,
      );

      // Try to fetch iqama times from Firebase (source of truth)
      Map<String, String> iqamaMap = {};
      try {
        iqamaMap = await FirebaseService.getIqamaTimes();
        debugPrint('Fetched iqama from Firebase: ${iqamaMap.length} prayers');
      } catch (e) {
        debugPrint('Failed to fetch iqama from Firebase: $e');
      }

      // If DB is empty (first boot), use waqt times as initial iqama
      // Otherwise, use the fetched iqama times from DB
      final finalIqamaMap = iqamaMap.isNotEmpty ? iqamaMap : schedule.timings;

      final mergedSchedule = PrayerSchedule(
        timings: schedule.timings,
        iqamaMap: finalIqamaMap,
      );

      setState(() {
        _locationData = locationData;
        _prayerSchedule = mergedSchedule;
        _loading = false;
        _showLoadingOverlay = false;
      });

      // Save iqama times to cache
      await StorageService.saveIqamaTimes(finalIqamaMap);

      // Fetch Hijri date
      try {
        final hijriDate = await HijriCalendarService.getHijriDate();
        setState(() {
          _hijriDate = hijriDate;
        });
      } catch (e) {
        debugPrint('Failed to fetch Hijri date: $e');
        // Non-critical, continue with cached/null
      }

      // Day/night for the Auto theme, and the timer for the next change
      _scheduleThemeEvents();
    } catch (e) {
      if (silent) {
        debugPrint('Midnight prayer-time refresh failed: $e');
        // Keep the sunrise/sunset/midnight timer going with current times
        _scheduleThemeEvents();
        return;
      }

      setState(() {
        _loading = false;
        _showLoadingOverlay = false;
      });

      // Try fallback location
      await _tryFallbackLocation();

      // Keep the sunrise/sunset/midnight timer going with cached times
      _scheduleThemeEvents();

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
      _iqamaSub = FirebaseService.listenToIqamaTimes().listen((iqamaMap) async {
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
      }, onError: (e) => debugPrint('Iqama listener error: $e'));
    } catch (e) {
      debugPrint('Failed to start iqama listener: $e');
    }
  }

  void _startNotificationListener() {
    try {
      _notifSub = FirebaseService.listenToNotifications().listen((
        notifications,
      ) async {
        setState(() {
          _notifications = notifications;
          _notifLoaded = true;
        });
        await StorageService.saveNotifications(notifications);

        // Check for high priority alerts and trigger vibration
        _checkForAlerts(notifications);
      }, onError: (e) => debugPrint('Notification listener error: $e'));
    } catch (e) {
      debugPrint('Failed to start notification listener: $e');
    }
  }

  void _checkForAlerts(List<MosqueNotification> notifications) {
    // Check if there are any new high-priority alerts
    final alerts =
        notifications
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
            'Cleaned up $remoteCleaned expired notifications from Firestore',
          );
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

    final now = DateTime.now();
    final nextPrayer = _prayerSchedule!.getNextPrayer();
    final timeToNext = _prayerSchedule!.getTimeToNextPrayer();
    final prayerPhase = _prayerSchedule!.getPrayerPhase(now);

    if (mounted) {
      setState(() {
        _nextPrayer = nextPrayer;
        _timeToNext = timeToNext;
        _prayerPhase = prayerPhase;
      });
    }
  }

  // ============ THEME MANAGEMENT ============

  /// Reports day/night for the Auto theme, then sets one timer for the next
  /// change instead of polling: at sunrise/sunset it re-checks, at midnight
  /// it fetches the new day's prayer times (which calls this again).
  void _scheduleThemeEvents() {
    _themeTimer?.cancel();
    final schedule = _prayerSchedule;
    if (schedule == null || !mounted) return;

    DateTime? waqt(String name) =>
        schedule.getPrayerByName(name)?.getWaqtTime();
    final sunrise = waqt('Sunrise');
    final sunset = waqt('Sunset') ?? waqt('Maghrib');
    if (sunrise == null || sunset == null) return;

    final now = DateTime.now();
    widget.onNightChanged(isNightAt(now, sunrise: sunrise, sunset: sunset));

    final next = nextThemeEvent(now, sunrise: sunrise, sunset: sunset);
    final isMidnight = next.isAfter(sunset);
    // +1s so the timer lands just after the event, not a moment before it.
    _themeTimer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      isMidnight ? () => _fetchPrayerTimes(silent: true) : _scheduleThemeEvents,
    );
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

  void _navigateToNotificationsTab(MosqueNotification notification) {
    // First, switch to notifications tab
    setState(() {
      _selectedIndex =
          kIsWeb
              ? 2
              : 3; // Notifications tab index (2 on web, 3 on mobile after Qibla)
    });

    // Then show the detail sheet for the specific notification
    // Use post-frame callback to ensure tab switch completes first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationDetailSheet.show(
        context,
        notification,
        adminMode: widget.currentUser.isAdmin || widget.currentUser.isModerator,
        onEdit: () {
          // After editing, refresh notifications
          onRefresh();
        },
        onDelete: () {
          // After deleting, refresh notifications
          onRefresh();
        },
      );
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
            child:
                _loading && _prayerSchedule == null
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
                          hijriDate: _hijriDate,
                          onOpenSettings:
                              () => setState(
                                () => _selectedIndex = kIsWeb ? 3 : 4,
                              ),
                          onOpenNotices:
                              () => setState(
                                () => _selectedIndex = kIsWeb ? 2 : 3,
                              ),
                        ),
                        PrayersTab(
                          prayerSchedule: _prayerSchedule,
                          nextPrayer: _nextPrayer,
                          adminMode:
                              canManageIqama, // Admin & Moderator can edit
                          onRefresh: onRefresh,
                          onIqamaUpdated: onIqamaUpdated,
                        ),
                        if (!kIsWeb)
                          QiblaTab(
                            locationData: _locationData,
                            darkMode: widget.darkMode,
                            onRefresh: onRefresh,
                          ),
                        NotificationsTab(
                          notifications: _notifications,
                          notifLoaded: _notifLoaded,
                          adminMode:
                              canManageAnnouncements, // Admin & Moderator
                          onNotificationsUpdated: onNotificationsUpdated,
                        ),
                        MoreTab(
                          locationData: _locationData,
                          usingRemoteIqama: _usingRemoteIqama,
                          currentUser: widget.currentUser,
                          darkMode: widget.darkMode,
                          themeSetting: widget.themeSetting,
                          onThemeSettingChanged: widget.onThemeSettingChanged,
                          onUserChanged: widget.onUserChanged,
                        ),
                      ],
                    ),
          ),
          // The large display's home screen is full-bleed, without the nav.
          bottomNavigationBar:
              _selectedIndex == 0 && isDisplayLayout(context)
                  ? null
                  : _buildBottomNav(),
        ),

        // Loading overlay (shown during location fetch and data loading)
        if (_showLoadingOverlay) const _LoadingOverlay(),

        // Iqamah countdown -> prayer time started -> prayer in progress
        if (_prayerPhase != null && !_showLoadingOverlay)
          _buildPrayerPhaseOverlay(_prayerPhase!),
      ],
    );
  }

  Widget _buildPrayerPhaseOverlay(PrayerPhaseState state) {
    switch (state.phase) {
      case PrayerPhase.iqamahCountdown:
        return CountdownOverlay(
          prayerName: state.prayer.name,
          timeRemaining: state.remaining(DateTime.now()),
        );
      case PrayerPhase.prayerStarted:
        return PrayerStartedOverlay(prayer: state.prayer);
      case PrayerPhase.prayerInProgress:
        return BlackoutOverlay(endsAt: state.endsAt);
    }
  }

  Widget _buildBottomNav() {
    // Count active notifications for badge
    final activeCount = _notifications.activeOnly.length;
    final hasHighPriority = _notifications.highPriorityOnly.isNotEmpty;

    return _DesignNavBar(
      selectedIndex: _selectedIndex,
      darkMode: widget.darkMode,
      onSelected: (index) => setState(() => _selectedIndex = index),
      items: [
        const _NavItem(Icons.schedule_rounded, 'Times', 'الأوقات'),
        const _NavItem(Icons.mosque_outlined, 'Prayers', 'الصلوات'),
        if (!kIsWeb) const _NavItem(Icons.explore_outlined, 'Qibla', 'القبلة'),
        _NavItem(
          Icons.chat_bubble_outline_rounded,
          'Notices',
          'الإعلانات',
          badge: activeCount,
          badgeColor:
              hasHighPriority ? AppColors.priorityHigh : DesignColors.green,
        ),
        const _NavItem(Icons.settings_outlined, 'Settings', 'الإعدادات'),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String labelArabic;
  final int badge;
  final Color badgeColor;

  const _NavItem(
    this.icon,
    this.label,
    this.labelArabic, {
    this.badge = 0,
    this.badgeColor = DesignColors.green,
  });
}

/// Bottom navigation with bilingual labels (design/screens/6 · Mobile app).
class _DesignNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool darkMode;
  final ValueChanged<int> onSelected;

  const _DesignNavBar({
    required this.items,
    required this.selectedIndex,
    required this.darkMode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final background = darkMode ? const Color(0xFF11261D) : Colors.white;
    final border = darkMode ? const Color(0xFF1F3A2E) : DesignColors.border;
    final selected = darkMode ? const Color(0xFF8FD4B0) : DesignColors.green;
    final unselected =
        darkMode ? const Color(0xFF9DB5A9) : DesignColors.inkMuted;

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _buildItem(
                    items[i],
                    i == selectedIndex ? selected : unselected,
                    i == selectedIndex,
                    () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    _NavItem item,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Semantics(
        selected: isSelected,
        button: true,
        label: item.label,
        // Scales down rather than overflowing when the bar is squeezed
        // (e.g. a near-zero browser window, or very large text settings).
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  isLabelVisible: item.badge > 0,
                  label: Text(item.badge.toString()),
                  backgroundColor: item.badgeColor,
                  child: Icon(item.icon, color: color, size: 25),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignText.latin(
                    size: 12.5,
                    weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                    height: 1.1,
                    features: const [],
                  ),
                ),
                Text(
                  item.labelArabic,
                  maxLines: 1,
                  textDirection: TextDirection.rtl,
                  style: DesignText.arabic(
                    size: 10.5,
                    weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                    height: 1.3,
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

/// Modern loading overlay with animation
class _LoadingOverlay extends StatefulWidget {
  const _LoadingOverlay();

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation controller for the circular progress
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Shimmer controller for text
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryGreenDark.withValues(alpha: 0.96),
                AppColors.primaryGreen.withValues(alpha: 0.96),
                AppColors.primaryGreenLight.withValues(alpha: 0.96),
              ],
            ),
          ),
          child: Center(
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rotating circular progress with mosque icon
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating circular progress indicator
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * 3.14159,
                              child: SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withValues(alpha: 0.9),
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Mosque icon in center
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const MasjidLogo(size: 68),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading text with shimmer effect
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _shimmerAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              'Loading Prayer Times',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Getting your location...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
