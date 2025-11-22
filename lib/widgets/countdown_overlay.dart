// lib/widgets/countdown_overlay.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class CountdownOverlay extends StatelessWidget {
  final String prayerName;
  final Duration timeRemaining;

  const CountdownOverlay({
    super.key,
    required this.prayerName,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black.withOpacity(0.85),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: const EdgeInsets.all(AppStyles.paddingLarge),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusXLarge),
                ),
                elevation: 20,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mosque Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppColors.getPrayerIcon(prayerName),
                          size: 40,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Prayer Name
                      Text(
                        prayerName,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Iqama in',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Countdown Display
                      _buildCountdownDisplay(),
                      const SizedBox(height: 24),

                      // Progress Bar
                      _buildProgressBar(),
                      const SizedBox(height: 24),

                      // Message
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppStyles.radiusMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Please prepare — line up quietly',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay() {
    final seconds = timeRemaining.inSeconds;
    final displaySeconds = seconds.clamp(0, 60);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        _formatTime(timeRemaining),
        key: ValueKey(displaySeconds),
        style: GoogleFonts.poppins(
          fontSize: 72,
          fontWeight: FontWeight.w700,
          color: Colors.black,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    // Progress from 60 seconds to 0
    final totalSeconds = 60;
    final remainingSeconds = timeRemaining.inSeconds.clamp(0, totalSeconds);
    final progress = 1 - (remainingSeconds / totalSeconds);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(progress),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '60s',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            Text(
              'Iqama',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    // Green -> Yellow -> Red as time decreases
    if (progress < 0.5) {
      return AppColors.primaryGreen;
    } else if (progress < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatTime(Duration d) {
    final seconds = d.inSeconds;
    if (seconds <= 0) return '0';
    if (seconds < 60) return '${seconds}s';

    final minutes = d.inMinutes;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }
}

/// Minimal countdown overlay variant
class MinimalCountdownOverlay extends StatelessWidget {
  final String prayerName;
  final Duration timeRemaining;

  const MinimalCountdownOverlay({
    super.key,
    required this.prayerName,
    required this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGreenDark,
                AppColors.primaryGreen,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prayer Icon
                Icon(
                  AppColors.getPrayerIcon(prayerName),
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),

                // Prayer Name
                Text(
                  prayerName,
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Iqama in',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),

                // Countdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
                  ),
                  child: Text(
                    _formatSeconds(timeRemaining.inSeconds),
                    style: GoogleFonts.poppins(
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Message
                Text(
                  'Please prepare for prayer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0';
    return seconds.toString();
  }
}
