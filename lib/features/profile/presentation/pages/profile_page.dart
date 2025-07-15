import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'profile_completion_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}


class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await SupabaseService.getUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildProfileItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _profile?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Information
                  if (_profile != null) ...[
                    _buildProfileItem(
                      title: 'Full Name',
                      value: _profile!.fullName ?? 'Not set',
                      icon: Icons.person_outline,
                    ),
                    _buildProfileItem(
                      title: 'Email',
                      value: _profile!.email,
                      icon: Icons.email_outlined,
                    ),
                    _buildProfileItem(
                      title: 'Role',
                      value: _profile!.role,
                      icon: Icons.verified_user,
                    ),
                    if (_profile!.warehouseDetails != null) ...[
                      _buildProfileItem(
                        title: 'Warehouse Name',
                        value: _profile!.warehouseDetails!['warehouse_name']?.toString() ?? 'Not set',
                        icon: Icons.home_work,
                      ),
                      _buildProfileItem(
                        title: 'Storage Capacity',
                        value: _profile!.warehouseDetails!['storage_capacity']?.toString() ?? 'Not set',
                        icon: Icons.store,
                      ),
                      _buildProfileItem(
                        title: 'Operating Hours',
                        value: _profile!.warehouseDetails!['operating_hours']?.toString() ?? 'Not set',
                        icon: Icons.access_time,
                      ),
                    ],
                    if (_profile!.driverDetails != null) ...[
                      _buildProfileItem(
                        title: 'License Number',
                        value: _profile!.driverDetails!['license_number']?.toString() ?? 'Not set',
                        icon: Icons.badge,
                      ),
                      _buildProfileItem(
                        title: 'License Expiry',
                        value: _profile!.driverDetails!['license_expiry']?.toString() ?? 'Not set',
                        icon: Icons.event,
                      ),
                      _buildProfileItem(
                        title: 'Vehicle Type',
                        value: _profile!.driverDetails!['vehicle_type']?.toString() ?? 'Not set',
                        icon: Icons.local_shipping,
                      ),
                      _buildProfileItem(
                        title: 'Years of Experience',
                        value: _profile!.driverDetails!['experience_years']?.toString() ?? 'Not set',
                        icon: Icons.timeline,
                      ),
                    ],
                    if (_profile!.brokerDetails != null) ...[
                      _buildProfileItem(
                        title: 'Company Name',
                        value: _profile!.brokerDetails!['company_name']?.toString() ?? 'Not set',
                        icon: Icons.business,
                      ),
                      _buildProfileItem(
                        title: 'Registration Number',
                        value: _profile!.brokerDetails!['registration_number']?.toString() ?? 'Not set',
                        icon: Icons.confirmation_number,
                      ),
                      _buildProfileItem(
                        title: 'Years in Business',
                        value: _profile!.brokerDetails!['years_in_business']?.toString() ?? 'Not set',
                        icon: Icons.calendar_today,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_profile == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileCompletionPage(
                              userId: _profile!.id,
                              role: _profile!.role,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  // Logout Button
                  ElevatedButton(
                    onPressed: () async {
                      await SupabaseService.signOut();
                      if (mounted) {
                        setState(() {
                          _profile = null;
                        });
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
