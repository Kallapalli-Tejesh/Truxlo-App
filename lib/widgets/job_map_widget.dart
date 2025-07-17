import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/maps_service.dart';
import '../services/location_service.dart';
import '../services/tracking_service.dart';
import '../features/jobs/domain/models/job.dart';

class JobMapWidget extends StatefulWidget {
  final Job job;
  final bool showDriverLocation;
  final bool showRoute;
  final bool enableTracking;
  final double height;
  final VoidCallback? onMapCreated;

  const JobMapWidget({
    Key? key,
    required this.job,
    this.showDriverLocation = false,
    this.showRoute = false,
    this.enableTracking = false,
    this.height = 300,
    this.onMapCreated,
  }) : super(key: key);

  @override
  State<JobMapWidget> createState() => _JobMapWidgetState();
}

class _JobMapWidgetState extends State<JobMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _driverLocation;
  Timer? _locationUpdateTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    if (widget.enableTracking) {
      _startLocationUpdates();
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    // First load driver location if needed
    if (widget.showDriverLocation) {
      await _loadDriverLocation();
    }
    
    // Then load job locations
    await _loadJobLocations();
    
    // Load route after we have all locations
    if (widget.showRoute) {
      await _loadRoute();
    }
    
    // Focus camera on driver location if available
    if (_driverLocation != null && _mapController != null) {
      await _focusOnDriverLocation();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadJobLocations() async {
    try {
      // Get coordinates for pickup and destination
      final pickupCoords = await LocationService.getCoordinatesFromAddress(widget.job.pickupLocation);
      final destCoords = await LocationService.getCoordinatesFromAddress(widget.job.destination);

      if (pickupCoords != null && destCoords != null) {
        final pickupLatLng = LatLng(pickupCoords.latitude, pickupCoords.longitude);
        final destLatLng = LatLng(destCoords.latitude, destCoords.longitude);

        _markers = MapsService.createJobMarkers(
          pickupLatLng,
          destLatLng,
          driverLocation: _driverLocation,
          onPickupTap: () => _showLocationInfo('Pickup Location', widget.job.pickupLocation),
          onDestinationTap: () => _showLocationInfo('Destination', widget.job.destination),
          onDriverTap: () => _showDriverInfo(),
        );

        // Update camera to show all markers only if we don't have driver location to focus on
        if (_mapController != null && _driverLocation == null) {
          final bounds = MapsService.getCameraBounds([pickupLatLng, destLatLng]);
          await _mapController!.animateCamera(bounds);
        }
      }
    } catch (e) {
      debugPrint('Error loading job locations: $e');
    }
  }

  Future<void> _loadDriverLocation() async {
    if (widget.job.assignedDriverId != null) {
      try {
        Position? driverPosition;
        
        // Always try to get current GPS location first when showing driver location
        if (widget.showDriverLocation) {
          driverPosition = await LocationService.getCurrentLocation();
        }
        
        // If GPS location not available, get from database
        if (driverPosition == null) {
          driverPosition = await LocationService.getDriverLocation(widget.job.assignedDriverId!);
        }
        
        if (driverPosition != null) {
          setState(() {
            _driverLocation = LatLng(driverPosition!.latitude, driverPosition.longitude);
          });
          await _updateMarkers();
        }
      } catch (e) {
        debugPrint('Error loading driver location: $e');
      }
    }
  }

  Future<void> _loadRoute() async {
    try {
      final pickupCoords = await LocationService.getCoordinatesFromAddress(widget.job.pickupLocation);
      final destCoords = await LocationService.getCoordinatesFromAddress(widget.job.destination);

      if (pickupCoords != null && destCoords != null) {
        final pickupLatLng = LatLng(pickupCoords.latitude, pickupCoords.longitude);
        final destLatLng = LatLng(destCoords.latitude, destCoords.longitude);

        LatLng startPoint = pickupLatLng;
        LatLng endPoint = destLatLng;
        
        // Status-based routing logic - ONLY if we have driver location
        if (_driverLocation != null) {
          startPoint = _driverLocation!;
          
          // For assigned status, route to pickup location
          if (widget.job.jobStatus == 'assigned' || widget.job.jobStatus == 'awaitingPickupVerification') {
            endPoint = pickupLatLng;
            debugPrint('Assigned job: Route from driver (${_driverLocation!.latitude}, ${_driverLocation!.longitude}) to pickup (${pickupLatLng.latitude}, ${pickupLatLng.longitude})');
          }
          // For inTransit status, route to destination
          else if (widget.job.jobStatus == 'inTransit' || widget.job.jobStatus == 'awaitingDeliveryVerification') {
            endPoint = destLatLng;
            debugPrint('InTransit job: Route from driver (${_driverLocation!.latitude}, ${_driverLocation!.longitude}) to destination (${destLatLng.latitude}, ${destLatLng.longitude})');
          }
        } else {
          debugPrint('No driver location available, showing default pickup to destination route');
        }

        debugPrint('Getting route from (${startPoint.latitude}, ${startPoint.longitude}) to (${endPoint.latitude}, ${endPoint.longitude})');
        final route = await MapsService.getRoute(startPoint, endPoint);
        if (route != null) {
          setState(() {
            _polylines = {MapsService.createRoutePolyline(route.polylineCoordinates)};
          });
          debugPrint('Route loaded successfully with ${route.polylineCoordinates.length} points');
        } else {
          debugPrint('Failed to get route');
        }
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
    }
  }

  Future<void> _updateMarkers() async {
    final pickupCoords = await LocationService.getCoordinatesFromAddress(widget.job.pickupLocation);
    final destCoords = await LocationService.getCoordinatesFromAddress(widget.job.destination);

    if (pickupCoords != null && destCoords != null) {
      final pickupLatLng = LatLng(pickupCoords.latitude, pickupCoords.longitude);
      final destLatLng = LatLng(destCoords.latitude, destCoords.longitude);

      setState(() {
        _markers = MapsService.createJobMarkers(
          pickupLatLng,
          destLatLng,
          driverLocation: _driverLocation,
          onPickupTap: () => _showLocationInfo('Pickup Location', widget.job.pickupLocation),
          onDestinationTap: () => _showLocationInfo('Destination', widget.job.destination),
          onDriverTap: () => _showDriverInfo(),
        );
      });
    }
  }

  Future<void> _focusOnDriverLocation() async {
    if (_driverLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _driverLocation!,
            zoom: 15.0, // Good zoom level to see the driver and nearby area
          ),
        ),
      );
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (widget.job.assignedDriverId != null) {
        await _loadDriverLocation();
        if (widget.showRoute) {
          await _loadRoute();
        }
      }
    });
  }

  void _showLocationInfo(String title, String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          address,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDriverInfo() {
    if (widget.job.assignedDriver != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Driver Information',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Name: ${widget.job.assignedDriver!.fullName ?? 'Unknown'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${widget.job.jobStatus}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFFE53935)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoading
            ? Container(
                color: const Color(0xFF1E1E1E),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                  ),
                ),
              )
            : GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  widget.onMapCreated?.call();
                  // Focus on driver location after map is created
                  if (_driverLocation != null) {
                    _focusOnDriverLocation();
                  }
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(28.6139, 77.2090), // Default to Delhi
                  zoom: 10,
                ),
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                myLocationEnabled: widget.enableTracking,
                myLocationButtonEnabled: widget.enableTracking,
                zoomControlsEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
                style: _darkMapStyle,
              ),
      ),
    );
  }

  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "administrative.country",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9e9e9e"
        }
      ]
    },
    {
      "featureType": "administrative.land_parcel",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#bdbdbd"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#181818"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#1b1b1b"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [
        {
          "color": "#2c2c2c"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#8a8a8a"
        }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#373737"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#3c3c3c"
        }
      ]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#4e4e4e"
        }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#000000"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#3d3d3d"
        }
      ]
    }
  ]
  ''';
}