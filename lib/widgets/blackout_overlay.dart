// lib/widgets/blackout_overlay.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../utils/design.dart';

/// Full-screen black state while the congregation is praying
/// (design/screens/4 · Prayer in progress).
class BlackoutOverlay extends StatelessWidget {
  /// When the blackout ends. Kept for callers; not displayed.
  final DateTime? endsAt;

  const BlackoutOverlay({super.key, this.endsAt});

  static const Color _translationText = Color(0xFF8E9792);
  static const Color _footnote = Color(0xFF8A918D);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Material(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, c) {
              final s = (c.maxWidth / 1150).clamp(0.0, c.maxHeight / 1125);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOut,
                builder:
                    (context, v, child) => Opacity(opacity: v, child: child),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 1500 * s),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 156 * s,
                            height: 156 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF5A5F5C),
                                width: 2.5 * s,
                              ),
                            ),
                            child: Icon(
                              Icons.comments_disabled_outlined,
                              color: DesignColors.silentText,
                              size: 62 * s,
                            ),
                          ),
                          SizedBox(height: 60 * s),
                          Text(
                            'Please stay silent during prayer',
                            textAlign: TextAlign.center,
                            style: DesignText.latin(
                              size: 92 * s,
                              weight: FontWeight.w700,
                              color: DesignColors.silentText,
                              height: 1.15,
                              features: const [],
                            ),
                          ),
                          Text(
                            '礼拝中はお静かにお願いします',
                            textAlign: TextAlign.center,
                            style: DesignText.japanese(
                              size: 64 * s,
                              weight: FontWeight.w600,
                              color: _translationText,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 70 * s),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Phones silent · ',
                                  style: DesignText.latin(
                                    size: 36 * s,
                                    weight: FontWeight.w600,
                                    color: _footnote,
                                  ),
                                ),
                                TextSpan(
                                  text: '携帯電話はマナーモードに',
                                  style: DesignText.japanese(
                                    size: 32 * s,
                                    color: _footnote,
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
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Alternative blackout overlay with mosque silhouette
class MosqueBlackoutOverlay extends StatelessWidget {
  final DateTime? endsAt;
  final String? prayerName;

  const MosqueBlackoutOverlay({super.key, this.endsAt, this.prayerName});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Mosque Icon
                Icon(
                  Icons.mosque,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 24),

                // Prayer Name (if provided)
                if (prayerName != null && prayerName!.isNotEmpty)
                  Text(
                    prayerName!,
                    style: GoogleFonts.amiri(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 32),

                // Silent Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.volume_off,
                        size: 48,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Silent Mode',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prayer in progress',
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // End time at bottom
                if (endsAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      'Resumes at ${DateFormat('hh:mm a').format(endsAt!)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white30,
                        fontSize: 12,
                      ),
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

/// Simple text-only blackout
class SimpleBlackoutOverlay extends StatelessWidget {
  final DateTime? endsAt;

  const SimpleBlackoutOverlay({super.key, this.endsAt});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🤫', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  'Please silence your phone',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 18,
                  ),
                ),
                if (endsAt != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Until ${DateFormat('hh:mm a').format(endsAt!)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white30,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
