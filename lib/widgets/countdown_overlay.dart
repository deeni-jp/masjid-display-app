// lib/widgets/countdown_overlay.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/design.dart';

/// Full-screen iqamah countdown shown in the final minute before iqamah
/// (design/screens/3 · Iqamah countdown).
class CountdownOverlay extends StatelessWidget {
  final String prayerName;
  final Duration timeRemaining;

  const CountdownOverlay({
    super.key,
    required this.prayerName,
    required this.timeRemaining,
  });

  static const Color _mintText = Color(0xFFD5EBDD);
  static const Color _mintMuted = Color(0xFF9CC7AE);

  @override
  Widget build(BuildContext context) {
    final remaining = timeRemaining.isNegative ? Duration.zero : timeRemaining;
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Material(
          color: DesignColors.greenDeep,
          child: LayoutBuilder(
            builder: (context, c) {
              // Scale against the 2000×1125 design, but let portrait phones
              // use more of their width.
              final s = (c.maxWidth / 1150).clamp(0.0, c.maxHeight / 1125);
              final now = DateTime.now();

              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RingsPainter(
                        center: const Offset(0.5, 0.5),
                        radii: const [0.445, 0.585],
                        color: Colors.white.withValues(alpha: 0.07),
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                  // Current time
                  Positioned(
                    left: 50 * s,
                    top: 50 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 34 * s,
                        vertical: 18 * s,
                      ),
                      decoration: BoxDecoration(
                        color: DesignColors.greenRaised,
                        borderRadius: BorderRadius.circular(20 * s),
                      ),
                      child: TimeWithPeriod(
                        time: now,
                        size: 46 * s,
                        color: DesignColors.goldBright,
                        periodScale: 0.5,
                      ),
                    ),
                  ),

                  // Masjid name
                  Positioned(
                    right: 50 * s,
                    top: 56 * s,
                    child: Text(
                      MasjidInfo.name,
                      style: DesignText.latin(
                        size: 32 * s,
                        weight: FontWeight.w700,
                        color: _mintText,
                        height: 1.1,
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 130 * s, 24, 0),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BilingualLabel(
                              english: prayerName,
                              arabic: Bilingual.prayerArabic(prayerName),
                              alignment: CrossAxisAlignment.center,
                              englishStyle: DesignText.latin(
                                size: 54 * s,
                                weight: FontWeight.w700,
                                color: _mintText,
                                height: 1.1,
                                features: const [],
                              ),
                              arabicStyle: DesignText.arabic(
                                size: 46 * s,
                                weight: FontWeight.w600,
                                color: _mintMuted,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 26 * s),
                            BilingualLabel(
                              english: 'Iqamah in',
                              arabic: 'الإقامة بعد',
                              alignment: CrossAxisAlignment.center,
                              englishStyle: DesignText.latin(
                                size: 70 * s,
                                weight: FontWeight.w800,
                                color: DesignColors.goldBright,
                                height: 1.1,
                                features: const [],
                              ),
                              arabicStyle: DesignText.arabic(
                                size: 54 * s,
                                weight: FontWeight.w700,
                                color: DesignColors.goldBright,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 20 * s),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _unit(s, minutes, 'minutes', 'دقائق'),
                                _colon(s),
                                _unit(s, seconds, 'seconds', 'ثانية'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _unit(double s, String value, String label, String labelAr) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder:
              (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
          child: Text(
            value,
            key: ValueKey(value),
            style: DesignText.latin(
              size: 360 * s,
              weight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        SizedBox(height: 30 * s),
        BilingualLabel(
          english: label,
          arabic: labelAr,
          alignment: CrossAxisAlignment.center,
          englishStyle: DesignText.latin(
            size: 34 * s,
            weight: FontWeight.w700,
            color: _mintText,
            height: 1.1,
            features: const [],
          ),
          arabicStyle: DesignText.arabic(
            size: 27 * s,
            color: _mintMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _colon(double s) {
    Widget dot() =>
        Container(width: 46 * s, height: 46 * s, color: DesignColors.gold);
    return Padding(
      padding: EdgeInsets.fromLTRB(46 * s, 105 * s, 46 * s, 0),
      child: Column(children: [dot(), SizedBox(height: 44 * s), dot()]),
    );
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
              colors: [AppColors.primaryGreenDark, AppColors.primaryGreen],
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
                    color: Colors.white.withValues(alpha: 0.2),
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
