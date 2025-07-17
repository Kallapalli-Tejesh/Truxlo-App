import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../jobs/domain/models/job_application.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../../services/location_service.dart';
import '../../../../services/tracking_service.dart';
import 'job_tracking_page.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({Key? key}) : super(key: key);

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UserProfile? _profile;
  List<Job> _availableJobs = [];
  List<JobApplication> _myApplications = [];
  List<Job> _myJobs = [];
  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _applicationsChannel;
  late TabController _tabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _jobsChannel?.unsubscribe();
    _applicationsChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_isDisposed) return;
    try {
      final profile = await SupabaseService.getUserProfile();
      if (profile != null) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
        _loadAvailableJobs();
        _loadMyApplications();
        _loadMyJobs();
        _setupRealtimeSubscription();
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

  Future<void> _loadAvailableJobs() async {
    if (_isDisposed) return;
    try {
      final jobs = await SupabaseService.getOpenJobs();
      if (_isDisposed) return;
      setState(() {
        _availableJobs = jobs.map((job) => Job.fromJson(job)).toList();
      });
    } catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
    }
  }

  Future<void> _loadMyApplications() async {
    if (_isDisposed) return;
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;
      final applications = await SupabaseService.getDriverApplications(userId);
      if (_isDisposed) return;
      setState(() {
        _myApplications = applications.map((app) => JobApplication.fromJson(app)).toList();
      });
    } catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    }
  }

  Future<void> _loadMyJobs() async {
    if (_isDisposed) return;
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;
      final jobs = await SupabaseService.getDriverJobs(userId);
      if (_isDisposed) return;
      setState(() {
        _myJobs = jobs.map((job) => Job.fromJson(job)).toList();
      });
    } catch (e) {
      if (_isDisposed) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading jobs: $e')),
        );
      }
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
          callback: (payload) async {
            await _loadAvailableJobs();
            await _loadMyJobs();
          },
        )
        .subscribe();
    _applicationsChannel = SupabaseService.client.channel('public:job_applications');
    _applicationsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: userId,
          ),
          callback: (payload) async {
            await _loadMyApplications();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
      );
    }
    if (_profile == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error loading profile',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage()),
            );
          },
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Driver Dashboard',
          style: AppTheme.headingMedium.copyWith(color: Colors.white),
        ),
          actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () async {
              await Future.wait([
                _loadAvailableJobs(),
                _loadMyApplications(),
                _loadMyJobs(),
              ]);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Jobs'),
            Tab(icon: Icon(Icons.local_shipping), text: 'My Jobs'),
            Tab(icon: Icon(Icons.people), text: 'Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildAvailableJobsTab(),
          _buildMyJobsTab(),
          _buildMyApplicationsTab(),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsTab() {
    return RefreshIndicator(
      onRefresh: _loadAvailableJobs,
      color: AppTheme.primaryColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${_profile!.fullName}',
                        style: AppTheme.headingLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Driver',
                        style: AppTheme.bodyMedium.copyWith(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Available Jobs',
                  style: AppTheme.headingMedium.copyWith(color: Colors.grey[300]),
                ),
                const SizedBox(height: 16),
                if (_availableJobs.isEmpty)
                  Center(
                    child: Text(
                      'No jobs available at the moment',
                      style: AppTheme.bodyLarge.copyWith(color: Colors.white.withOpacity(0.8)),
                    ),
                  )
                else
                  ..._availableJobs.map((job) => _buildJobCard(job)).toList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyApplicationsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyApplications,
      color: Colors.red,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'My Applications',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_myApplications.isEmpty)
                  Center(
                    child: Text(
                      'No applications yet',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  ..._myApplications.map((app) => _buildApplicationCard(app)).toList(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobsTab() {
    if (_myJobs.isEmpty) {
      return Center(
        child: Text(
          'No active jobs found',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myJobs.length,
      itemBuilder: (context, index) {
        final job = _myJobs[index];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(job.jobStatus),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        job.jobStatus.toUpperCase(),
                        style: TextStyle(
                          color: job.jobStatus.toLowerCase() == 'open' ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Type', job.goodsType),
                _buildDetailRow('Weight', '${job.weight} kg'),
                _buildDetailRow('Price', '₹${job.price}'),
                _buildDetailRow('Distance', '${job.distance} km'),
                const SizedBox(height: 12),
                _buildLocationSection(
                  'Pickup',
                  job.pickupLocation,
                  Icons.location_on,
                ),
                const SizedBox(height: 8),
                _buildLocationSection(
                  'Destination',
                  job.destination,
                  Icons.location_on,
                ),
                const SizedBox(height: 16),
                // Action buttons based on job status
                if (job.jobStatus == 'assigned') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _startDelivery(job.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Start Delivery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openJobTracking(job),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Track'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (job.jobStatus == 'inTransit') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateJobStatus(job.id, job.jobStatus),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Complete Delivery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openJobTracking(job),
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (job.jobStatus == 'awaitingPickupVerification' || 
                          job.jobStatus == 'awaitingDeliveryVerification') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openJobTracking(job),
                      icon: const Icon(Icons.location_on, size: 18),
                      label: Text(
                        job.jobStatus == 'awaitingPickupVerification' 
                            ? 'View Pickup Location' 
                            : 'View Delivery Location'
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobCard(Job job) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobDetailsPage(job: job),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        elevation: 4,
        shadowColor: Colors.black54,
        color: AppTheme.surfaceColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getJobStatusColor(job.jobStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getJobStatusText(job.jobStatus),
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.description,
                style: AppTheme.bodyMedium.copyWith(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${job.price.toStringAsFixed(2)}',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${job.distance} km',
                    style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (job.jobStatus == 'assigned')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _startDelivery(job.id),
                    style: AppTheme.elevatedHomeButtonStyle,
                    child: const Text(
                      'START DELIVERY',
                      style: TextStyle(letterSpacing: 1.2),
                    ),
                  ),
                ),
              if (job.jobStatus == 'inTransit')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _updateJobStatus(job.id, job.jobStatus),
                    style: AppTheme.elevatedHomeButtonStyle.copyWith(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                    ),
                    child: const Text(
                      'COMPLETE DELIVERY',
                      style: TextStyle(letterSpacing: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(JobApplication application) {
    final job = application.job!;
    final status = application.status;
    final createdAt = application.createdAt;
    Color statusColor;
    IconData statusIcon;
    String statusMessage;
    String? statusDescription;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusMessage = 'Accepted';
        statusDescription =
            'Congratulations! Your application has been accepted. Please check your notifications for further instructions.';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusMessage = 'Rejected';
        statusDescription =
            'Your application was not selected for this job. Keep applying for other opportunities!';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusMessage = 'Pending';
        statusDescription =
            'Your application is being reviewed. We\'ll notify you when there\'s an update.';
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
                      statusMessage,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Applied ${_formatTimeAgo(createdAt)}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              if (job.warehouseOwner != null)
                Text(
                  job.warehouseOwner!.fullName ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          if (statusDescription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusDescription,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Open job tracking page
  void _openJobTracking(Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobTrackingPage(job: job),
      ),
    );
  }

  Future<void> _applyForJob(String jobId) async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to apply for jobs'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final hasActiveJob = await SupabaseService.hasActiveJob(userId);
      if (hasActiveJob) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your current job before applying for new ones'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Submitting application...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await SupabaseService.applyForJob(jobId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF6B5ECD),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.wait([
        _loadAvailableJobs(),
        _loadMyApplications(),
      ]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying for job: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'awaitingpickupverification':
        return Colors.purple;
      case 'intransit':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getJobStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'assigned':
        return Colors.blue;
      case 'awaitingpickupverification':
        return Colors.purple;
      case 'intransit':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getJobStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'OPEN';
      case 'assigned':
        return 'ASSIGNED';
      case 'awaitingpickupverification':
        return 'PICKUP PENDING';
      case 'intransit':
        return 'IN TRANSIT';
      case 'completed':
        return 'COMPLETED';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }

  Future<void> _startDelivery(String jobId) async {
    try {
      await SupabaseService.updateJobStatus(jobId, 'awaitingPickupVerification');
      await _loadMyJobs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery started - Awaiting pickup verification'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateJobStatus(String jobId, String currentStatus) async {
    try {
      switch (currentStatus.toLowerCase()) {
        case 'intransit':
          await SupabaseService.updateJobStatus(jobId, 'awaitingDeliveryVerification');
          break;
        default:
          return;
      }
      await _loadMyJobs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating job status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}