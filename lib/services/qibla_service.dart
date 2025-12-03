// lib/services/qibla_service.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';

class QiblaService {
  // Kaaba coordinates (Mecca, Saudi Arabia)
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;

  /// Calculate Qibla direction from user coordinates
  /// Returns bearing in degrees (0-360) where 0 = North
  static double calculateQiblaDirection(double userLat, double userLon) {
    // Convert to radians
    final lat1 = _toRadians(userLat);
    final lat2 = _toRadians(_kaabaLatitude);
    final lonDiff = _toRadians(_kaabaLongitude - userLon);

    // Calculate bearing using spherical trigonometry
    final y = sin(lonDiff) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lonDiff);
    final bearing = atan2(y, x);

    // Convert to degrees and normalize to 0-360
    final degrees = _toDegrees(bearing);
    return (degrees + 360) % 360;
  }

  /// Get compass heading stream
  /// Returns device heading relative to North (0-360°)
  static Stream<CompassEvent>? getCompassStream() {
    return FlutterCompass.events;
  }

  /// Check if device has compass/magnetometer
  static Future<bool> hasCompassSensor() async {
    try {
      final events = await FlutterCompass.events?.first.timeout(
        const Duration(seconds: 2),
      );
      return events != null;
    } catch (e) {
      return false;
    }
  }

  /// Calculate relative angle between device heading and Qibla
  /// Returns angle to rotate compass needle (-180 to +180)
  static double getQiblaAngle({
    required double deviceHeading,
    required double qiblaDirection,
  }) {
    double angle = qiblaDirection - deviceHeading;

    // Normalize to -180 to +180 range
    if (angle > 180) {
      angle -= 360;
    } else if (angle < -180) {
      angle += 360;
    }

    return angle;
  }

  // Helper methods
  static double _toRadians(double degrees) => degrees * pi / 180;
  static double _toDegrees(double radians) => radians * 180 / pi;
}

/// Custom exception for Qibla service errors
class QiblaServiceException implements Exception {
  final String message;

  QiblaServiceException(this.message);

  @override
  String toString() => 'QiblaServiceException: $message';
}
