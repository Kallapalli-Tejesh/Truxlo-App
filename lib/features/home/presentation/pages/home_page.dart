import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../jobs/domain/models/job_application.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../profile/presentation/pages/profile_completion_page.dart';
import '../../../warehouse/presentation/pages/warehouse_home_page.dart';
import '../../../broker/presentation/pages/broker_home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
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
    _tabController = TabController(length: 4, vsync: this);
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
      debugPrint('Loading available jobs...');
      final jobs = await SupabaseService.getOpenJobs();
      debugPrint('Received ${jobs.length} jobs from database');

      if (_isDisposed) return;

      setState(() {
        _availableJobs = jobs.map((job) => Job.fromJson(job)).toList();
        debugPrint('Parsed jobs length: ${_availableJobs.length}');
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading jobs: $e');
      debugPrint('Stack trace: $stackTrace');
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
      debugPrint('Error loading applications: $e');
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
      debugPrint('Error loading jobs: $e');
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

    // Subscribe to job changes
    _jobsChannel = SupabaseService.client.channel('public:jobs');
    _jobsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          callback: (payload) async {
            debugPrint('Job change detected: ${payload.eventType}');
            await _loadAvailableJobs();
            await _loadMyJobs();
          },
        )
        .subscribe();

    // Subscribe to application changes
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
            debugPrint('Application change detected: ${payload.eventType}');
            await _loadMyApplications();

            // Show notification for status updates
            if (payload.eventType == PostgresChangeEvent.update) {
              final newStatus = payload.newRecord?['status'] as String?;
              if (newStatus != null) {
                _showStatusUpdateNotification(newStatus);
              }
            }
          },
        )
        .subscribe();
  }

  void _showStatusUpdateNotification(String status) {
    if (!mounted) return;

    String message;
    Color backgroundColor;
    IconData icon;
    Duration duration;

    switch (status.toLowerCase()) {
      case 'accepted':
        message = 'Congratulations! Your application has been accepted!';
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        duration = Duration(seconds: 4);
        break;
      case 'rejected':
        message = 'Your application was not selected for this job.';
        backgroundColor = Colors.red;
        icon = Icons.cancel;
        duration = Duration(seconds: 4);
        break;
      default:
        return; // Don't show notification for other status updates
    }

    // Clear any existing SnackBars before showing the new one
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show the new SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // If the application was accepted, refresh the jobs list and applications
    if (status.toLowerCase() == 'accepted') {
      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;
        Future.wait([
          _loadAvailableJobs(),
          _loadMyApplications(),
          _loadMyJobs(),
        ]);
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
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

    final userRole = _profile!.role?.toString().toLowerCase();

    if (userRole == 'driver') {
      return _buildDriverHome();
    } else if (userRole == 'broker') {
      return _buildBrokerHome();
    } else if (userRole == 'warehouse_owner') {
      return const WarehouseHomePage();
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Unknown user role',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Widget _buildDriverHome() {
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
        title: Text(
          'Driver Dashboard',
          style: AppTheme.headingMedium,
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
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Jobs'),
            Tab(icon: Icon(Icons.local_shipping), text: 'My Jobs'),
            Tab(icon: Icon(Icons.people), text: 'Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableJobsTab(),
          _buildMyJobsTab(),
          _buildMyApplicationsTab(),
        ],
      ),
    );
  }

  Widget _buildBrokerHome() {
    return const BrokerHomePage();
  }

  Widget _buildAvailableJobsTab() {
    return RefreshIndicator(
      onRefresh: _loadAvailableJobs,
      color: Colors.red,
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
                        'Driver',
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
                  'Available Jobs',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_availableJobs.isEmpty)
                  Center(
                    child: Text(
                      'No jobs available at the moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
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
                if (job.jobStatus == 'assigned')
                  SizedBox(
                    width: double.infinity,
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
                if (job.jobStatus == 'inTransit')
                  SizedBox(
                    width: double.infinity,
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
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                    style: TextStyle(
                      color: job.jobStatus.toLowerCase() == 'open' ? Colors.white : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
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
            if (job.jobStatus == 'assigned')
              SizedBox(
                width: double.infinity,
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
            if (job.jobStatus == 'inTransit')
              SizedBox(
                width: double.infinity,
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.grey[400],
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
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

      // Check if user has active jobs
      final hasActiveJob = await SupabaseService.hasActiveJob(userId);
      if (hasActiveJob) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please complete your current job before applying for new ones'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
          duration: Duration(seconds: 5), // Reduced to 5 seconds
          behavior: SnackBarBehavior.floating,
        ),
      );

      await SupabaseService.applyForJob(jobId, userId);

      // Show success message
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

      // Refresh the jobs lists
      await Future.wait([
        _loadAvailableJobs(),
        _loadMyApplications(),
      ]);
    } catch (e) {
      print('Error applying for job: $e');
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
      case 'open':
        return Colors.blue;
      default:
        return Colors.grey;
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
        case 'assigned':
          await SupabaseService.startDelivery(jobId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery started - Awaiting pickup verification'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'awaitingpickupverification':
          await SupabaseService.updateJobStatus(jobId, 'inTransit');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job status updated to In Transit'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        case 'intransit':
          await SupabaseService.completeDelivery(jobId);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery completed - Awaiting warehouse owner verification'),
              backgroundColor: Colors.green,
            ),
          );
          break;
        default:
          return;
      }
      await _loadMyJobs();
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

  String _getJobStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'awaitingpickupverification':
        return 'Awaiting Pickup';
      case 'intransit':
        return 'In Transit';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getJobStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue; // Bright standard blue for open
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
}
