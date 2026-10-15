// lib/utils/design.dart
//
// Design tokens and small shared building blocks for the masjid display
// and mobile UI (see design/screens).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/hijri_date.dart';
import 'constants.dart';

/// Colour palette taken from the design mockups.
class DesignColors {
  // Greens
  static const Color green = Color(0xFF0F5C46);
  static const Color greenDeep = Color(0xFF0B3D2F);
  static const Color greenRaised = Color(0xFF15503F);
  static const Color mint = Color(0xFFDDEEE4);
  static const Color mintSoft = Color(0xFFE6F1EA);

  // Neutrals
  static const Color background = Color(0xFFEFF5F1);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFD5E4DB);
  static const Color divider = Color(0xFFE4EDE7);
  static const Color ink = Color(0xFF12352A);
  static const Color inkMuted = Color(0xFF4D6B5F);
  static const Color inkFaint = Color(0xFF8CA59A);

  // Gold accents
  static const Color gold = Color(0xFFC9A24A);
  static const Color goldBright = Color(0xFFE8C46A);
  static const Color goldText = Color(0xFF8A6A12);
  static const Color goldSoft = Color(0xFFF6EBCB);

  // Prohibited-time alert
  static const Color red = Color(0xFFBF2420);
  static const Color redSoft = Color(0xFFE2A3A0);
  static const Color cream = Color(0xFFFDF6EA);

  // Prayer-in-progress
  static const Color silentText = Color(0xFFB7BFBB);
}

