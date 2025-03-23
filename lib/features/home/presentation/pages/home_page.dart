import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../broker/presentation/pages/manage_drivers_page.dart';
import '../../../driver/presentation/pages/manage_brokers_page.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
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
  Map<String, dynamic>? _profile;
  List<Job> _availableJobs = [];
  List<Map<String, dynamic>> _myApplications = [];
  List<Job> _myJobs = [];
  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _applicationsChannel;
  late TabController _tabController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isDisposed) return;
    await _loadProfile();
    if (_isDisposed) return;
    await Future.wait([
      _loadAvailableJobs(),
      _loadMyApplications(),
      _loadMyJobs(),
    ]);
    _setupRealtimeSubscription();
    _setupApplicationsSubscription();
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
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No user ID found');
        return;
      }

      final profile = await SupabaseService.getUserProfile(userId);
      if (_isDisposed) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      if (_isDisposed) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableJobs() async {
    if (_isDisposed) return;
    try {
      print('Loading available jobs...');
      print('Auth state: ${SupabaseService.client.auth.currentSession}');
      print('Current user: ${SupabaseService.client.auth.currentUser}');

      final jobs = await SupabaseService.getOpenJobs();
      print('Received ${jobs.length} jobs from database');
      print('Jobs data: $jobs');

      if (_isDisposed) return;

      setState(() {
        _availableJobs = jobs.map((job) => Job.fromJson(job)).toList();
        print('Parsed jobs length: ${_availableJobs.length}');
      });
    } catch (e, stackTrace) {
      print('Error loading jobs: $e');
      print('Stack trace: $stackTrace');
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
        _myApplications = applications;
      });
    } catch (e) {
      print('Error loading applications: $e');
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
      print('Error loading my jobs: $e');
      if (_isDisposed) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading my jobs: $e')),
        );
      }
    }
  }

  void _setupRealtimeSubscription() {
    if (_isDisposed) return;
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _jobsChannel = SupabaseService.client
        .channel('public:jobs')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          callback: (payload) {
            if (!_isDisposed && mounted) {
              _loadAvailableJobs();
            }
          },
        )
        .subscribe();
  }

  void _setupApplicationsSubscription() {
    if (_isDisposed) return;
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _applicationsChannel = SupabaseService.client
        .channel('public:job_applications:driver_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: userId,
          ),
          callback: (payload) {
            if (!_isDisposed && mounted) {
              _loadMyApplications();
              if (payload.eventType == PostgresChangeEvent.update) {
                final newStatus = payload.newRecord?['status'] as String?;
                if (newStatus != null) {
                  _showStatusUpdateNotification(newStatus);
                }
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
          MaterialPageRoute(builder: (_) => const LoginPage()),
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B5ECD)),
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

    final userRole = _profile!['role']?.toString().toLowerCase();

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
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: _signOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Available Jobs'),
            Tab(text: 'My Applications'),
            Tab(text: 'My Jobs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableJobsTab(),
          _buildMyApplicationsTab(),
          _buildMyJobsTab(),
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
      color: Color(0xFF6B5ECD),
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
      color: Color(0xFF6B5ECD),
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
                  ..._myApplications
                      .map((app) => _buildApplicationCard(app))
                      .toList(),
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
                        color: _getStatusColor(job.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        job.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
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
                _buildDetailRow('Price', '\$${job.price}'),
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
                if (job.status == 'assigned')
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
                if (job.status == 'in_progress')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateJobStatus(job, 'completed'),
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
    // Check if any job in _myJobs is active (status is 'assigned' or 'in_progress')
    final hasActiveJob = _myJobs.any((j) =>
        j.status.toLowerCase() == 'assigned' ||
        j.status.toLowerCase() == 'in_progress');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsPage(job: job),
          ),
        );
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
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '₹${job.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
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
            Row(
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
            const SizedBox(height: 16),
            if (hasActiveJob)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your current active job before applying for new ones',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _applyForJob(job.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Apply for Job',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final job = Job.fromJson(application['job']);
    final status = application['status'];
    final createdAt = DateTime.parse(application['created_at']);

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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
          if (statusDescription != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                statusDescription,
                style: TextStyle(
                  color: statusColor.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 12),
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
                _buildInfoChip(
                  Icons.access_time,
                  'Applied ${_formatTimeAgo(createdAt)}',
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  Icons.local_shipping,
                  '${job.weight} kg',
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  Icons.route,
                  '${job.distance} km',
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  Icons.monetization_on,
                  '₹${job.price.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateJobStatus(Job job, String newStatus) async {
    try {
      await SupabaseService.updateJobStatus(job.id, newStatus);
      await _loadMyJobs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Job status updated to ${newStatus.replaceAll('_', ' ')}'),
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

  Future<void> _startDelivery(String jobId) async {
    try {
      await SupabaseService.updateJobStatus(jobId, 'in_progress');
      await _loadMyJobs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery started'),
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
}
