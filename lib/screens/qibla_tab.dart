// lib/screens/qibla_tab.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../services/qibla_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class QiblaTab extends StatefulWidget {
  final LocationData? locationData;
  final bool darkMode;
  final Future<void> Function() onRefresh;

  const QiblaTab({
    super.key,
    required this.locationData,
    required this.darkMode,
    required this.onRefresh,
  });

  @override
  State<QiblaTab> createState() => _QiblaTabState();
}

class _QiblaTabState extends State<QiblaTab> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double? _deviceHeading;
  double? _qiblaDirection;
  bool _hasCompass = true;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initQibla() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if device has compass
      final hasCompass = await QiblaService.hasCompassSensor();
      if (!hasCompass) {
        setState(() {
          _hasCompass = false;
          _isLoading = false;
          _error = 'Your device does not have a compass sensor';
        });
        return;
      }

      // Calculate Qibla direction from user location
      if (widget.locationData != null) {
        _qiblaDirection = QiblaService.calculateQiblaDirection(
          widget.locationData!.latitude,
          widget.locationData!.longitude,
        );
      } else {
        throw QiblaServiceException('Location not available');
      }

      // Listen to compass events
      _startCompass();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize compass: $e';
        _isLoading = false;
      });
    }
  }

  void _startCompass() {
    _compassSubscription = QiblaService.getCompassStream()?.listen(
      (CompassEvent event) {
        if (event.heading != null) {
          setState(() {
            _deviceHeading = event.heading;
          });
        }
      },
      onError: (error) {
        setState(() {
          _error = 'Compass error: $error';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh();
        await _initQibla();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 180,
          padding: const EdgeInsets.all(AppStyles.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildCompassBody(),
              const SizedBox(height: 40),
              _buildLocationInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Qibla Direction',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: widget.darkMode ? Colors.white : AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Face towards Mecca',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCompassBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null || !_hasCompass) {
      return _buildErrorState();
    }

    if (_deviceHeading == null || _qiblaDirection == null) {
      return _buildCalibrationMessage();
    }

    // Calculate angle for compass needle
    final qiblaAngle = QiblaService.getQiblaAngle(
      deviceHeading: _deviceHeading!,
      qiblaDirection: _qiblaDirection!,
    );

    return _buildCompass(qiblaAngle, _deviceHeading!);
  }

  Widget _buildCompass(double qiblaAngle, double deviceHeading) {
    final isAligned = qiblaAngle.abs() < 5;

    return Column(
      children: [
        // Simple compass circle
        Card(
          elevation: 4,
          shape: const CircleBorder(),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.darkMode ? Colors.grey.shade900 : Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating compass rose (N/S/E/W) - rotates to show true directions
                Transform.rotate(
                  angle: -deviceHeading * pi / 180,
                  child: _buildSimpleCardinals(),
                ),

                // Qibla needle (simplified) - rotates to point to Qibla
                Transform.rotate(
                  angle: qiblaAngle * pi / 180,
                  child: _buildSimpleNeedle(),
                ),

                // Center dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned ? Colors.green : AppColors.secondaryGold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Status card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  isAligned ? Icons.check_circle : Icons.navigation,
                  color: isAligned ? Colors.green : AppColors.primaryGreen,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  qiblaAngle.abs() < 1
                      ? 'Perfectly Aligned'
                      : '${qiblaAngle.abs().toStringAsFixed(1)}° ${qiblaAngle >= 0 ? 'Right' : 'Left'}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAligned ? 'Ready to pray' : 'Rotate your device',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleCardinals() {
    return Stack(
      children: [
        // North (top) - red
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Text(
            'N',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        // South (bottom) - gray
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Text(
            'S',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        // East (right) - gray
        Positioned(
          right: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              'E',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        // West (left) - gray
        Positioned(
          left: 20,
          top: 0,
          bottom: 0,
          child: Center(
            child: Text(
              'W',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleNeedle() {
    return CustomPaint(
      size: const Size(6, 100),
      painter: _SimpleNeedlePainter(
        color: AppColors.secondaryGold,
        darkMode: widget.darkMode,
      ),
    );
  }

  Widget _buildCalibrationMessage() {
    return Column(
      children: [
        Icon(
          Icons.screen_rotation_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'Calibrating compass...',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Move your device in a figure-8 pattern',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.red.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          _error ?? 'Compass not available',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _initQibla,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    if (widget.locationData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.darkMode
            ? AppColors.primaryGreenDark.withValues(alpha: 0.3)
            : AppColors.primaryGreenLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                widget.locationData!.formattedLocation,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (_qiblaDirection != null) ...[
            const SizedBox(height: 8),
            Text(
              'Qibla: ${_qiblaDirection!.toStringAsFixed(1)}° from North',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter for Qibla needle (simplified two-sided needle)
class _SimpleNeedlePainter extends CustomPainter {
  final Color color;
  final bool darkMode;

  _SimpleNeedlePainter({required this.color, required this.darkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Gold side (pointing to Qibla)
    final goldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final goldPath = Path();
    goldPath.moveTo(centerX, 0); // Top point
    goldPath.lineTo(0, size.height * 0.4); // Left
    goldPath.lineTo(centerX, size.height * 0.35); // Center notch
    goldPath.lineTo(size.width, size.height * 0.4); // Right
    goldPath.close();

    canvas.drawPath(goldPath, goldPaint);

    // Gray side (opposite)
    final grayPaint = Paint()
      ..color = darkMode ? Colors.grey.shade700 : Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final grayPath = Path();
    grayPath.moveTo(centerX, size.height); // Bottom point
    grayPath.lineTo(0, size.height * 0.6); // Left
    grayPath.lineTo(centerX, size.height * 0.65); // Center notch
    grayPath.lineTo(size.width, size.height * 0.6); // Right
    grayPath.close();

    canvas.drawPath(grayPath, grayPaint);

    // Outline
    canvas.drawPath(
        goldPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    canvas.drawPath(
        grayPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
