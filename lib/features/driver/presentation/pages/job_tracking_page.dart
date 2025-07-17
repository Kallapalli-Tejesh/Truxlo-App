import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/tracking_service.dart';
import '../../../../services/location_service.dart';
import '../../../../services/maps_service.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../../widgets/job_map_widget.dart';

class JobTrackingPage extends StatefulWidget {
  final Job job;

  const JobTrackingPage({
    Key? key,
    required this.job,
  }) : super(key: key);

  @override
  State<JobTrackingPage> createState() => _JobTrackingPageState();
}

class _JobTrackingPageState extends State<JobTrackingPage> {
  bool _isTrackingActive = false;
  RouteProgress? _routeProgress;
  Timer? _progressTimer;
  String _currentStatus = '';
  String _estimatedArrival = '';
  double _progressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    setState(() {
      _currentStatus = 'Initializing tracking...';
    });

    // Check if tracking is already active
    if (TrackingService.isActiveTracking && TrackingService.activeJobId == widget.job.id) {
      _isTrackingActive = true;
      _startProgressUpdates();
    }

    await _updateRouteProgress();
  }

  Future<void> _startTracking() async {
    setState(() {
      _currentStatus = 'Starting tracking...';
    });

    try {
      // Check location permission first
      final hasPermission = await LocationService.getCurrentLocationWithPermissionCheck(context);
      if (hasPermission == null) {
        setState(() {
          _currentStatus = 'Location permission required';
        });
        return;
      }

      await TrackingService.startJobTracking(widget.job.id, widget.job.assignedDriverId!);
      setState(() {
        _isTrackingActive = true;
        _currentStatus = 'Tracking active';
      });
      _startProgressUpdates();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job tracking started'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _currentStatus = 'Failed to start tracking';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start tracking: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _stopTracking() async {
    setState(() {
      _currentStatus = 'Stopping tracking...';
    });

    try {
      await TrackingService.stopJobTracking();
      setState(() {
        _isTrackingActive = false;
        _currentStatus = 'Tracking stopped';
      });
      _progressTimer?.cancel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job tracking stopped'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _currentStatus = 'Failed to stop tracking';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop tracking: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startProgressUpdates() {
    _progressTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updateRouteProgress();
    });
  }

  Future<void> _updateRouteProgress() async {
    try {
      final progress = await TrackingService.getRouteProgress(widget.job.id);
      if (progress != null) {
        setState(() {
          _routeProgress = progress;
          _progressPercentage = progress.progressPercentage;
          _estimatedArrival = _formatDuration(progress.estimatedTimeRemaining);
        });
      }
    } catch (e) {
      debugPrint('Error updating route progress: $e');
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

  String _getJobStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return 'Assigned - Head to pickup';
      case 'awaitingpickupverification':
        return 'At pickup - Awaiting verification';
      case 'intransit':
        return 'In transit to destination';
      case 'awaitingdeliveryverification':
        return 'At destination - Awaiting verification';
      case 'completed':
        return 'Job completed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'awaitingpickupverification':
        return Colors.purple;
      case 'intransit':
        return Colors.orange;
      case 'awaitingdeliveryverification':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Job Tracking',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Job Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.job.title,
                        style: AppTheme.headingMedium.copyWith(color: Colors.white),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.job.jobStatus).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getJobStatusText(widget.job.jobStatus),
                        style: TextStyle(
                          color: _getStatusColor(widget.job.jobStatus),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Progress Bar
                if (_progressPercentage > 0) ...[
                  Text(
                    'Progress: ${_progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progressPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(widget.job.jobStatus)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Route Information
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            widget.job.pickupLocation,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.white70),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Destination',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            widget.job.destination,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                if (_estimatedArrival.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ETA: $_estimatedArrival',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (_routeProgress != null)
                        Text(
                          'Distance: ${_routeProgress!.remainingDistance.toStringAsFixed(1)} km',
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: JobMapWidget(
                job: widget.job,
                showDriverLocation: true,
                showRoute: true,
                enableTracking: _isTrackingActive,
                height: double.infinity,
              ),
            ),
          ),

          // Control Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_currentStatus.isNotEmpty) ...[
                  Text(
                    _currentStatus,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTrackingActive ? _stopTracking : _startTracking,
                        icon: Icon(_isTrackingActive ? Icons.stop : Icons.play_arrow),
                        label: Text(_isTrackingActive ? 'Stop Tracking' : 'Start Tracking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTrackingActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _updateRouteProgress,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
}