/// Typography: Manrope for Latin text, Noto Sans Arabic for Arabic.
class DesignText {
  static TextStyle latin({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color color = DesignColors.ink,
    double? height,
    double? letterSpacing,
    List<FontFeature>? features,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: features ?? const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle arabic({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = DesignColors.inkMuted,
    double? height,
  }) {
    return GoogleFonts.notoSansArabic(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle japanese({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = DesignColors.inkMuted,
    double? height,
  }) {
    return GoogleFonts.notoSansJp(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}

/// Arabic strings and number/time formatting helpers.
class Bilingual {
  static const Map<String, String> prayerNames = {
    'Fajr': 'الفجر',
    'Sunrise': 'الشروق',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
    'Jumuah': 'الجمعة',
    'Sunset': 'الغروب',
    'Zenith': 'الزوال',
  };

  static String prayerArabic(String name) => prayerNames[name] ?? '';

  static const _arabicDigits = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  /// Converts Western digits to Arabic-Indic digits.
  static String digits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final d = int.tryParse(ch);
      buffer.write(d != null ? _arabicDigits[d] : ch);
    }
    return buffer.toString();
  }

  /// "12:30 PM" -> "١٢:٣٠ م"
  static String timeArabic(DateTime time) {
    final suffix = time.hour < 12 ? 'ص' : 'م';
    return '${digits(DateFormat('h:mm').format(time))} $suffix';
  }

  /// "29 Rabi' II 1448"
  static String hijriEnglish(HijriDate? h) =>
      h == null ? '' : '${h.day} ${h.monthNameEnglish} ${h.year}';

  /// "٢٩ ربيع الآخر ١٤٤٨"
  static String hijriArabic(HijriDate? h) =>
      h == null ? '' : digits('${h.day} ${h.monthName} ${h.year}');
}

/// Clock/time formatting used across the display screens.
class DesignTime {
  /// Splits a time into the main part and the AM/PM period,
  /// e.g. (`11:52:08`, `AM`).
  static (String, String) split(DateTime t, {bool seconds = false}) {
    final main = DateFormat(seconds ? 'h:mm:ss' : 'h:mm').format(t);
    return (main, DateFormat('a').format(t));
  }

  static String hms(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// Masjid name shown on the display.
class MasjidInfo {
  static String get name => AppConstants.appName;
}

/// Light and dark colour sets for the home screens (display and mobile).
/// The display and mobile mockups are light; dark mode follows the app's
/// theme setting (which switches automatically after sunset).
class DesignPalette {
  final Color background;
  final Color surface;
  final Color border;
  final Color divider;

  /// Brand-green headings (masjid name, notice titles, clock).
  final Color title;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;

  /// Clock card and settings button backgrounds.
  final Color accentSurface;
  final Color accentSurfaceSoft;

  /// Next-prayer row on the mobile list.
  final Color highlight;
  final Color highlightText;

  /// Notice-type chip.
  final Color chip;
  final Color chipText;

  final Color dotInactive;

  const DesignPalette({
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.title,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accentSurface,
    required this.accentSurfaceSoft,
    required this.highlight,
    required this.highlightText,
    required this.chip,
    required this.chipText,
    required this.dotInactive,
  });

  static const light = DesignPalette(
    background: DesignColors.background,
    surface: DesignColors.surface,
    border: DesignColors.border,
    divider: DesignColors.divider,
    title: DesignColors.green,
    ink: DesignColors.ink,
    inkMuted: DesignColors.inkMuted,
    inkFaint: DesignColors.inkFaint,
    accentSurface: DesignColors.mint,
    accentSurfaceSoft: DesignColors.mintSoft,
    highlight: DesignColors.mint,
    highlightText: DesignColors.green,
    chip: DesignColors.goldSoft,
    chipText: DesignColors.goldText,
    dotInactive: DesignColors.mint,
  );

  static const dark = DesignPalette(
    background: Color(0xFF0A1A14),
    surface: Color(0xFF11261D),
    border: Color(0xFF1F3A2E),
    divider: Color(0xFF1A3328),
    title: Color(0xFFBFE3CF),
    ink: Color(0xFFE6F0EA),
    inkMuted: Color(0xFF9DB5A9),
    inkFaint: Color(0xFF5E7A6D),
    accentSurface: Color(0xFF143326),
    accentSurfaceSoft: Color(0xFF173A2D),
    highlight: Color(0xFF173A2D),
    highlightText: Color(0xFF8FD4B0),
    chip: Color(0xFF3A3018),
    chipText: DesignColors.goldBright,
    dotInactive: Color(0xFF1F3A2E),
  );

  static DesignPalette of(bool darkMode) => darkMode ? dark : light;
}

/// Outlined sunset glyph: half sun on the horizon with a downward arrow.
/// Material Icons has no sunset icon, so this is drawn to match them.
class SunsetIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SunsetIcon({super.key, this.size = 24, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SunsetPainter(color)),
    );
  }
}

class _SunsetPainter extends CustomPainter {
  final Color color;

  const _SunsetPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 24×24 grid like Material icons.
    canvas.scale(size.width / 24, size.height / 24);
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    const center = Offset(12, 19);
    // Horizon
    canvas.drawLine(const Offset(2, 19), const Offset(22, 19), paint);
    // Half sun
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 5),
      math.pi,
      math.pi,
      false,
      paint,
    );
    // Rays
    for (final deg in const [180.0, 225.0, 315.0, 360.0]) {
      final a = deg * math.pi / 180;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + dir * 7.5, center + dir * 9.5, paint);
    }
    // Downward arrow
    canvas.drawLine(const Offset(12, 2.5), const Offset(12, 9.5), paint);
    canvas.drawPath(
      Path()
        ..moveTo(9.2, 6.8)
        ..lineTo(12, 9.6)
        ..lineTo(14.8, 6.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SunsetPainter old) => old.color != color;
}

/// A time with a smaller AM/PM suffix, e.g. "4:52 AM".
class TimeWithPeriod extends StatelessWidget {
  final DateTime? time;
  final String fallback;
  final double size;
  final Color color;
  final FontWeight weight;
  final bool seconds;
  final double periodScale;

  const TimeWithPeriod({
    super.key,
    required this.time,
    this.fallback = '--:--',
    this.size = 20,
    this.color = DesignColors.ink,
    this.weight = FontWeight.w700,
    this.seconds = false,
    this.periodScale = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    if (time == null) {
      return Text(
        fallback,
        style: DesignText.latin(size: size, weight: weight, color: color),
      );
    }
    final (main, period) = DesignTime.split(time!, seconds: seconds);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: main,
            style: DesignText.latin(size: size, weight: weight, color: color),
          ),
          TextSpan(
            text: ' $period',
            style: DesignText.latin(
              size: size * periodScale,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}

/// English label with Arabic beneath it.
class BilingualLabel extends StatelessWidget {
  final String english;
  final String arabic;
  final TextStyle englishStyle;
  final TextStyle arabicStyle;
  final CrossAxisAlignment alignment;
  final double gap;

  const BilingualLabel({
    super.key,
    required this.english,
    required this.arabic,
    required this.englishStyle,
    required this.arabicStyle,
    this.alignment = CrossAxisAlignment.start,
    this.gap = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(english, style: englishStyle),
        if (gap > 0) SizedBox(height: gap),
        if (arabic.isNotEmpty)
          Text(arabic, style: arabicStyle, textDirection: TextDirection.rtl),
      ],
    );
  }
}

/// Faint concentric rings used as background decoration.
class RingsPainter extends CustomPainter {
  final Offset center;
  final List<double> radii;
  final Color color;
  final double strokeWidth;

  const RingsPainter({
    required this.center,
    required this.radii,
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    final c = Offset(center.dx * size.width, center.dy * size.height);
    for (final r in radii) {
      canvas.drawCircle(c, r * size.shortestSide, paint);
    }
  }

  @override
  bool shouldRepaint(RingsPainter old) =>
      old.center != center || old.radii != radii || old.color != color;
}

/// Width at which the app switches to the large masjid-display layout.
const double kDisplayBreakpoint = 900;

bool isDisplayLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDisplayBreakpoint;
