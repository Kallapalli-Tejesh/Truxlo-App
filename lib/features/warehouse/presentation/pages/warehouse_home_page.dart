import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../jobs/domain/models/job_application.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'post_job_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class WarehouseHomePage extends StatefulWidget {
  const WarehouseHomePage({super.key});

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UserProfile? _profile;
  List<Job> _postedJobs = [];
  List<Job> _activeJobs = [];
  Map<String, List<JobApplication>> _jobApplications = {};
  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _applicationsChannel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
    _loadPostedJobs().then((_) {
      // Load applications for all jobs after jobs are loaded
      for (var job in _postedJobs) {
        _loadJobApplications(job.id);
      }
    });
    _loadActiveJobs();
    _setupRealtimeSubscription();
    _setupApplicationsSubscription();
  }

  @override
  void dispose() {
    _jobsChannel?.unsubscribe();
    _applicationsChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.getUserProfile();
      if (profile != null) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPostedJobs() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final jobs = await SupabaseService.getWarehouseOwnerJobs(userId);
      if (!mounted) return;

      setState(() {
        _postedJobs = jobs.map((job) => Job.fromJson(job)).toList();
      });
    } catch (e) {
      print('Error loading jobs: $e');
    }
  }

  Future<void> _loadActiveJobs() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final jobs = await SupabaseService.getWarehouseOwnerJobs(userId);
      if (!mounted) return;

      setState(() {
        _activeJobs = jobs
            .map((job) => Job.fromJson(job))
            .where((job) =>
                job.jobStatus == 'assigned' ||
                job.jobStatus == 'awaitingPickupVerification' ||
                job.jobStatus == 'inTransit' ||
                job.jobStatus == 'awaitingDeliveryVerification')
            .toList();
      });
    } catch (e) {
      print('Error loading active jobs: $e');
    }
  }

  Future<void> _loadJobApplications(String jobId) async {
    try {
      final applications = await SupabaseService.getJobApplications(jobId);
      if (mounted) {
        setState(() {
          _jobApplications[jobId] = applications.map((app) => JobApplication.fromJson(app)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _jobsChannel = SupabaseService.client.channel('public:jobs');
    _jobsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'warehouse_owner_id',
            value: userId,
          ),
          callback: (payload) async {
            debugPrint('Job change detected: ${payload.eventType}');
            await _loadPostedJobs();
            await _loadActiveJobs();
          },
        )
        .subscribe();
  }

  void _setupApplicationsSubscription() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _applicationsChannel = SupabaseService.client.channel('public:job_applications');
    _applicationsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'job:jobs(warehouse_owner_id)',
            value: userId,
          ),
          callback: (payload) async {
            debugPrint('Application change detected: ${payload.eventType}');

            // Get the affected job ID from the payload
            final jobId = payload.newRecord?['job_id'] as String?;
            if (jobId != null) {
              // Only reload the affected job's applications
              await _loadJobApplications(jobId);

              // If it's an update and the status changed to accepted
              if (payload.eventType == PostgresChangeEvent.update) {
                final newStatus = payload.newRecord?['status'] as String?;
                if (newStatus == 'accepted') {
                  // Update the job status in local state
                  setState(() {
                    final jobIndex = _postedJobs.indexWhere((job) => job.id == jobId);
                    if (jobIndex != -1) {
                      _postedJobs[jobIndex] = _postedJobs[jobIndex].copyWith(
                        jobStatus: 'assigned',
                        assignedDriverId: payload.newRecord?['driver_id'],
                        assignedDate: DateTime.now(),
                      );
                    }
                  });
                }
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> _updateApplicationStatus(
    String applicationId,
    String status,
    String jobId,
    String? driverId,
  ) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Updating status...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update application status
      await SupabaseService.updateApplicationStatus(
        applicationId,
        status,
        jobId,
        driverId: driverId,
      );

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' 
                ? 'Application accepted successfully'
                : 'Application rejected successfully',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Update local state
      setState(() {
        final applications = _jobApplications[jobId];
        if (applications != null) {
          final index = applications.indexWhere((app) => app.id == applicationId);
          if (index != -1) {
            applications[index] = applications[index].copyWith(status: status);
          }
        }
      });

      // If accepting, update the job status
      if (status == 'accepted') {
        setState(() {
          final jobIndex = _postedJobs.indexWhere((job) => job.id == jobId);
          if (jobIndex != -1) {
            _postedJobs[jobIndex] = _postedJobs[jobIndex].copyWith(
              jobStatus: 'assigned',
              assignedDriverId: driverId,
              assignedDate: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating application status: $e');
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status: ${e.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Revert local state changes
      setState(() {
        final applications = _jobApplications[jobId];
        if (applications != null) {
          final index = applications.indexWhere((app) => app.id == applicationId);
          if (index != -1) {
            applications[index] = applications[index].copyWith(status: 'pending');
          }
        }
      });
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showJobDetails(Job job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getJobStatusColor(job.jobStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getJobStatusText(job.jobStatus),
                          style: TextStyle(
                            color: _getJobStatusColor(job.jobStatus),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    job.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildDetailSection(
                    'Goods Information',
                    [
                      _buildDetailRow('Type', job.goodsType),
                      _buildDetailRow('Weight', '${job.weight} kg'),
                      _buildDetailRow(
                          'Price', '₹${job.price.toStringAsFixed(2)}'),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildDetailSection(
                    'Location Details',
                    [
                      _buildDetailRowWithIcon(
                        'Pickup',
                        job.pickupLocation,
                        Icons.location_on,
                      ),
                      _buildDetailRowWithIcon(
                        'Destination',
                        job.destination,
                        Icons.location_on,
                      ),
                      _buildDetailRow('Distance', '${job.distance} km'),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildDetailSection(
                    'Additional Information',
                    [
                      _buildDetailRow('Posted', _formatTimeAgo(job.postedDate)),
                      if (job.assignedDriverId != null) ...[
                        _buildDetailRow('Driver', 'Assigned'),
                        _buildDetailRow(
                          'Assigned Date',
                          _formatTimeAgo(job.assignedDate!),
                        ),
                      ],
                      if (job.completionDate != null)
                        _buildDetailRow(
                          'Completed',
                          _formatTimeAgo(job.completionDate!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithIcon(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final isActive = _isJobActive(job.jobStatus);
    final statusColor = _getJobStatusColor(job.jobStatus);
    final statusText = _getJobStatusText(job.jobStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job.pickupLocation} → ${job.destination}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '₹${job.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (job.assignedDriverId != null)
                Text(
                  'Assigned to: ${job.assignedDriver?.fullName ?? "Unknown Driver"}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPickup(String jobId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Verifying pickup...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update job status to 'inTransit' through SupabaseService
      await SupabaseService.updateJobStatus(jobId, 'inTransit');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pickup verified successfully',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        final jobIndex = _activeJobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          _activeJobs[jobIndex] = _activeJobs[jobIndex].copyWith(
            jobStatus: 'inTransit',
          );
        }
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to verify pickup: ${e.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showApplications(Job job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applications for ${job.title}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Posted ${_formatTimeAgo(job.postedDate)}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _jobApplications[job.id] == null
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      )
                    : _jobApplications[job.id]!.isEmpty
                        ? Center(
                            child: Text(
                              'No applications yet',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: _jobApplications[job.id]!.length,
                            itemBuilder: (context, index) {
                              final application =
                                  _jobApplications[job.id]![index];
                              return _buildApplicationCard(application, job);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(JobApplication application, Job job) {
    final driver = application.driver;
    final status = application.status;
    final createdAt = application.createdAt;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? statusMessage;

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        statusMessage = 'Application has been accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        statusMessage = 'Application has been rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
        statusMessage = 'Application is pending review';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver?.fullName ?? 'Unknown Driver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver?.email ?? 'Email not provided',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Applied ${_formatTimeAgo(createdAt)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
              ),
            ),
          ],
          if (status == 'pending' && driver != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateApplicationStatus(
                        application.id,
                        'accepted',
                        job.id,
                        driver.id,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateApplicationStatus(
                        application.id,
                        'rejected',
                        job.id,
                        null,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveJobCard(Job job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getJobStatusColor(job.jobStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getJobStatusText(job.jobStatus),
                  style: TextStyle(
                    color: _getJobStatusColor(job.jobStatus),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${job.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '${job.distance} km',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show 'Verify Pickup' button for warehouse owner if job is awaiting pickup verification
          if (job.jobStatus == 'awaitingPickupVerification')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _verifyPickup(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Verify Pickup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Existing delivery verification button
          if (job.jobStatus == 'awaitingDeliveryVerification')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _verifyDelivery(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Verify Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _verifyDelivery(String jobId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Verifying delivery...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Verify delivery
      await SupabaseService.verifyDelivery(jobId);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery verified successfully',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Update local state
      setState(() {
        final jobIndex = _activeJobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          _activeJobs[jobIndex] = _activeJobs[jobIndex].copyWith(
            jobStatus: 'completed',
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Text(
            'Error loading profile',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        title: Text(
          'Warehouse Dashboard',
          style: AppTheme.headingMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () {
              _loadPostedJobs();
              _loadActiveJobs();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Posted Jobs'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Active Jobs'),
            Tab(icon: Icon(Icons.people), text: 'Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostedJobsTab(),
          _buildActiveJobsTab(),
          _buildApplicationsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostJobPage()),
          );
          if (result == true) {
            _loadPostedJobs();
          }
        },
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildPostedJobsTab() {
    return RefreshIndicator(
      onRefresh: _loadPostedJobs,
      color: Colors.red,
      backgroundColor: Colors.black,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_profile!.fullName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Warehouse Owner',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your Posted Jobs',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_postedJobs.isEmpty)
                  Center(
                    child: Text(
                      'No jobs posted yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ..._postedJobs.map((job) => _buildJobCard(job)).toList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobsTab() {
    return RefreshIndicator(
      onRefresh: _loadActiveJobs,
      color: Colors.red,
      backgroundColor: Colors.black,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_profile!.fullName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Warehouse Owner',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Active Jobs',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_activeJobs.isEmpty)
                  Center(
                    child: Text(
                      'No active jobs at the moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ..._activeJobs
                      .map((job) => _buildActiveJobCard(job))
                      .toList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        for (var job in _postedJobs) {
          await _loadJobApplications(job.id);
        }
      },
      color: Colors.red,
      backgroundColor: Colors.black,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Job Applications',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_postedJobs.isEmpty)
                  Center(
                    child: Text(
                      'No jobs posted yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ..._postedJobs.map((job) {
                    final applications = _jobApplications[job.id];
                    if (applications == null || applications.isEmpty) {
                      return Container(); // Skip jobs with no applications
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...applications.map((application) {
                          return _buildApplicationCard(application, job);
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _getJobStatusColor(String jobStatus) {
    switch (jobStatus.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'awaitingpickupverification':
        return Colors.purple;
      case 'intransit':
        return Colors.green;
      case 'awaitingdeliveryverification':
        return Colors.amber;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getJobStatusText(String jobStatus) {
    switch (jobStatus.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'awaitingpickupverification':
        return 'Awaiting Pickup';
      case 'intransit':
        return 'In Transit';
      case 'awaitingdeliveryverification':
        return 'Awaiting Delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool _isJobActive(String jobStatus) {
    return jobStatus.toLowerCase() == 'assigned' ||
           jobStatus.toLowerCase() == 'awaitingpickupverification' ||
           jobStatus.toLowerCase() == 'intransit' ||
           jobStatus.toLowerCase() == 'awaitingdeliveryverification';
  }
}
