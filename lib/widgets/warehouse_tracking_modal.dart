import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/tracking_service.dart';
import '../services/location_service.dart';
import '../services/maps_service.dart';
import '../features/jobs/domain/models/job.dart';
import '../core/theme/app_theme.dart';

class WarehouseTrackingModal extends StatefulWidget {
  final Job job;

  const WarehouseTrackingModal({
    Key? key,
    required this.job,
  }) : super(key: key);

  @override
  State<WarehouseTrackingModal> createState() => _WarehouseTrackingModalState();
}

class _WarehouseTrackingModalState extends State<WarehouseTrackingModal> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  DriverLocation? _driverLocation;
  Timer? _locationUpdateTimer;
  bool _isLoading = true;
  String _statusText = '';
  String _etaText = '';

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    TrackingService.stopWarehouseTracking(widget.job.id);
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    setState(() {
      _statusText = 'Initializing tracking...';
    });

    try {
      // Start warehouse tracking session
      await TrackingService.startWarehouseTracking(widget.job.id);
      
      // Load initial driver location
      await _loadDriverLocation();
      
      // Load job locations and route
      await _loadTrackingView();
      
      // Start real-time updates
      _startLocationUpdates();
      
      setState(() {
        _isLoading = false;
        _statusText = _getStatusText();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'Error initializing tracking';
      });
      debugPrint('Error initializing tracking: $e');
    }
  }

  Future<void> _loadDriverLocation() async {
    try {
      debugPrint('Loading driver location for job: ${widget.job.id}');
      final driverLocation = await TrackingService.getDriverLocationForWarehouse(widget.job.id);
      if (driverLocation != null) {
        debugPrint('Driver location found: ${driverLocation.latitude}, ${driverLocation.longitude}');
        setState(() {
          _driverLocation = driverLocation;
        });
      } else {
        debugPrint('No driver location found for job: ${widget.job.id}');
        setState(() {
          _statusText = 'Driver location not available';
        });
      }
    } catch (e) {
      debugPrint('Error loading driver location: $e');
      setState(() {
        _statusText = 'Error loading driver location';
      });
    }
  }

  Future<void> _loadTrackingView() async {
    if (_driverLocation == null) return;

    try {
      final pickupCoords = await LocationService.getCoordinatesFromAddress(widget.job.pickupLocation);
      final destCoords = await LocationService.getCoordinatesFromAddress(widget.job.destination);

      if (pickupCoords == null || destCoords == null) return;

      final pickupLatLng = LatLng(pickupCoords.latitude, pickupCoords.longitude);
      final destLatLng = LatLng(destCoords.latitude, destCoords.longitude);
      final driverLatLng = LatLng(_driverLocation!.latitude, _driverLocation!.longitude);

      // Create markers based on job status
      _markers = _createTrackingMarkers(pickupLatLng, destLatLng, driverLatLng);

      // Get status-based route
      final route = await TrackingService.getStatusBasedRoute(widget.job.id, driverLatLng);
      if (route != null) {
        setState(() {
          _polylines = {MapsService.createRoutePolyline(route.polylineCoordinates)};
          _etaText = _formatDuration(route.durationValue);
        });
      }

      // Focus camera on driver location
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: driverLatLng,
              zoom: 15.0, // Focus on driver location
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading tracking view: $e');
    }
  }

  Set<Marker> _createTrackingMarkers(LatLng pickup, LatLng destination, LatLng driver) {
    final markers = <Marker>{};

    // Pickup marker (green)
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
        title: 'Pickup Location',
        snippet: 'Goods pickup point',
      ),
    ));

    // Destination marker (red)
    markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(
        title: 'Destination',
        snippet: 'Delivery destination',
      ),
    ));

    // Driver marker (blue)
    markers.add(Marker(
      markerId: const MarkerId('driver'),
      position: driver,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Driver Location',
        snippet: 'Current position - ${widget.job.assignedDriver?.fullName ?? "Unknown"}',
      ),
    ));

    return markers;
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _loadDriverLocation();
      await _loadTrackingView();
    });
  }

  String _getStatusText() {
    switch (widget.job.jobStatus.toLowerCase()) {
      case 'assigned':
        return 'Driver heading to pickup location';
      case 'awaitingpickupverification':
        return 'Driver at pickup - awaiting verification';
      case 'intransit':
      case 'inTransit':
        return 'Driver en route to destination';
      case 'awaitingdeliveryverification':
        return 'Driver at destination - awaiting verification';
      default:
        return 'Tracking active';
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Color _getStatusColor() {
    switch (widget.job.jobStatus.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'awaitingpickupverification':
        return Colors.purple;
      case 'intransit':
      case 'inTransit':
        return Colors.orange;
      case 'awaitingdeliveryverification':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Tracking: ${widget.job.title}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_etaText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ETA: $_etaText',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          // Focus on driver location after map is created
                          if (_driverLocation != null) {
                            final driverLatLng = LatLng(_driverLocation!.latitude, _driverLocation!.longitude);
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: driverLatLng,
                                  zoom: 15.0,
                                ),
                              ),
                            );
                          }
                        },
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(28.6139, 77.2090), // Default to Delhi
                          zoom: 10,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        mapType: MapType.normal,
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                        mapToolbarEnabled: false,
                        style: _darkMapStyle,
                      ),
                      
                      // Show message overlay when driver location is not available
                      if (_driverLocation == null && !_isLoading)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_off,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Driver Location Not Available',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'The driver\'s location is not currently available. Please try refreshing or check back later.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),

          // Info Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Driver',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            widget.job.assignedDriver?.fullName ?? 'Unknown',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    if (_driverLocation != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Last Update',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _formatLastUpdate(_driverLocation!.timestamp),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _loadDriverLocation();
                          await _loadTrackingView();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
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