// lib/widgets/next_prayer_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer_time.dart';
import '../utils/constants.dart';

class NextPrayerCard extends StatelessWidget {
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final PrayerSchedule? prayerSchedule;
  final bool darkMode;

  const NextPrayerCard({
    super.key,
    required this.nextPrayer,
    required this.timeToNext,
    required this.prayerSchedule,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Get sunrise and sunset times
    final sunrise = prayerSchedule?.getPrayerByName('Sunrise');
    final maghrib = prayerSchedule?.getPrayerByName('Maghrib');

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
            colors:
                darkMode
                    ? AppColors.nextPrayerGradientDark
                    : AppColors.nextPrayerGradientLight,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.paddingXLarge),
          child: Column(
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextPrayer?.name ?? 'Next Prayer',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color:
                                darkMode
                                    ? Colors.white
                                    : AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Salah will start in',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: darkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPrayerIcon(context),
                ],
              ),
              const SizedBox(height: 24),

              // Countdown Timer
              _buildCountdown(context),

              const SizedBox(height: 24),

              // Sunrise & Sunset Row
              _buildSunTimesRow(context, sunrise, maghrib),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerIcon(BuildContext context) {
    final prayerColor =
        nextPrayer != null
            ? AppColors.getPrayerColor(nextPrayer!.name)
            : AppColors.primaryGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            darkMode
                ? Colors.white.withValues(alpha: 0.1)
                : prayerColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        nextPrayer != null
            ? AppColors.getPrayerIcon(nextPrayer!.name)
            : Icons.access_time,
        size: 32,
        color: darkMode ? Colors.white : prayerColor,
      ),
    );
  }

  Widget _buildCountdown(BuildContext context) {
    final formattedTime = _formatDuration(timeToNext);

    return Column(
      children: [
        // Main countdown display
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            formattedTime,
            key: ValueKey(formattedTime),
            style: GoogleFonts.poppins(
              fontSize: 52,
              fontWeight: FontWeight.w700,
              color: darkMode ? Colors.white : AppColors.primaryGreen,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Time labels
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (timeToNext.inHours > 0) ...[
              _buildTimeLabel('hours'),
              const SizedBox(width: 24),
            ],
            _buildTimeLabel('min'),
            const SizedBox(width: 24),
            _buildTimeLabel('sec'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        color: darkMode ? Colors.white54 : Colors.black45,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSunTimesRow(
    BuildContext context,
    PrayerTime? sunrise,
    PrayerTime? maghrib,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            darkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSunTimeItem(
            icon: Icons.wb_sunny_outlined,
            label: 'Sunrise',
            time: sunrise != null ? PrayerTime.trimTime(sunrise.waqt) : '--:--',
          ),
          Container(
            width: 1,
            height: 30,
            color: darkMode ? Colors.white24 : Colors.black12,
          ),
          _buildSunTimeItem(
            icon: Icons.wb_twilight,
            label: 'Sunset',
            time: maghrib != null ? PrayerTime.trimTime(maghrib.waqt) : '--:--',
          ),
        ],
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
        Icon(icon, size: 20, color: darkMode ? Colors.white70 : Colors.black54),
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
              time,
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

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// Circular countdown variant
class CircularCountdownCard extends StatelessWidget {
  final PrayerTime? nextPrayer;
  final Duration timeToNext;
  final bool darkMode;

  const CircularCountdownCard({
    super.key,
    required this.nextPrayer,
    required this.timeToNext,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (max 6 hours)
    const maxSeconds = 6 * 60 * 60;
    final currentSeconds = timeToNext.inSeconds.clamp(0, maxSeconds);
    final progress = 1 - (currentSeconds / maxSeconds);

    return Padding(
      padding: const EdgeInsets.all(AppStyles.paddingLarge),
      child: Container(
        padding: const EdgeInsets.all(AppStyles.paddingXLarge),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
          boxShadow: AppStyles.cardShadow,
        ),
        child: Column(
          children: [
            Text(
              nextPrayer?.name ?? 'Next Prayer',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(timeToNext),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'remaining',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
