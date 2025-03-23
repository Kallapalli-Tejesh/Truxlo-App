import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';

class BrokerHomePage extends StatefulWidget {
  const BrokerHomePage({super.key});

  @override
  State<BrokerHomePage> createState() => _BrokerHomePageState();
}

class _BrokerHomePageState extends State<BrokerHomePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _drivers = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDrivers();
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

  void _loadDrivers() {
    // Placeholder data for demonstration
    setState(() {
      _drivers = [
        {
          'id': '1',
          'name': 'John Doe',
          'phone': '+91 98765 43210',
          'status': 'active',
          'rating': 4.5,
          'totalDeliveries': 25,
          'currentLocation': 'Mumbai',
          'lastActive': DateTime.now().subtract(Duration(hours: 2)),
        },
        {
          'id': '2',
          'name': 'Rajesh Kumar',
          'phone': '+91 98765 43211',
          'status': 'inactive',
          'rating': 4.2,
          'totalDeliveries': 18,
          'currentLocation': 'Delhi',
          'lastActive': DateTime.now().subtract(Duration(days: 1)),
        },
        {
          'id': '3',
          'name': 'Amit Singh',
          'phone': '+91 98765 43212',
          'status': 'active',
          'rating': 4.8,
          'totalDeliveries': 32,
          'currentLocation': 'Bangalore',
          'lastActive': DateTime.now().subtract(Duration(hours: 1)),
        },
      ];
    });
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

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    return GestureDetector(
      onTap: () => _showDriverDetails(driver),
      child: Container(
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
          'Broker Dashboard',
          style: AppTheme.headingMedium,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadDrivers,
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${_profile!['full_name']}',
                    style: AppTheme.headingLarge,
                  ),
                  SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    'Broker',
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              'Your Drivers',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: AppTheme.paddingMedium),
            ..._drivers.map((driver) => _buildDriverCard(driver)).toList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add driver functionality
        },
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.person_add, color: AppTheme.textPrimary),
      ),
    );
  }
}
