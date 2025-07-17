import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'maps_service.dart';

class TrackingService {
  static Timer? _trackingTimer;
  static String? _activeJobId;
  static String? _driverId;
  static bool _isActiveTracking = false;
  static StreamSubscription<Position>? _positionSubscription;
  
  // Warehouse tracking sessions
  static final Map<String, Timer> _warehouseTrackingSessions = {};
  static final Map<String, StreamController<DriverLocation>> _warehouseLocationStreams = {};

  /// Start comprehensive job tracking
  static Future<void> startJobTracking(String jobId, String driverId) async {
    try {
      debugPrint('Starting job tracking for job: $jobId, driver: $driverId');
      
      _activeJobId = jobId;
      _driverId = driverId;
      _isActiveTracking = true;

      // Start location tracking
      await LocationService.startLocationTracking(driverId);

      // Start periodic job status updates
      _trackingTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        await _updateJobProgress();
      });

      // Update job status to indicate tracking started
      await _updateJobTrackingStatus(jobId, true);

      debugPrint('Job tracking started successfully');
    } catch (e) {
      debugPrint('Error starting job tracking: $e');
      _isActiveTracking = false;
    }
  }

  /// Stop job tracking
  static Future<void> stopJobTracking() async {
    try {
      debugPrint('Stopping job tracking');

      _isActiveTracking = false;
      
      // Stop location tracking
      await LocationService.stopLocationTracking();

      // Cancel tracking timer
      _trackingTimer?.cancel();
      _trackingTimer = null;

      // Update job status to indicate tracking stopped
      if (_activeJobId != null) {
        await _updateJobTrackingStatus(_activeJobId!, false);
      }

      _activeJobId = null;
      _driverId = null;

      debugPrint('Job tracking stopped successfully');
    } catch (e) {
      debugPrint('Error stopping job tracking: $e');
    }
  }

  /// Update job progress based on location
  static Future<void> _updateJobProgress() async {
    if (!_isActiveTracking || _activeJobId == null || _driverId == null) return;

    try {
      // Get current location
      final currentPosition = await LocationService.getCurrentLocation();
      if (currentPosition == null) return;

      // Get job details
      final jobDetails = await _getJobDetails(_activeJobId!);
      if (jobDetails == null) return;

      // Check proximity to pickup/destination
      await _checkLocationProximity(currentPosition, jobDetails);

      // Update estimated arrival times
      await _updateEstimatedArrival(currentPosition, jobDetails);

      // Log tracking data
      await _logTrackingData(currentPosition, jobDetails);

    } catch (e) {
      debugPrint('Error updating job progress: $e');
    }
  }

  /// Check if driver is near pickup or destination
  static Future<void> _checkLocationProximity(Position driverPosition, Map<String, dynamic> jobDetails) async {
    try {
      final pickupLat = jobDetails['pickup_lat'] as double?;
      final pickupLng = jobDetails['pickup_lng'] as double?;
      final destLat = jobDetails['destination_lat'] as double?;
      final destLng = jobDetails['destination_lng'] as double?;
      final jobStatus = jobDetails['job_status'] as String;

      if (pickupLat != null && pickupLng != null) {
        final pickupPosition = Position(
          latitude: pickupLat,
          longitude: pickupLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        // Check if near pickup location
        if (jobStatus == 'assigned' && LocationService.isNearLocation(driverPosition, pickupPosition)) {
          await _notifyNearPickup(_activeJobId!);
        }
      }

      if (destLat != null && destLng != null) {
        final destPosition = Position(
          latitude: destLat,
          longitude: destLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );

        // Check if near destination
        if (jobStatus == 'inTransit' && LocationService.isNearLocation(driverPosition, destPosition)) {
          await _notifyNearDestination(_activeJobId!);
        }
      }
    } catch (e) {
      debugPrint('Error checking location proximity: $e');
    }
  }

  /// Update estimated arrival times
  static Future<void> _updateEstimatedArrival(Position driverPosition, Map<String, dynamic> jobDetails) async {
    try {
      final driverLatLng = LatLng(driverPosition.latitude, driverPosition.longitude);
      final jobStatus = jobDetails['job_status'] as String;

      if (jobStatus == 'assigned' || jobStatus == 'awaitingPickupVerification') {
        // Calculate ETA to pickup
        final pickupLat = jobDetails['pickup_lat'] as double?;
        final pickupLng = jobDetails['pickup_lng'] as double?;
        
        if (pickupLat != null && pickupLng != null) {
          final pickupLatLng = LatLng(pickupLat, pickupLng);
          final travelTime = await MapsService.getEstimatedTravelTime(driverLatLng, pickupLatLng);
          
          if (travelTime != null) {
            final eta = DateTime.now().add(Duration(seconds: travelTime));
            await _updateJobETA(_activeJobId!, 'pickup_eta', eta);
          }
        }
      } else if (jobStatus == 'inTransit') {
        // Calculate ETA to destination
        final destLat = jobDetails['destination_lat'] as double?;
        final destLng = jobDetails['destination_lng'] as double?;
        
        if (destLat != null && destLng != null) {
          final destLatLng = LatLng(destLat, destLng);
          final travelTime = await MapsService.getEstimatedTravelTime(driverLatLng, destLatLng);
          
          if (travelTime != null) {
            final eta = DateTime.now().add(Duration(seconds: travelTime));
            await _updateJobETA(_activeJobId!, 'delivery_eta', eta);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating estimated arrival: $e');
    }
  }

  /// Log tracking data for analytics
  static Future<void> _logTrackingData(Position position, Map<String, dynamic> jobDetails) async {
    try {
      await Supabase.instance.client.from('job_tracking_logs').insert({
        'job_id': _activeJobId,
        'driver_id': _driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'job_status': jobDetails['job_status'],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging tracking data: $e');
    }
  }

  /// Get job details from database
  static Future<Map<String, dynamic>?> _getJobDetails(String jobId) async {
    try {
      final response = await Supabase.instance.client
          .from('jobs')
          .select('*')
          .eq('id', jobId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error getting job details: $e');
      return null;
    }
  }

  /// Update job tracking status
  static Future<void> _updateJobTrackingStatus(String jobId, bool isTracking) async {
    try {
      await Supabase.instance.client
          .from('jobs')
          .update({
            'is_tracking_active': isTracking,
            'tracking_started_at': isTracking ? DateTime.now().toUtc().toIso8601String() : null,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', jobId);
    } catch (e) {
      debugPrint('Error updating job tracking status: $e');
    }
  }

  /// Update job ETA
  static Future<void> _updateJobETA(String jobId, String etaField, DateTime eta) async {
    try {
      await Supabase.instance.client
          .from('jobs')
          .update({
            etaField: eta.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', jobId);
    } catch (e) {
      debugPrint('Error updating job ETA: $e');
    }
  }

  /// Notify when driver is near pickup
  static Future<void> _notifyNearPickup(String jobId) async {
    try {
      // Create notification for warehouse owner
      await Supabase.instance.client.from('notifications').insert({
        'job_id': jobId,
        'type': 'driver_near_pickup',
        'title': 'Driver Near Pickup',
        'message': 'Driver is approaching the pickup location',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('Notification sent: Driver near pickup');
    } catch (e) {
      debugPrint('Error sending pickup notification: $e');
    }
  }

  /// Notify when driver is near destination
  static Future<void> _notifyNearDestination(String jobId) async {
    try {
      // Create notification for warehouse owner
      await Supabase.instance.client.from('notifications').insert({
        'job_id': jobId,
        'type': 'driver_near_destination',
        'title': 'Driver Near Destination',
        'message': 'Driver is approaching the delivery destination',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('Notification sent: Driver near destination');
    } catch (e) {
      debugPrint('Error sending destination notification: $e');
    }
  }

  /// Get tracking history for a job
  static Future<List<Map<String, dynamic>>> getJobTrackingHistory(String jobId) async {
    try {
      final response = await Supabase.instance.client
          .from('job_tracking_logs')
          .select('*')
          .eq('job_id', jobId)
          .order('timestamp', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting tracking history: $e');
      return [];
    }
  }

  /// Get current tracking status
  static bool get isActiveTracking => _isActiveTracking;
  static String? get activeJobId => _activeJobId;
  static String? get trackingDriverId => _driverId;

  /// Get driver location for warehouse owner tracking
  static Future<DriverLocation?> getDriverLocationForWarehouse(String jobId) async {
    try {
      final jobDetails = await _getJobDetails(jobId);
      if (jobDetails == null) return null;

      final driverId = jobDetails['assigned_driver_id'] as String?;
      if (driverId == null) return null;

      final driverPosition = await LocationService.getDriverLocation(driverId);
      if (driverPosition == null) return null;

      return DriverLocation(
        driverId: driverId,
        latitude: driverPosition.latitude,
        longitude: driverPosition.longitude,
        speed: driverPosition.speed,
        heading: driverPosition.heading,
        accuracy: driverPosition.accuracy,
        timestamp: driverPosition.timestamp,
        jobStatus: jobDetails['job_status'] as String,
      );
    } catch (e) {
      debugPrint('Error getting driver location for warehouse: $e');
      return null;
    }
  }

  /// Get status-based route for warehouse owner tracking
  static Future<RouteInfo?> getStatusBasedRoute(String jobId, LatLng driverLocation) async {
    try {
      final jobDetails = await _getJobDetails(jobId);
      if (jobDetails == null) return null;

      final jobStatus = jobDetails['job_status'] as String;
      final pickupLat = jobDetails['pickup_lat'] as double?;
      final pickupLng = jobDetails['pickup_lng'] as double?;
      final destLat = jobDetails['destination_lat'] as double?;
      final destLng = jobDetails['destination_lng'] as double?;

      LatLng destination;
      
      if (jobStatus == 'assigned' || jobStatus == 'awaitingPickupVerification') {
        // Route to pickup location
        if (pickupLat == null || pickupLng == null) return null;
        destination = LatLng(pickupLat, pickupLng);
      } else if (jobStatus == 'inTransit' || jobStatus == 'awaitingDeliveryVerification') {
        // Route to destination
        if (destLat == null || destLng == null) return null;
        destination = LatLng(destLat, destLng);
      } else {
        return null;
      }

      return await MapsService.getRoute(driverLocation, destination);
    } catch (e) {
      debugPrint('Error getting status-based route: $e');
      return null;
    }
  }

  /// Start warehouse tracking session
  static Future<void> startWarehouseTracking(String jobId) async {
    try {
      debugPrint('Starting warehouse tracking for job: $jobId');

      // Stop existing session if any
      await stopWarehouseTracking(jobId);

      // Create location stream for real-time updates
      final streamController = StreamController<DriverLocation>.broadcast();
      _warehouseLocationStreams[jobId] = streamController;

      // Start periodic location updates
      final timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        final driverLocation = await getDriverLocationForWarehouse(jobId);
        if (driverLocation != null && !streamController.isClosed) {
          streamController.add(driverLocation);
        }
      });

      _warehouseTrackingSessions[jobId] = timer;
      debugPrint('Warehouse tracking started for job: $jobId');
    } catch (e) {
      debugPrint('Error starting warehouse tracking: $e');
    }
  }

  /// Stop warehouse tracking session
  static Future<void> stopWarehouseTracking(String jobId) async {
    try {
      // Cancel timer
      final timer = _warehouseTrackingSessions.remove(jobId);
      timer?.cancel();

      // Close stream
      final streamController = _warehouseLocationStreams.remove(jobId);
      await streamController?.close();

      debugPrint('Warehouse tracking stopped for job: $jobId');
    } catch (e) {
      debugPrint('Error stopping warehouse tracking: $e');
    }
  }

  /// Get warehouse tracking stream
  static Stream<DriverLocation>? getWarehouseTrackingStream(String jobId) {
    return _warehouseLocationStreams[jobId]?.stream;
  }

  /// Get driver's route progress
  static Future<RouteProgress?> getRouteProgress(String jobId) async {
    try {
      final jobDetails = await _getJobDetails(jobId);
      if (jobDetails == null) return null;

      final driverLocation = await LocationService.getDriverLocation(jobDetails['assigned_driver_id']);
      if (driverLocation == null) return null;

      final pickupLat = jobDetails['pickup_lat'] as double?;
      final pickupLng = jobDetails['pickup_lng'] as double?;
      final destLat = jobDetails['destination_lat'] as double?;
      final destLng = jobDetails['destination_lng'] as double?;

      if (pickupLat == null || pickupLng == null || destLat == null || destLng == null) {
        return null;
      }

      final driverLatLng = LatLng(driverLocation.latitude, driverLocation.longitude);
      final pickupLatLng = LatLng(pickupLat, pickupLng);
      final destLatLng = LatLng(destLat, destLng);

      // Get route information
      final route = await MapsService.getRoute(driverLatLng, destLatLng);
      if (route == null) return null;

      // Calculate progress percentage
      final totalDistance = LocationService.calculateDistance(pickupLat, pickupLng, destLat, destLng);
      final remainingDistance = LocationService.calculateDistance(
        driverLocation.latitude, 
        driverLocation.longitude, 
        destLat, 
        destLng
      );
      
      final progressPercentage = ((totalDistance - remainingDistance) / totalDistance * 100).clamp(0, 100);

      return RouteProgress(
        currentLocation: driverLatLng,
        pickupLocation: pickupLatLng,
        destinationLocation: destLatLng,
        route: route,
        progressPercentage: progressPercentage.toDouble(),
        remainingDistance: remainingDistance,
        estimatedTimeRemaining: route.durationValue,
      );
    } catch (e) {
      debugPrint('Error getting route progress: $e');
      return null;
    }
  }
}

class RouteProgress {
  final LatLng currentLocation;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final RouteInfo route;
  final double progressPercentage;
  final double remainingDistance;
  final int estimatedTimeRemaining;

  RouteProgress({
    required this.currentLocation,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.route,
    required this.progressPercentage,
    required this.remainingDistance,
    required this.estimatedTimeRemaining,
  });
}

class DriverLocation {
  final String driverId;
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;
  final String jobStatus;

  DriverLocation({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
    required this.jobStatus,
  });
}