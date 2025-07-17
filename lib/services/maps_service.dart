import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'location_service.dart';

class MapsService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Get route between two points
  static Future<RouteInfo?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = '$_baseUrl/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode polyline
          final polylinePoints = decodePolyline(route['overview_polyline']['points']);
          final polylineCoordinates = polylinePoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return RouteInfo(
            polylineCoordinates: polylineCoordinates,
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            distanceValue: leg['distance']['value'],
            durationValue: leg['duration']['value'],
          );
        }
      }
      
      debugPrint('Error getting route: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error in getRoute: $e');
      return null;
    }
  }

  /// Get optimized route for multiple waypoints
  static Future<RouteInfo?> getOptimizedRoute(
    LatLng origin,
    LatLng destination,
    List<LatLng> waypoints,
  ) async {
    try {
      String waypointsStr = '';
      if (waypoints.isNotEmpty) {
        waypointsStr = '&waypoints=optimize:true|' +
            waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|');
      }

      final url = '$_baseUrl/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}'
          '$waypointsStr&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Calculate total distance and duration
          int totalDistance = 0;
          int totalDuration = 0;
          List<LatLng> allPolylineCoordinates = [];
          
          for (var leg in route['legs']) {
            totalDistance += leg['distance']['value'] as int;
            totalDuration += leg['duration']['value'] as int;
          }
          
          // Decode polyline
          final polylinePoints = decodePolyline(route['overview_polyline']['points']);
          allPolylineCoordinates = polylinePoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return RouteInfo(
            polylineCoordinates: allPolylineCoordinates,
            distance: '${(totalDistance / 1000).toStringAsFixed(1)} km',
            duration: '${(totalDuration / 60).round()} min',
            distanceValue: totalDistance,
            durationValue: totalDuration,
            waypointOrder: route['waypoint_order']?.cast<int>(),
          );
        }
      }
      
      debugPrint('Error getting optimized route: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error in getOptimizedRoute: $e');
      return null;
    }
  }

  /// Get nearby places (gas stations, rest areas, etc.)
  static Future<List<NearbyPlace>> getNearbyPlaces(
    LatLng location,
    String type, {
    int radius = 5000,
  }) async {
    try {
      final url = '$_baseUrl/place/nearbysearch/json?'
          'location=${location.latitude},${location.longitude}&'
          'radius=$radius&'
          'type=$type&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final places = <NearbyPlace>[];
          
          for (var place in data['results']) {
            places.add(NearbyPlace(
              name: place['name'],
              placeId: place['place_id'],
              location: LatLng(
                place['geometry']['location']['lat'],
                place['geometry']['location']['lng'],
              ),
              rating: place['rating']?.toDouble(),
              vicinity: place['vicinity'],
              types: List<String>.from(place['types']),
              isOpen: place['opening_hours']?['open_now'],
            ));
          }
          
          return places;
        }
      }
      
      debugPrint('Error getting nearby places: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Error in getNearbyPlaces: $e');
      return [];
    }
  }

  /// Create markers for map
  static Set<Marker> createJobMarkers(
    LatLng pickupLocation,
    LatLng destinationLocation, {
    LatLng? driverLocation,
    VoidCallback? onPickupTap,
    VoidCallback? onDestinationTap,
    VoidCallback? onDriverTap,
  }) {
    final markers = <Marker>{};

    // Pickup marker
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
        title: 'Pickup Location',
        snippet: 'Goods pickup point',
      ),
      onTap: onPickupTap,
    ));

    // Destination marker
    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destinationLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(
        title: 'Destination',
        snippet: 'Delivery destination',
      ),
      onTap: onDestinationTap,
    ));

    // Driver marker (if available)
    if (driverLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: driverLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: 'Driver Location',
          snippet: 'Current driver position',
        ),
        onTap: onDriverTap,
      ));
    }

    return markers;
  }

  /// Create polyline for route
  static Polyline createRoutePolyline(List<LatLng> coordinates) {
    return Polyline(
      polylineId: const PolylineId('route'),
      points: coordinates,
      color: Colors.blue,
      width: 4,
      patterns: [],
    );
  }

  /// Calculate camera bounds for multiple points
  static CameraUpdate getCameraBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      100.0, // padding
    );
  }

  /// Get estimated travel time
  static Future<int?> getEstimatedTravelTime(LatLng origin, LatLng destination) async {
    final route = await getRoute(origin, destination);
    return route?.durationValue;
  }

  /// Get traffic information
  static Future<TrafficInfo?> getTrafficInfo(LatLng origin, LatLng destination) async {
    try {
      final url = '$_baseUrl/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'departure_time=now&'
          'traffic_model=best_guess&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          return TrafficInfo(
            normalDuration: leg['duration']['value'],
            trafficDuration: leg['duration_in_traffic']?['value'] ?? leg['duration']['value'],
            trafficCondition: _getTrafficCondition(
              leg['duration']['value'],
              leg['duration_in_traffic']?['value'] ?? leg['duration']['value'],
            ),
          );
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting traffic info: $e');
      return null;
    }
  }

  static String _getTrafficCondition(int normalDuration, int trafficDuration) {
    final ratio = trafficDuration / normalDuration;
    if (ratio <= 1.1) return 'Light';
    if (ratio <= 1.3) return 'Moderate';
    return 'Heavy';
  }
}

class RouteInfo {
  final List<LatLng> polylineCoordinates;
  final String distance;
  final String duration;
  final int distanceValue;
  final int durationValue;
  final List<int>? waypointOrder;

  RouteInfo({
    required this.polylineCoordinates,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
    this.waypointOrder,
  });
}

class NearbyPlace {
  final String name;
  final String placeId;
  final LatLng location;
  final double? rating;
  final String? vicinity;
  final List<String> types;
  final bool? isOpen;

  NearbyPlace({
    required this.name,
    required this.placeId,
    required this.location,
    this.rating,
    this.vicinity,
    required this.types,
    this.isOpen,
  });
}

class TrafficInfo {
  final int normalDuration;
  final int trafficDuration;
  final String trafficCondition;

  TrafficInfo({
    required this.normalDuration,
    required this.trafficDuration,
    required this.trafficCondition,
  });

  int get delayMinutes => ((trafficDuration - normalDuration) / 60).round();
}