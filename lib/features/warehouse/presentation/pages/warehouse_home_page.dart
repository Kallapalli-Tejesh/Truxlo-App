import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
import '../../../../core/services/supabase_service.dart';
import 'post_job_page.dart';

class WarehouseHomePage extends StatefulWidget {
  const WarehouseHomePage({super.key});

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Job> _postedJobs = [];
  List<Job> _activeJobs = [];
  Map<String, List<Map<String, dynamic>>> _jobApplications = {};
  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _applicationsChannel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user ID found');
        return;
      }

      final profile = await SupabaseService.getUserProfile(userId);
      print('Loaded profile: $profile'); // Debug log

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e'); // Debug log
      if (!mounted) return;
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
                job.status == 'assigned' || job.status == 'in_progress')
            .toList();
      });
    } catch (e) {
      print('Error loading active jobs: $e');
    }
  }

  Future<void> _loadJobApplications(String jobId) async {
    try {
      final applications = await SupabaseService.getJobApplications(jobId);
      if (!mounted) return;

      setState(() {
        _jobApplications[jobId] = applications;
      });
    } catch (e) {
      print('Error loading applications: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _jobsChannel = SupabaseService.client
        .channel('public:jobs:warehouse_owner_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'warehouse_owner_id',
            value: userId,
          ),
          callback: (payload) {
            _loadPostedJobs();
          },
        )
        .subscribe();
  }

  void _setupApplicationsSubscription() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _applicationsChannel = SupabaseService.client
        .channel('public:job_applications:warehouse_owner')
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
            print('Application change detected: ${payload.eventType}');

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
                    final jobIndex =
                        _postedJobs.indexWhere((job) => job.id == jobId);
                    if (jobIndex != -1) {
                      _postedJobs[jobIndex] = _postedJobs[jobIndex].copyWith(
                        status: 'assigned',
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
    String? driverName,
  ) async {
    try {
      // Show loading indicator in a non-blocking way
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' ? 'Assigning driver...' : 'Updating status...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Make the API call
      await SupabaseService.updateApplicationStatus(
        applicationId,
        status,
        jobId,
        driverId: driverId,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'Driver assigned successfully'
                : 'Status updated',
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
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating application status: $e');
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Revert local state changes
      setState(() {
        final applications = _jobApplications[jobId];
        if (applications != null) {
          final index =
              applications.indexWhere((app) => app['id'] == applicationId);
          if (index != -1) {
            applications[index] = {
              ...applications[index],
              'status': 'pending',
            };
          }
        }
      });
    }
  }

  String _formatTimeAgo(DateTime date) {
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
                          color: job.status == 'open'
                              ? Color(0xFF6B5ECD).withOpacity(0.2)
                              : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          job.status.toUpperCase(),
                          style: TextStyle(
                            color: job.status == 'open'
                                ? Color(0xFF6B5ECD)
                                : Colors.green,
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
    final applications = _jobApplications[job.id];
    final pendingApplications =
        applications?.where((app) => app['status'] == 'pending').length ?? 0;

    return GestureDetector(
      onTap: () {
        _loadJobApplications(job.id);
        _showApplications(job);
      },
      child: Container(
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
                const SizedBox(width: 8),
                if (pendingApplications > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B5ECD).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingApplications new',
                      style: const TextStyle(
                        color: Color(0xFF6B5ECD),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'From: ${job.pickupLocation}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'To: ${job.destination}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeAgo(job.postedDate),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.local_shipping,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${job.weight} kg',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.route,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${job.distance} km',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                              AlwaysStoppedAnimation<Color>(Color(0xFF6B5ECD)),
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

  Widget _buildApplicationCard(Map<String, dynamic> application, Job job) {
    final driver = application['driver'];
    final status = application['status'];
    final createdAt = DateTime.parse(application['created_at']);

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? statusMessage;

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'ACCEPTED';
        statusMessage = 'Job has been assigned to ${driver['full_name']}';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        statusMessage = 'This application has been rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'PENDING';
        statusMessage = null;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'accepted'
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: status == 'accepted' ? 2 : 1,
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
                  driver['full_name'] ?? 'Unknown Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (statusMessage != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    status == 'accepted' ? Icons.check_circle : Icons.info,
                    color: statusColor,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 8),
          Text(
            'Phone: ${driver['phone'] ?? 'Not provided'}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey[400],
                size: 16,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Applied ${_formatTimeAgo(createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (status == 'pending')
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateApplicationStatus(
                        application['id'],
                        'accepted',
                        job.id,
                        driver['id'],
                        driver['full_name'],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateApplicationStatus(
                        application['id'],
                        'rejected',
                        job.id,
                        null,
                        null,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
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
                  color: job.status == 'assigned'
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  job.status == 'assigned'
                      ? 'DELIVERY NOT STARTED'
                      : 'IN PROGRESS',
                  style: TextStyle(
                    color:
                        job.status == 'assigned' ? Colors.blue : Colors.orange,
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
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Assigned to: ${job.assignedDriverName ?? 'Unknown Driver'}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'From: ${job.pickupLocation}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[400],
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'To: ${job.destination}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Assigned: ${_formatTimeAgo(job.assignedDate!)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.local_shipping,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${job.weight} kg',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.route,
                  color: Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${job.distance} km',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: () async {
              await SupabaseService.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Posted Jobs'),
            Tab(text: 'Active Jobs'),
            Tab(text: 'Applications'),
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
      color: Color(0xFF6B5ECD),
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
                        'Welcome back, ${_profile!['full_name']}',
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
      color: Color(0xFF6B5ECD),
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
                        'Welcome back, ${_profile!['full_name']}',
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
      color: Color(0xFF6B5ECD),
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
}
