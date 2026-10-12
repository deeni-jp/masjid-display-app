// lib/widgets/prohibited_time_overlay.dart
//
// Full-screen alert on the masjid display during times when prayer is not
// permitted (design/screens/5 · Prohibited-time alert).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/hijri_date.dart';
import '../models/prayer_windows.dart';
import '../utils/design.dart';

class ProhibitedTimeOverlay extends StatelessWidget {
  final ProhibitedWindow window;
  final HijriDate? hijriDate;
  final VoidCallback? onDismiss;

  const ProhibitedTimeOverlay({
    super.key,
    required this.window,
    this.hijriDate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final (clock, period) = DesignTime.split(now, seconds: true);
    final hijriAr = Bilingual.hijriArabic(hijriDate);

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Material(
          color: DesignColors.cream,
          child: LayoutBuilder(
            builder: (context, c) {
              final s = (c.maxWidth / 1150).clamp(0.0, c.maxHeight / 1125);

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40 * s,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clock
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: clock,
                                style: DesignText.latin(
                                  size: 150 * s,
                                  weight: FontWeight.w800,
                                  color: DesignColors.red,
                                  height: 1.1,
                                ),
                              ),
                              TextSpan(
                                text: '  $period',
                                style: DesignText.latin(
                                  size: 50 * s,
                                  weight: FontWeight.w700,
                                  color: DesignColors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18 * s),

                        // Dates
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(now),
                              style: DesignText.latin(
                                size: 32 * s,
                                weight: FontWeight.w600,
                                color: DesignColors.red,
                              ),
                            ),
                            if (hijriAr.isNotEmpty) ...[
                              Container(
                                width: 3 * s,
                                height: 30 * s,
                                margin: EdgeInsets.symmetric(
                                  horizontal: 30 * s,
                                ),
                                color: DesignColors.redSoft,
                              ),
                              Text(
                                hijriAr,
                                textDirection: TextDirection.rtl,
                                style: DesignText.arabic(
                                  size: 30 * s,
                                  color: DesignColors.red,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 22 * s),

                        // Which window
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              window.name,
                              style: DesignText.latin(
                                size: 46 * s,
                                weight: FontWeight.w700,
                                color: DesignColors.red,
                                features: const [],
                              ),
                            ),
                            SizedBox(width: 24 * s),
                            Text(
                              Bilingual.prayerArabic(window.name),
                              textDirection: TextDirection.rtl,
                              style: DesignText.arabic(
                                size: 44 * s,
                                weight: FontWeight.w600,
                                color: DesignColors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40 * s),

                        // Banner
                        Container(
                          width: 1690 * s,
                          padding: EdgeInsets.symmetric(vertical: 40 * s),
                          decoration: BoxDecoration(
                            color: DesignColors.red,
                            borderRadius: BorderRadius.circular(50 * s),
                          ),
                          child: BilingualLabel(
                            english: 'Prayer is not permitted now',
                            arabic: 'وقت النهي عن الصلاة',
                            alignment: CrossAxisAlignment.center,
                            englishStyle: DesignText.latin(
                              size: 100 * s,
                              weight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                              features: const [],
                            ),
                            arabicStyle: DesignText.arabic(
                              size: 78 * s,
                              weight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: 40 * s),

                        // Remaining
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Remaining',
                              style: DesignText.latin(
                                size: 46 * s,
                                weight: FontWeight.w700,
                                color: DesignColors.red,
                                features: const [],
                              ),
                            ),
                            SizedBox(width: 30 * s),
                            Text(
                              'المتبقي',
                              textDirection: TextDirection.rtl,
                              style: DesignText.arabic(
                                size: 40 * s,
                                weight: FontWeight.w600,
                                color: DesignColors.red,
                              ),
                            ),
                            SizedBox(width: 30 * s),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 42 * s,
                                vertical: 10 * s,
                              ),
                              decoration: BoxDecoration(
                                color: DesignColors.red,
                                borderRadius: BorderRadius.circular(24 * s),
                              ),
                              child: Text(
                                DesignTime.hms(window.remaining(now)),
                                style: DesignText.latin(
                                  size: 84 * s,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40 * s),

                        // Warning
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: DesignColors.red,
                              size: 62 * s,
                            ),
                            SizedBox(width: 22 * s),
                            Text(
                              'Do not offer prayer during this time',
                              style: DesignText.latin(
                                size: 40 * s,
                                weight: FontWeight.w700,
                                color: DesignColors.red,
                                features: const [],
                              ),
                            ),
                            SizedBox(width: 24 * s),
                            Text(
                              'لا تُصَلِّ في هذا الوقت',
                              textDirection: TextDirection.rtl,
                              style: DesignText.arabic(
                                size: 36 * s,
                                color: DesignColors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
