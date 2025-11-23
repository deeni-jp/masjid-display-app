// lib/screens/home_tab.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_time.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../widgets/notification_card.dart';
import '../widgets/news_ticker.dart';
import 'profile_screen.dart';

class HomeTab extends StatelessWidget {
  final LocationData? locationData;
  final PrayerSchedule? prayerSchedule;
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final List<MosqueNotification> notifications;
  final bool darkMode;
  final Future<void> Function() onRefresh;
  final AppUser currentUser;
  final void Function(AppUser?) onUserChanged;
  final VoidCallback? onNotificationTap;

  const HomeTab({
    super.key,
    required this.locationData,
    required this.prayerSchedule,
    required this.nextPrayer,
    required this.timeToNext,
    required this.notifications,
    required this.darkMode,
    required this.onRefresh,
    required this.currentUser,
    required this.onUserChanged,
    this.onNotificationTap,
  });

  // Get high priority notifications sorted by expiry
  List<MosqueNotification> get _highPriorityNotifications {
    return notifications.highPriorityOnly.sortedByExpiry;
  }

  // Get notifications for ticker (non-high priority)
  List<MosqueNotification> get _tickerNotifications {
    return notifications.excludingHighPriority;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main scrollable content
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  _buildNextPrayerCard(context),

                  // High priority notifications
                  if (_highPriorityNotifications.isNotEmpty)
                    _buildHighPrioritySection(context),

                  _buildQuickPrayerTimes(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),

        // News ticker at bottom (for non-high priority notifications)
        if (_tickerNotifications.isNotEmpty)
          NewsTicker(
            notifications: _tickerNotifications,
            onTap: onNotificationTap,
            darkMode: darkMode,
            rotationInterval: AppConstants.tickerRotationInterval,
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    const hijriDate =
        'Muharram 24, 1446 AH'; // TODO: Integrate Hijri calendar package

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: darkMode
              ? AppColors.headerGradientDark
              : AppColors.headerGradientLight,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppStyles.paddingLarge,
          AppStyles.paddingMedium,
          AppStyles.paddingLarge,
          AppStyles.paddingXLarge,
        ),
        child: Column(
          children: [
            // Profile Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _openProfileScreen(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                    child:
                        const Icon(Icons.person_outline, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Welcome Message - CENTERED
            Text(
              'Welcome',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              AppConstants.appName,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Calendar Card - CENTERED
            Container(
              padding: const EdgeInsets.all(AppStyles.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              ),
              child: Column(
                children: [
                  Icon(Icons.wb_sunny, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    hijriDate,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(now),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location - CENTERED
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  locationData?.formattedLocation ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          currentUser: currentUser,
          onUserChanged: onUserChanged,
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(BuildContext context) {
    final sunriseRaw = prayerSchedule?.getPrayerByName('Sunrise')?.waqt ?? '';
    final sunsetRaw = prayerSchedule?.getPrayerByName('Maghrib')?.waqt ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        AppStyles.paddingLarge,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: darkMode
                ? AppColors.nextPrayerGradientDark
                : AppColors.nextPrayerGradientLight,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingXLarge),
          child: Column(
            children: [
              // Prayer Name - CENTERED
              Text(
                nextPrayer?.name ?? 'Next Prayer',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: darkMode ? Colors.white : AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Salah will start in',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: darkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Countdown Timer - CENTERED with smooth animation
              _buildSmoothCountdown(context),

              const SizedBox(height: 24),

              // Sunrise & Sunset Row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: darkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSunTimeItem(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Sunrise',
                      time: PrayerTime.trimTime(sunriseRaw),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: darkMode ? Colors.white24 : Colors.black12,
                    ),
                    _buildSunTimeItem(
                      icon: Icons.wb_twilight,
                      label: 'Sunset',
                      time: PrayerTime.trimTime(sunsetRaw),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmoothCountdown(BuildContext context) {
    final hours = timeToNext.inHours;
    final minutes = timeToNext.inMinutes.remainder(60);
    final seconds = timeToNext.inSeconds.remainder(60);

    final textColor = darkMode ? Colors.white : AppColors.primaryGreen;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hours > 0) ...[
          _buildTimeUnit(hours.toString().padLeft(2, '0'), 'hrs', textColor),
          _buildTimeSeparator(textColor),
        ],
        _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'min', textColor),
        _buildTimeSeparator(textColor),
        _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'sec', textColor),
      ],
    );
  }

  Widget _buildTimeUnit(String value, String label, Color color) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: Text(
            value,
            key: ValueKey(value),
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: color.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSunTimeItem({
    required IconData icon,
    required String label,
    required String time,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: darkMode ? Colors.white70 : Colors.black54,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: darkMode ? Colors.white60 : Colors.black45,
              ),
            ),
            Text(
              time.isNotEmpty ? time : '--:--',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighPrioritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppStyles.paddingLarge,
            AppStyles.paddingLarge,
            AppStyles.paddingLarge,
            0,
          ),
          child: Row(
            children: [
              Icon(
                Icons.priority_high,
                color: AppColors.priorityHigh,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Important',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.priorityHigh,
                ),
              ),
              const Spacer(),
              if (_highPriorityNotifications.length > 1)
                Text(
                  '${_highPriorityNotifications.length} alerts',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),

        // Rotating high priority card
        RotatingHighPriorityCard(
          notifications: _highPriorityNotifications,
          onTap: onNotificationTap,
          darkMode: darkMode,
          rotationInterval: AppConstants.notificationRotationInterval,
        ),
      ],
    );
  }

  Widget _buildQuickPrayerTimes(BuildContext context) {
    if (prayerSchedule == null) return const SizedBox.shrink();

    final prayers = prayerSchedule!.getMainPrayers();

    return Padding(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prayer Times',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              boxShadow: AppStyles.cardShadowLight,
            ),
            child: Column(
              children: [
                _buildPrayerTimeHeader(context),
                const Divider(height: 1),
                ...prayers.map((prayer) {
                  return _buildCompactPrayerRow(context, prayer);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.paddingMedium,
        vertical: 12,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Prayer',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Waqt',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Iqama',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPrayerRow(BuildContext context, PrayerTime prayer) {
    final isNext = nextPrayer?.name == prayer.name;

    return Container(
      decoration: BoxDecoration(
        color: isNext
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingMedium,
          vertical: 14,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.getPrayerColor(prayer.name)
                          .withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppStyles.radiusSmall),
                    ),
                    child: Icon(
                      AppColors.getPrayerIcon(prayer.name),
                      size: 16,
                      color: AppColors.getPrayerColor(prayer.name),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    prayer.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                PrayerTime.trimTime(prayer.waqt),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                PrayerTime.trimTime(prayer.iqama),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
