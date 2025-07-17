import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enhanced error handling for location services
enum LocationPermissionError {
  denied,
  deniedForever,
  serviceDisabled,
  timeout,
  unknown,
}

class LocationPermissionException implements Exception {
  final LocationPermissionError type;
  final String message;
  final String? solution;
  
  LocationPermissionException(this.type, this.message, [this.solution]);
  
  @override
  String toString() => 'LocationPermissionException: $message';
}

class LocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _currentPosition;
  static bool _isTracking = false;

  /// Enhanced permission checking with detailed error handling
  static Future<bool> checkAndRequestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationPermissionException(
          LocationPermissionError.serviceDisabled,
          'Location services are disabled on this device',
          'Please enable location services in your device settings'
        );
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationPermissionException(
            LocationPermissionError.denied,
            'Location permission was denied',
            'Please grant location permission to use tracking features'
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionException(
          LocationPermissionError.deniedForever,
          'Location permission is permanently denied',
          'Please enable location permission in app settings'
        );
      }

      return true;
    } catch (e) {
      if (e is LocationPermissionException) {
        rethrow;
      }
      throw LocationPermissionException(
        LocationPermissionError.unknown,
        'Unknown error occurred while checking location permission: $e'
      );
    }
  }

  /// Legacy method for backward compatibility
  static Future<bool> checkLocationPermission() async {
    try {
      return await checkAndRequestLocationPermission();
    } catch (e) {
      debugPrint('Location permission check failed: $e');
      return false;
    }
  }

  /// Show location permission alert dialog
  static Future<bool> showLocationPermissionAlert(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Location Access Required',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'This app needs location access to track your position and provide navigation. Please enable location services to continue.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enable Location'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Open device location settings
  static Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
    }
  }

  /// Get current location with enhanced error handling
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      debugPrint('Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Get current location with permission check and user interaction
  static Future<Position?> getCurrentLocationWithPermissionCheck(BuildContext context) async {
    try {
      await checkAndRequestLocationPermission();
      return await getCurrentLocation();
    } on LocationPermissionException catch (e) {
      debugPrint('Location permission error: $e');
      
      // Show user-friendly dialog
      final shouldOpenSettings = await showLocationPermissionAlert(context);
      if (shouldOpenSettings) {
        await openLocationSettings();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current location with permission check: $e');
      return null;
    }
  }

  /// Start location tracking for drivers
  static Future<void> startLocationTracking(String driverId) async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return;

      if (_isTracking) {
        debugPrint('Location tracking already active');
        return;
      }

      _isTracking = true;
      debugPrint('Starting location tracking for driver: $driverId');

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          _currentPosition = position;
          await _updateDriverLocation(driverId, position);
        },
        onError: (error) {
          debugPrint('Location tracking error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      _isTracking = false;
    }
  }

  /// Stop location tracking
  static Future<void> stopLocationTracking() async {
    if (_positionStream != null) {
      await _positionStream!.cancel();
      _positionStream = null;
      _isTracking = false;
      debugPrint('Location tracking stopped');
    }
  }

  /// Update driver location in database
  static Future<void> _updateDriverLocation(String driverId, Position position) async {
    try {
      await Supabase.instance.client
          .from('driver_details')
          .update({
            'current_location': '${position.latitude},${position.longitude}',
            'last_active': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', driverId);

      debugPrint('Driver location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error updating driver location: $e');
    }
  }

  /// Get address from coordinates
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      return 'Unknown location';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return 'Address not available';
    }
  }

  /// Get coordinates from address
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  /// Get current position (cached)
  static Position? get currentPosition => _currentPosition;

  /// Check if tracking is active
  static bool get isTracking => _isTracking;

  /// Get driver's current location from database
  static Future<Position?> getDriverLocation(String driverId) async {
    try {
      final response = await Supabase.instance.client
          .from('driver_details')
          .select('current_location')
          .eq('user_id', driverId)
          .single();

      final locationString = response['current_location'] as String?;
      if (locationString != null && locationString.isNotEmpty) {
        final coords = locationString.split(',');
        if (coords.length == 2) {
          return Position(
            latitude: double.parse(coords[0]),
            longitude: double.parse(coords[1]),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting driver location: $e');
      return null;
    }
  }

  /// Check if driver is near pickup/delivery location
  static bool isNearLocation(Position driverPosition, Position targetPosition, {double radiusKm = 0.5}) {
    final distance = calculateDistance(
      driverPosition.latitude,
      driverPosition.longitude,
      targetPosition.latitude,
      targetPosition.longitude,
    );
    return distance <= radiusKm;
  }
}