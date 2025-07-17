import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Import the services we've enhanced
import '../lib/services/location_service.dart';
import '../lib/services/tracking_service.dart';
import '../lib/services/maps_service.dart';

void main() {
  group('Enhanced Tracking System Tests', () {
    
    test('LocationPermissionException should be created correctly', () {
      final exception = LocationPermissionException(
        LocationPermissionError.denied,
        'Permission denied',
        'Please grant permission'
      );
      
      expect(exception.type, LocationPermissionError.denied);
      expect(exception.message, 'Permission denied');
      expect(exception.solution, 'Please grant permission');
    });

    test('DriverLocation should be created correctly', () {
      final driverLocation = DriverLocation(
        driverId: 'test-driver-id',
        latitude: 28.6139,
        longitude: 77.2090,
        speed: 50.0,
        heading: 90.0,
        accuracy: 5.0,
        timestamp: DateTime.now(),
        jobStatus: 'inTransit',
      );
      
      expect(driverLocation.driverId, 'test-driver-id');
      expect(driverLocation.latitude, 28.6139);
      expect(driverLocation.longitude, 77.2090);
      expect(driverLocation.jobStatus, 'inTransit');
    });

    test('RouteProgress should be created correctly', () {
      final routeProgress = RouteProgress(
        currentLocation: const LatLng(28.6139, 77.2090),
        pickupLocation: const LatLng(28.6129, 77.2080),
        destinationLocation: const LatLng(28.6149, 77.2100),
        route: RouteInfo(
          polylineCoordinates: [
            const LatLng(28.6139, 77.2090),
            const LatLng(28.6149, 77.2100),
          ],
          distance: '1.2 km',
          duration: '5 min',
          distanceValue: 1200,
          durationValue: 300,
        ),
        progressPercentage: 50.0,
        remainingDistance: 0.6,
        estimatedTimeRemaining: 150,
      );
      
      expect(routeProgress.progressPercentage, 50.0);
      expect(routeProgress.remainingDistance, 0.6);
      expect(routeProgress.estimatedTimeRemaining, 150);
    });

    group('Location Service Tests', () {
      test('LocationService static properties should be accessible', () {
        expect(LocationService.isTracking, isA<bool>());
        expect(LocationService.currentPosition, isNull);
      });
    });

    group('Tracking Service Tests', () {
      test('TrackingService static properties should be accessible', () {
        expect(TrackingService.isActiveTracking, isA<bool>());
        expect(TrackingService.activeJobId, isNull);
        expect(TrackingService.trackingDriverId, isNull);
      });
    });
  });
}