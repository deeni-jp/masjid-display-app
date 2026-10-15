// lib/services/location_service.dart
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../utils/env_config.dart';

class LocationService {
  // Default location (normally the masjid's): DEFAULT_* in .env
  static String get defaultLocation => '$defaultCity, $defaultCountry';
  static double get defaultLatitude => EnvConfig.defaultLatitude;
  static double get defaultLongitude => EnvConfig.defaultLongitude;
  static String get defaultCity => EnvConfig.defaultCity;
  static String get defaultCountry => EnvConfig.defaultCountry;

  /// Get current device location
  static Future<LocationData> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceException('Location services are disabled');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationServiceException('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationServiceException(
          'Location permission permanently denied. Please enable in settings.',
        );
      }

      // Get position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      // Try to reverse geocode
      String city = 'Unknown';
      String country = '';

      try {
        final locationInfo = await reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        city = locationInfo.city;
        country = locationInfo.country;
      } catch (_) {
        // Geocoding failed, but we still have coordinates
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
      );
    } catch (e) {
      // If any error occurs (permission denied, service disabled, etc.),
      // return the default location
      debugPrint(
        'Location error: $e. Using default location: $defaultLocation',
      );
      return getDefaultLocation();
    }
  }

  /// Get the default location (DEFAULT_* in .env)
  /// Use this when location permission is denied or location services are disabled
  static LocationData getDefaultLocation() {
    return LocationData(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      city: defaultCity,
      country: defaultCountry,
      isDefault: true,
    );
  }

  /// Get current location with explicit fallback handling
  /// Returns a tuple indicating if default location was used
  static Future<LocationResult> getCurrentLocationWithFallback() async {
    try {
      final location = await getCurrentLocation();
      return LocationResult(data: location, usedDefault: location.isDefault);
    } catch (e) {
      debugPrint('Failed to get location: $e. Using default.');
      return LocationResult(data: getDefaultLocation(), usedDefault: true);
    }
  }

  /// Reverse geocode coordinates to city name
  static Future<LocationInfo> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // Try native geocoding first
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final country = place.country ?? '';

        if (city.isNotEmpty || country.isNotEmpty) {
          return LocationInfo(
            city: city.isNotEmpty ? city : 'Unknown',
            country: country,
          );
        }
      }
    } catch (_) {
      // Fall through to Nominatim
    }

    // Fallback to Nominatim (OpenStreetMap)
    try {
      return await _reverseGeocodeNominatim(latitude, longitude);
    } catch (_) {
      return LocationInfo(city: 'Unknown', country: '');
    }
  }

  /// Reverse geocode using Nominatim API
  static Future<LocationInfo> _reverseGeocodeNominatim(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=en',
    );

    final response = await http
        .get(
          uri,
          headers: {'User-Agent': 'PrayerApp/1.0 (contact@example.com)'},
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw LocationServiceException(
        'Geocoding failed: HTTP ${response.statusCode}',
      );
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final address = body['address'] as Map<String, dynamic>?;

    if (address == null) {
      throw LocationServiceException('No address data found');
    }

    final city =
        address['city'] ??
        address['town'] ??
        address['village'] ??
        address['county'] ??
        address['state'] ??
        'Unknown';
    final country = address['country'] ?? '';

    return LocationInfo(city: city.toString(), country: country.toString());
  }

  /// Get location by IP address (fallback)
  static Future<LocationInfo> getLocationByIP() async {
    try {
      final uri = Uri.parse('https://ipapi.co/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        throw LocationServiceException(
          'IP lookup failed: HTTP ${response.statusCode}',
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final city = body['city'] as String? ?? 'Unknown';
      final country = body['country_name'] as String? ?? '';

      return LocationInfo(city: city, country: country);
    } catch (e) {
      throw LocationServiceException('IP lookup failed: $e');
    }
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Open app settings for location permission
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

/// Location data with coordinates and address
class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final bool isDefault;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.isDefault = false,
  });

  /// Get formatted location string
  String get formattedLocation {
    if (city != 'Unknown' && city.isNotEmpty) {
      return country.isNotEmpty ? '$city, $country' : city;
    }
    return '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
  }

  /// Get coordinates string
  String get coordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  String toString() =>
      'LocationData(lat: $latitude, lon: $longitude, city: $city, country: $country, isDefault: $isDefault)';
}

/// Location info from geocoding
class LocationInfo {
  final String city;
  final String country;

  LocationInfo({required this.city, required this.country});

  /// Get formatted location string
  String get formattedLocation {
    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    }
    return city.isNotEmpty ? city : country;
  }

  @override
  String toString() => 'LocationInfo(city: $city, country: $country)';
}

/// Result wrapper for location with fallback indication
class LocationResult {
  final LocationData data;
  final bool usedDefault;

  LocationResult({required this.data, required this.usedDefault});

  @override
  String toString() => 'LocationResult(data: $data, usedDefault: $usedDefault)';
}

/// Custom exception for location service errors
class LocationServiceException implements Exception {
  final String message;

  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
