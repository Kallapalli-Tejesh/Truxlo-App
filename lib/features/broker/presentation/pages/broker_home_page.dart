import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/models/user_profile.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class BrokerHomePage extends StatefulWidget {
  const BrokerHomePage({super.key});

  @override
  State<BrokerHomePage> createState() => _BrokerHomePageState();
}

class _BrokerHomePageState extends State<BrokerHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  UserProfile? _profile;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _applications = [];
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'rating';
  String _jobStatusFilter = 'all';

  List<Map<String, dynamic>> get _filteredAndSortedDrivers {
    var filtered = _drivers.where((d) {
      final matchesQuery = _searchQuery.isEmpty || d['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'all' || d['status'] == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
    if (_sortBy == 'rating') {
      filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
    } else if (_sortBy == 'deliveries') {
      filtered.sort((a, b) => (b['totalDeliveries'] ?? 0).compareTo(a['totalDeliveries'] ?? 0));
    }
    return filtered;
  }

  void _showAddDriverDialog() {
    String name = '';
    String phone = '';
    String status = 'active';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Full Name'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                onChanged: (value) => phone = value,
              ),
              DropdownButton<String>(
                value: status,
                items: [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive'))],
                onChanged: (v) => status = v!,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.trim().isEmpty || phone.trim().isEmpty) return;
                setState(() {
                  _drivers.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': name.trim(),
                    'phone': phone.trim(),
                    'status': status,
                    'rating': 0.0,
                    'totalDeliveries': 0,
                    'currentLocation': 'Unknown',
                    'lastActive': DateTime.now(),
                  });
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Driver "$name" added!'), backgroundColor: Colors.green),
                );
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }


  void _showAssignJobDialog() {
    String? selectedJobId = _jobs.where((j) => j['status'] == 'open').isNotEmpty ? _jobs.firstWhere((j) => j['status'] == 'open')['id'] : null;
    String? selectedDriverId = _drivers.isNotEmpty ? _drivers.first['id'] : null;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedJobId,
                hint: Text('Select Job'),
                items: _jobs.where((j) => j['status'] == 'open').map<DropdownMenuItem<String>>((job) => DropdownMenuItem(value: job['id'], child: Text(job['title']))).toList(),
                onChanged: (v) => selectedJobId = v,
              ),
              DropdownButton<String>(
                value: selectedDriverId,
                hint: Text('Select Driver'),
                items: _drivers.map<DropdownMenuItem<String>>((d) => DropdownMenuItem(value: d['id'], child: Text(d['name']))).toList(),
                onChanged: (v) => selectedDriverId = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedJobId == null || selectedDriverId == null) return;
                setState(() {
                  final job = _jobs.firstWhere((j) => j['id'] == selectedJobId);
                  job['status'] = 'assigned';
                  job['assignedDriverId'] = selectedDriverId;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Job assigned!'), backgroundColor: Colors.green),
                );
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  void _showAddJobDialog() {
    String title = '';
    String description = '';
    String pickup = '';
    String destination = '';
    double price = 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Job'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Title'),
                  onChanged: (v) => title = v,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Description'),
                  onChanged: (v) => description = v,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Pickup Location'),
                  onChanged: (v) => pickup = v,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Destination'),
                  onChanged: (v) => destination = v,
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => price = double.tryParse(v) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.trim().isEmpty || pickup.trim().isEmpty || destination.trim().isEmpty) return;
                setState(() {
                  _jobs.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'title': title.trim(),
                    'description': description.trim(),
                    'status': 'open',
                    'assignedDriverId': null,
                    'applications': [],
                    'price': price,
                    'pickupLocation': pickup.trim(),
                    'destination': destination.trim(),
                    'createdAt': DateTime.now(),
                  });
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Job "$title" added!'), backgroundColor: Colors.green),
                );
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initDemoData();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs: Overview, Drivers, Jobs, Analytics
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    setState(() {
      _profile = UserProfile(
        id: 'local-broker',
        email: 'local@broker.com',
        fullName: 'Local Broker',
        role: 'broker',
        isProfileComplete: true,
        updatedAt: DateTime.now(),
        brokerDetails: null,
        warehouseDetails: null,
        driverDetails: null,
      );
    });
  }

  void _initDemoData() {
    _drivers = [
      {
        'id': 'd1',
        'name': 'John Doe',
        'phone': '+91 98765 43210',
        'status': 'active',
        'rating': 4.5,
        'totalDeliveries': 25,
        'currentLocation': 'Mumbai',
        'lastActive': DateTime.now().subtract(Duration(hours: 2)),
      },
      {
        'id': 'd2',
        'name': 'Rajesh Kumar',
        'phone': '+91 98765 43211',
        'status': 'inactive',
        'rating': 4.2,
        'totalDeliveries': 18,
        'currentLocation': 'Delhi',
        'lastActive': DateTime.now().subtract(Duration(days: 1)),
      },
      {
        'id': 'd3',
        'name': 'Amit Singh',
        'phone': '+91 98765 43212',
        'status': 'active',
        'rating': 4.8,
        'totalDeliveries': 32,
        'currentLocation': 'Bangalore',
        'lastActive': DateTime.now().subtract(Duration(hours: 1)),
      },
    ];
    _jobs = [
      {
        'id': 'j1',
        'title': 'Deliver Electronics',
        'description': 'Pickup electronics from Chennai and deliver to Hyderabad.',
        'status': 'open',
        'assignedDriverId': null,
        'applications': [],
        'price': 2000,
        'pickupLocation': 'Chennai',
        'destination': 'Hyderabad',
        'createdAt': DateTime.now().subtract(Duration(days: 2)),
      },
      {
        'id': 'j2',
        'title': 'Furniture Move',
        'description': 'Move furniture from Pune to Mumbai.',
        'status': 'assigned',
        'assignedDriverId': 'd1',
        'applications': ['d1', 'd3'],
        'price': 3500,
        'pickupLocation': 'Pune',
        'destination': 'Mumbai',
        'createdAt': DateTime.now().subtract(Duration(days: 1)),
      },
    ];
    _applications = [
      {'jobId': 'j1', 'driverId': 'd2', 'status': 'pending'},
      {'jobId': 'j2', 'driverId': 'd1', 'status': 'accepted'},
      {'jobId': 'j2', 'driverId': 'd3', 'status': 'pending'},
    ];
  }


  Widget _buildDashboardOverview() {
    final totalDrivers = _drivers.length;
    final activeDrivers = _drivers.where((d) => d['status'] == 'active').length;
    final pendingApplications = 0; // Placeholder, to be implemented
    final totalDeliveries = _drivers.fold<int>(0, (sum, d) => sum + ((d['totalDeliveries'] ?? 0) as int));
    final earnings = 0; // Placeholder, to be implemented
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.gridSpacing,
            mainAxisSpacing: AppTheme.gridSpacing,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Total Drivers', totalDrivers.toString(), Icons.people),
              _buildStatCard('Active Drivers', activeDrivers.toString(), Icons.directions_car),
              _buildStatCard('Pending Apps', pendingApplications.toString(), Icons.hourglass_empty),
              _buildStatCard('Deliveries', totalDeliveries.toString(), Icons.local_shipping),
              _buildStatCard('Earnings', '₹$earnings', Icons.attach_money),
            ],
          ),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTheme.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showAddDriverDialog,
                icon: Icon(Icons.person_add),
                label: Text('Add Driver'),
                style: AppTheme.elevatedHomeButtonStyle,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showAssignJobDialog,
                icon: Icon(Icons.assignment),
                label: Text('Assign Job'),
                style: AppTheme.elevatedHomeButtonStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(value, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.bodyMedium.copyWith(color: Colors.grey)),
        ],
      ),
    );
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

  void _showDriverDetails(Map<String, dynamic> driver) {
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
                        driver['name'],
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
                          color: driver['status'] == 'active'
                              ? Color(0xFF6B5ECD).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          driver['status'].toUpperCase(),
                          style: TextStyle(
                            color: driver['status'] == 'active'
                                ? Color(0xFF6B5ECD)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Phone: ${driver['phone']}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Driver Information', [
                      {'Rating': '${driver['rating']} ⭐'},
                      {
                        'Total Deliveries': driver['totalDeliveries'].toString()
                      },
                      {'Current Location': driver['currentLocation']},
                    ]),
                    SizedBox(height: 24),
                    _buildDetailSection('Activity Information', [
                      {'Status': driver['status'].toUpperCase()},
                      {'Last Active': _formatTimeAgo(driver['lastActive'])},
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Map<String, String>> details) {
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
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: details.map((detail) {
              final entry = detail.entries.first;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return Center(
      child: Text('Analytics coming soon...', style: AppTheme.bodyLarge),
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.paddingMedium),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                  driver['name'],
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: driver['status'] == 'active'
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : AppTheme.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  driver['status'].toUpperCase(),
                  style: AppTheme.bodyMedium.copyWith(
                    color: driver['status'] == 'active'
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            'Phone: ${driver['phone']}',
            style: AppTheme.bodyMedium,
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
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        title: const Text('Broker Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Drivers'),
            Tab(icon: Icon(Icons.assignment), text: 'Jobs'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDashboardOverview(),
          SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppTheme.paddingLarge),
                Text('Your Drivers', style: AppTheme.headingMedium),
                SizedBox(height: AppTheme.paddingMedium),
                for (var driver in _drivers) _buildDriverCard(driver),
              ],
            ),
          ),
          _buildAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.person_add, color: AppTheme.textPrimary),
      ),
    );
  }
}
