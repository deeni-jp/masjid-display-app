// lib/widgets/prayer_started_overlay.dart
//
// Full-screen "Time for prayer" state shown for the first 30 seconds after
// iqamah, between the iqamah countdown and the prayer-in-progress screen
// (design/screens/2 · Prayer time started). Wide screens use the design's
// landscape layout; phones get a stacked portrait version.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/prayer_time.dart';
import '../utils/design.dart';

class PrayerStartedOverlay extends StatelessWidget {
  final PrayerTime prayer;

  const PrayerStartedOverlay({super.key, required this.prayer});

  static const _tips = [
    ('Straighten the rows', 'سَوُّوا الصفوف'),
    ('Fill the gaps', 'سُدُّوا الفُرَج'),
    ('Silence your phone', 'أغلق هاتفك أو اجعله صامتًا'),
    ('Repeat after the iqamah', 'ردِّد كلمات الإقامة'),
  ];

  @override
  Widget build(BuildContext context) {
    final iqamah = prayer.getIqamaTime();

    return Positioned.fill(
      child: AbsorbPointer(
        child: Material(
          color: DesignColors.background,
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < c.maxHeight) return _buildPortrait(c, iqamah);

              final s = (c.maxWidth / 2000).clamp(0.0, c.maxHeight / 1125);
              final split = c.maxHeight * 0.555;

              return Stack(
                children: [
                  // Deep green lower band.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: split,
                    bottom: 0,
                    child: const ColoredBox(color: DesignColors.greenDeep),
                  ),
                  // Rings: faint on the light half, bright on the dark half.
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _BandClipper(top: 0, bottom: split),
                      child: _rings(DesignColors.divider),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _BandClipper(top: split, bottom: c.maxHeight),
                      child: _rings(Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),

                  // Etiquette icons
                  Positioned(
                    left: 50 * s,
                    top: 50 * s,
                    child: Column(
                      children: [
                        _etiquetteIcon(s, Icons.mobile_off),
                        SizedBox(height: 24 * s),
                        _etiquetteIcon(s, Icons.comments_disabled_outlined),
                      ],
                    ),
                  ),

                  // Iqamah time
                  Positioned(
                    right: 50 * s,
                    top: 50 * s,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Iqamah at',
                          style: DesignText.latin(
                            size: 25 * s,
                            weight: FontWeight.w600,
                            color: DesignColors.inkMuted,
                          ),
                        ),
                        Text(
                          iqamah != null
                              ? DateFormat('h:mm a').format(iqamah)
                              : PrayerTime.trimTime(prayer.iqama),
                          style: DesignText.latin(
                            size: 58 * s,
                            weight: FontWeight.w800,
                            color: DesignColors.green,
                          ),
                        ),
                        if (iqamah != null)
                          Text(
                            'الإقامة ${Bilingual.timeArabic(iqamah)}',
                            textDirection: TextDirection.rtl,
                            style: DesignText.arabic(size: 24 * s),
                          ),
                      ],
                    ),
                  ),

                  // Prayer name
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 60 * s,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'TIME FOR PRAYER',
                              style: DesignText.latin(
                                size: 31 * s,
                                weight: FontWeight.w700,
                                color: DesignColors.goldText,
                                letterSpacing: 2,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24 * s),
                              child: Container(
                                width: 10 * s,
                                height: 10 * s,
                                decoration: const BoxDecoration(
                                  color: DesignColors.gold,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Text(
                              'حان وقت الصلاة',
                              textDirection: TextDirection.rtl,
                              style: DesignText.arabic(
                                size: 31 * s,
                                color: DesignColors.goldText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          prayer.name,
                          style: DesignText.latin(
                            size: 205 * s,
                            weight: FontWeight.w800,
                            color: DesignColors.green,
                            height: 1.05,
                            features: const [],
                          ),
                        ),
                        Text(
                          Bilingual.prayerArabic(prayer.name),
                          textDirection: TextDirection.rtl,
                          style: DesignText.arabic(
                            size: 135 * s,
                            weight: FontWeight.w600,
                            color: const Color(0xFF2E5E4A),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Etiquette tips
                  Positioned(
                    left: 88 * s,
                    right: 88 * s,
                    bottom: 140 * s,
                    child: Column(
                      children: [
                        for (var row = 0; row < 2; row++)
                          Padding(
                            padding: EdgeInsets.only(
                              top: row == 0 ? 0 : 50 * s,
                            ),
                            child: Row(
                              children: [
                                for (var col = 0; col < 2; col++)
                                  Expanded(
                                    child: _tip(
                                      s,
                                      row * 2 + col + 1,
                                      _tips[row * 2 + col],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
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

  Widget _rings(
    Color color, {
    Offset center = const Offset(0.5, 0.2),
    List<double> radii = const [0.44, 0.52],
  }) {
    return CustomPaint(
      painter: RingsPainter(
        center: center,
        radii: radii,
        color: color,
        strokeWidth: 2,
      ),
    );
  }

  /// Phone layout: light top half with the prayer name, green bottom half
  /// with the etiquette tips in one column.
  Widget _buildPortrait(BoxConstraints c, DateTime? iqamah) {
    // Sized for a ~390pt-wide phone; grows a little on portrait tablets.
    final u = (c.maxWidth / 390).clamp(0.8, 1.5);
    final split = c.maxHeight * 0.54;
    // Rings dip just into the green band, staying clear of the tips.
    const ringRadii = [0.52, 0.62];
    final outerRadius = ringRadii.last * c.maxWidth;
    final ringCenter = Offset(
      0.5,
      (split + 36 * u - outerRadius) / c.maxHeight,
    );

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: split,
          bottom: 0,
          child: const ColoredBox(color: DesignColors.greenDeep),
        ),
        Positioned.fill(
          child: ClipRect(
            clipper: _BandClipper(top: 0, bottom: split),
            child: _rings(
              DesignColors.divider,
              center: ringCenter,
              radii: ringRadii,
            ),
          ),
        ),
        Positioned.fill(
          child: ClipRect(
            clipper: _BandClipper(top: split, bottom: c.maxHeight),
            child: _rings(
              Colors.white.withValues(alpha: 0.85),
              center: ringCenter,
              radii: ringRadii,
            ),
          ),
        ),
        Column(
          children: [
            // Top: icons, iqamah time, prayer name
            SizedBox(
              height: split,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20 * u, 16 * u, 20 * u, 12 * u),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _etiquetteIcon(44 * u / 104, Icons.mobile_off),
                          SizedBox(width: 10 * u),
                          _etiquetteIcon(
                            44 * u / 104,
                            Icons.comments_disabled_outlined,
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Iqamah at',
                                style: DesignText.latin(
                                  size: 12 * u,
                                  weight: FontWeight.w600,
                                  color: DesignColors.inkMuted,
                                ),
                              ),
                              Text(
                                iqamah != null
                                    ? DateFormat('h:mm a').format(iqamah)
                                    : PrayerTime.trimTime(prayer.iqama),
                                style: DesignText.latin(
                                  size: 24 * u,
                                  weight: FontWeight.w800,
                                  color: DesignColors.green,
                                ),
                              ),
                              if (iqamah != null)
                                Text(
                                  'الإقامة ${Bilingual.timeArabic(iqamah)}',
                                  textDirection: TextDirection.rtl,
                                  style: DesignText.arabic(size: 12 * u),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'TIME FOR PRAYER',
                                      style: DesignText.latin(
                                        size: 14 * u,
                                        weight: FontWeight.w700,
                                        color: DesignColors.goldText,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10 * u,
                                      ),
                                      child: Container(
                                        width: 6 * u,
                                        height: 6 * u,
                                        decoration: const BoxDecoration(
                                          color: DesignColors.gold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'حان وقت الصلاة',
                                      textDirection: TextDirection.rtl,
                                      style: DesignText.arabic(
                                        size: 14 * u,
                                        color: DesignColors.goldText,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  prayer.name,
                                  style: DesignText.latin(
                                    size: 76 * u,
                                    weight: FontWeight.w800,
                                    color: DesignColors.green,
                                    height: 1.1,
                                    features: const [],
                                  ),
                                ),
                                Text(
                                  Bilingual.prayerArabic(prayer.name),
                                  textDirection: TextDirection.rtl,
                                  style: DesignText.arabic(
                                    size: 52 * u,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF2E5E4A),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom: etiquette tips
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24 * u, 20 * u, 24 * u, 20 * u),
                  child: Center(
                    // Shrinks to fit short screens. The tips' rows need a
                    // bounded width, so cap it to the available width.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: c.maxWidth - 48 * u,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < _tips.length; i++)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: i == 0 ? 0 : 16 * u,
                                ),
                                // Scale so the English line is 18pt at u = 1.
                                child: _tip(18 * u / 42, i + 1, _tips[i]),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _etiquetteIcon(double s, IconData icon) {
    return Container(
      width: 104 * s,
      height: 104 * s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: DesignColors.red, width: 2.5 * s),
      ),
      child: Icon(icon, color: DesignColors.red, size: 46 * s),
    );
  }

  Widget _tip(double s, int number, (String, String) tip) {
    return Row(
      children: [
        Container(
          width: 68 * s,
          height: 68 * s,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: DesignColors.gold,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: DesignText.latin(
              size: 30 * s,
              weight: FontWeight.w800,
              color: DesignColors.greenDeep,
            ),
          ),
        ),
        SizedBox(width: 30 * s),
        Flexible(
          child: BilingualLabel(
            english: tip.$1,
            arabic: tip.$2,
            englishStyle: DesignText.latin(
              size: 42 * s,
              weight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
              features: const [],
            ),
            arabicStyle: DesignText.arabic(
              size: 30 * s,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _BandClipper extends CustomClipper<Rect> {
  final double top;
  final double bottom;

  const _BandClipper({required this.top, required this.bottom});

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, top, size.width, bottom);

  @override
  bool shouldReclip(_BandClipper old) => old.top != top || old.bottom != bottom;
}
