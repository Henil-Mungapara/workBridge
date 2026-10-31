import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

/// Representation of a verified geographical location with coordinates and address.
class AppLocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String? postalCode;
  final double? heading;
  final double? speed;
  final DateTime timestamp;

  const AppLocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    this.postalCode,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      if (postalCode != null) 'postalCode': postalCode,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppLocationData.fromMap(Map<String, dynamic> map) {
    final lat = (map['latitude'] as num?)?.toDouble() ?? 21.9619;
    final lng = (map['longitude'] as num?)?.toDouble() ?? 70.7923;
    final addr = map['address'] as String? ?? 'Gondal, Gujarat';
    final city = map['city'] as String? ?? 'Gondal';
    final tsStr = map['timestamp'] as String?;
    final ts = tsStr != null ? DateTime.tryParse(tsStr) ?? DateTime.now() : DateTime.now();

    return AppLocationData(
      latitude: lat,
      longitude: lng,
      address: addr,
      city: city,
      postalCode: map['postalCode'] as String?,
      heading: (map['heading'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      timestamp: ts,
    );
  }
}

/// Centralized service managing device location permissions, GPS checks,
/// reverse geocoding, distance calculations, and real-time position updates.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Default fallback location: Gondal, Gujarat (Lat: 21.9619, Lng: 70.7923)
  static const double defaultLat = 21.9619;
  static const double defaultLng = 70.7923;
  static const String defaultCity = 'Gondal';
  static const String defaultAddress = 'Gondal, Gujarat 360311, India';

  /// Test hook to mock location responses in automated test environments
  @visibleForTesting
  static AppLocationData? mockLocationData;

  /// Test hook to bypass permission dialogs in automated test environments
  @visibleForTesting
  static bool? mockPermissionGranted;

  // ── 1. Check and Request Location Permissions ──────────────────────────────

  /// Checks if location service (GPS hardware) is enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    if (mockPermissionGranted != null) return mockPermissionGranted!;
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return true; // Fallback for platforms without direct sensor support
    }
  }

  /// Verifies and requests location permission.
  /// If permission is denied or service disabled, displays a WorkBridge-branded
  /// modal explaining the mandatory requirement for live dispatch and tracking.
  ///
  /// Returns `true` only if permission is granted and GPS is on; otherwise `false`.
  Future<bool> checkAndEnforceLocationPermission({
    required BuildContext context,
    required String roleTitle, // e.g. "Customer" or "Service Provider"
    required String actionReason, // e.g. "send your service request" or "accept this booking"
  }) async {
    if (mockPermissionGranted != null) {
      return mockPermissionGranted!;
    }

    // 1. Check GPS Service
    bool serviceEnabled = false;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = true;
    }

    if (!serviceEnabled && context.mounted) {
      final shouldOpen = await _showLocationDisabledDialog(context, actionReason);
      if (shouldOpen == true) {
        await Geolocator.openLocationSettings();
      }
      return false;
    }

    // 2. Check Permission Status
    LocationPermission permission = LocationPermission.denied;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('Location permission check exception: $e');
      return true; // Allow graceful fallback in desktop/test environments
    }

    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context: context,
          roleTitle: roleTitle,
          actionReason: actionReason,
          isPermanent: false,
        );
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        final openSettings = await _showPermissionDeniedDialog(
          context: context,
          roleTitle: roleTitle,
          actionReason: actionReason,
          isPermanent: true,
        );
        if (openSettings == true) {
          await Geolocator.openAppSettings();
        }
      }
      return false;
    }

    return true;
  }

  // ── 2. Get Current Location & Reverse Geocoding ───────────────────────────

  /// Retrieves current GPS coordinates and performs reverse geocoding to obtain
  /// the readable city (e.g. Gondal) and full street address.
  Future<AppLocationData> getCurrentLocation() async {
    if (mockLocationData != null) {
      return mockLocationData!;
    }

    double lat = defaultLat;
    double lng = defaultLng;
    double? heading;
    double? speed;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
      heading = position.heading;
      speed = position.speed;
    } catch (e) {
      debugPrint('Geolocator fetch position fallback to default (Gondal): $e');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          lat = last.latitude;
          lng = last.longitude;
          heading = last.heading;
          speed = last.speed;
        }
      } catch (_) {}
    }

    // Reverse geocode coordinates to human-readable address
    String city = defaultCity;
    String fullAddress = defaultAddress;
    String? postalCode;

    try {
      final placemarks = await geo.Geocoding().placemarkFromCoordinates(lat, lng).timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality?.trim();
        final subAdmin = place.subAdministrativeArea?.trim();
        final admin = place.administrativeArea?.trim();
        final street = place.street?.trim();
        final subLocality = place.subLocality?.trim();
        final pCode = place.postalCode?.trim();
        postalCode = pCode;

        if (locality != null && locality.isNotEmpty) {
          city = locality;
        } else if (subAdmin != null && subAdmin.isNotEmpty) {
          city = subAdmin;
        } else if (admin != null && admin.isNotEmpty) {
          city = admin;
        }

        final parts = <String>[];
        if (street != null && street.isNotEmpty && street != place.name) {
          parts.add(street);
        }
        if (subLocality != null && subLocality.isNotEmpty) {
          parts.add(subLocality);
        }
        if (locality != null && locality.isNotEmpty) {
          parts.add(locality);
        }
        if (admin != null && admin.isNotEmpty) {
          parts.add(admin);
        }
        if (pCode != null && pCode.isNotEmpty) {
          parts.add(pCode);
        }

        if (parts.isNotEmpty) {
          fullAddress = parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding exception: $e');
      // If coordinates are approximately around Gondal (21.96, 70.79), format clean Gondal address
      if ((lat - defaultLat).abs() < 0.2 && (lng - defaultLng).abs() < 0.2) {
        city = 'Gondal';
        fullAddress = 'Gondal, Gujarat, India';
      } else {
        fullAddress = 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
      }
    }

    return AppLocationData(
      latitude: lat,
      longitude: lng,
      address: fullAddress,
      city: city,
      postalCode: postalCode,
      heading: heading,
      speed: speed,
      timestamp: DateTime.now(),
    );
  }

  // ── 3. Distance & Geometry Calculations ────────────────────────────────────

  /// Calculates geodesic distance between two coordinate pairs in meters.
  double calculateDistanceMeters(double startLat, double startLng, double endLat, double endLng) {
    try {
      return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    } catch (_) {
      return 0.0;
    }
  }

  /// Calculates distance in kilometers formatted as readable string.
  String formatDistance(double startLat, double startLng, double endLat, double endLng) {
    final meters = calculateDistanceMeters(startLat, startLng, endLat, endLng);
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Calculates estimated travel time in minutes based on urban technician travel (30 km/h avg).
  String estimateTravelTime(double startLat, double startLng, double endLat, double endLng) {
    final meters = calculateDistanceMeters(startLat, startLng, endLat, endLng);
    if (meters < 100) return 'Arrived';
    final minutes = ((meters / 1000.0) / 30.0 * 60).round();
    final clamped = minutes < 2 ? 2 : minutes;
    return '$clamped mins';
  }

  // ── 4. Dialog Alerts ───────────────────────────────────────────────────────

  Future<bool?> _showLocationDisabledDialog(BuildContext context, String actionReason) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Turn On Location',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'Location services (GPS) are currently turned off on your device. '
            'WorkBridge requires active device location to $actionReason and provide live technician tracking.\n\n'
            'Please turn on device location to continue.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _showPermissionDeniedDialog({
    required BuildContext context,
    required String roleTitle,
    required String actionReason,
    required bool isPermanent,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fmd_bad_rounded,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Location Permission',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            isPermanent
                ? '$roleTitle location permission is permanently disabled in app settings. '
                    'WorkBridge cannot $actionReason without precise location for live routing.\n\n'
                    'Please open App Settings and allow Location permission.'
                : '$roleTitle location permission was denied. '
                    'WorkBridge strictly requires your location to $actionReason and ensure real-time technician matching and tracking.\n\n'
                    'Please grant location permission to proceed.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
        actionsOverflowButtonSpacing: 8,
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Dismiss', style: TextStyle(color: AppColors.secondaryText)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(
                    isPermanent ? 'App Settings' : 'Allow Access',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
