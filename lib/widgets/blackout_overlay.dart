// lib/widgets/blackout_overlay.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class BlackoutOverlay extends StatefulWidget {
  final DateTime? endsAt;

  const BlackoutOverlay({
    super.key,
    this.endsAt,
  });

  @override
  State<BlackoutOverlay> createState() => _BlackoutOverlayState();
}

class _BlackoutOverlayState extends State<BlackoutOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            color: Colors.black,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mosque icon with breathing animation and glow
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, double fadeValue, child) {
                            return AnimatedBuilder(
                              animation: _breathAnimation,
                              builder: (context, breathChild) {
                                return Transform.scale(
                                  scale: fadeValue * _breathAnimation.value,
                                  child: Opacity(
                                    opacity: fadeValue,
                                    child: Container(
                                      padding: const EdgeInsets.all(36),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primaryGreen
                                                .withValues(alpha: 0.3),
                                            blurRadius: 60,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                        gradient: RadialGradient(
                                          colors: [
                                            AppColors.primaryGreen
                                                .withValues(alpha: 0.2),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.mosque_outlined,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 56),

                        // Main message with staggered animation
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                'Prayer Time',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.volume_off_rounded,
                                      color: Colors.white70,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Keep your phone silent',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (widget.endsAt != null) ...[
                          const SizedBox(height: 56),
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1200),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_outlined,
                                    color: Colors.white60,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Resumes at ${DateFormat('h:mm a').format(widget.endsAt!)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
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

  const MosqueBlackoutOverlay({
    super.key,
    this.endsAt,
    this.prayerName,
  });

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

  const SimpleBlackoutOverlay({
    super.key,
    this.endsAt,
  });

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
                Text(
                  '🤫',
                  style: TextStyle(fontSize: 64),
                ),
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
