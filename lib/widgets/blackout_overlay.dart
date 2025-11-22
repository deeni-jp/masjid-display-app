// lib/widgets/blackout_overlay.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class BlackoutOverlay extends StatelessWidget {
  final DateTime? endsAt;

  const BlackoutOverlay({
    super.key,
    this.endsAt,
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
                Color(0xFF000000),
                Color(0xFF0A0A0A),
                Color(0xFF000000),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Silent Icon with glow effect
                    _buildSilentIcon(),
                    const SizedBox(height: 32),

                    // Main Message
                    _buildMainMessage(),
                    const SizedBox(height: 16),

                    // Sub Message
                    Text(
                      'The screen will resume automatically',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // End Time
                    if (endsAt != null) _buildEndTime(),

                    const SizedBox(height: 40),

                    // Decorative line
                    _buildDecorativeLine(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSilentIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
        ),
        child: const Icon(
          Icons.volume_off_rounded,
          size: 56,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildMainMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Arabic-style text using Amiri font
          Text(
            'Please put your phone',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          Text(
            'in silent mode',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndTime() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            color: Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Ends at ${DateFormat('hh:mm a').format(endsAt!)}',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 1,
          color: Colors.white12,
        ),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 1,
          color: Colors.white12,
        ),
      ],
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
                  color: Colors.white.withOpacity(0.15),
                ),
                const SizedBox(height: 24),

                // Prayer Name (if provided)
                if (prayerName != null && prayerName!.isNotEmpty)
                  Text(
                    prayerName!,
                    style: GoogleFonts.amiri(
                      color: Colors.white.withOpacity(0.6),
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
