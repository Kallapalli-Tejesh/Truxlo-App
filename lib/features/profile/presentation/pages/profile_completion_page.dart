import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../home/presentation/pages/home_page.dart';

class ProfileCompletionPage extends StatefulWidget {
  final String userId;
  final String role;

  const ProfileCompletionPage({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Common controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // Driver-specific controllers
  final _licenseNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  DateTime? _licenseExpiry;

  // Warehouse-specific controllers
  final _warehouseNameController = TextEditingController();
  final _storageCapacityController = TextEditingController();
  final _operatingHoursController = TextEditingController();

  // Broker-specific controllers
  final _companyNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _yearsInBusinessController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(() => _licenseExpiry = picked);
    }
  }

  Future<void> _submitDriverProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Update driver details
      await SupabaseService.updateRoleDetails(
        widget.userId,
        'driver',
        {
          'license_number': _licenseNumberController.text,
          'license_expiry': _licenseExpiry?.toIso8601String(),
          'vehicle_type': _vehicleTypeController.text,
          'experience_years':
              int.tryParse(_experienceYearsController.text) ?? 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Update common profile details
      await SupabaseService.updateProfile(
        widget.userId,
        {
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'is_profile_complete': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitWarehouseProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Update warehouse details
      await SupabaseService.updateRoleDetails(
        widget.userId,
        'warehouse_owner',
        {
          'warehouse_name': _warehouseNameController.text,
          'storage_capacity':
              double.tryParse(_storageCapacityController.text) ?? 0,
          'operating_hours': _operatingHoursController.text,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Update common profile details
      await SupabaseService.updateProfile(
        widget.userId,
        {
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'is_profile_complete': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitBrokerProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Update broker details
      await SupabaseService.updateRoleDetails(
        widget.userId,
        'broker',
        {
          'company_name': _companyNameController.text,
          'registration_number': _registrationNumberController.text,
          'years_in_business':
              int.tryParse(_yearsInBusinessController.text) ?? 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      // Update common profile details
      await SupabaseService.updateProfile(
        widget.userId,
        {
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'is_profile_complete': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCommonFields() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            hintText: 'Enter your address',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter your city',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  hintText: 'Enter your state',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverFields() {
    return Column(
      children: [
        TextFormField(
          controller: _licenseNumberController,
          decoration: InputDecoration(
            labelText: 'License Number',
            hintText: 'Enter your license number',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your license number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'License Expiry',
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _licenseExpiry != null
                  ? '${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}'
                  : 'Select expiry date',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _vehicleTypeController,
          decoration: InputDecoration(
            labelText: 'Vehicle Type',
            hintText: 'Enter your vehicle type',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your vehicle type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _experienceYearsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Years of Experience',
            hintText: 'Enter your years of experience',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your years of experience';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWarehouseFields() {
    return Column(
      children: [
        TextFormField(
          controller: _warehouseNameController,
          decoration: InputDecoration(
            labelText: 'Warehouse Name',
            hintText: 'Enter your warehouse name',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your warehouse name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _storageCapacityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Storage Capacity (sq ft)',
            hintText: 'Enter storage capacity',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter storage capacity';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _operatingHoursController,
          decoration: InputDecoration(
            labelText: 'Operating Hours',
            hintText: 'e.g., Mon-Fri 9AM-5PM',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter operating hours';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBrokerFields() {
    return Column(
      children: [
        TextFormField(
          controller: _companyNameController,
          decoration: InputDecoration(
            labelText: 'Company Name',
            hintText: 'Enter your company name',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your company name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _registrationNumberController,
          decoration: InputDecoration(
            labelText: 'Registration Number',
            hintText: 'Enter company registration number',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter registration number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _yearsInBusinessController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Years in Business',
            hintText: 'Enter years in business',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter years in business';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCommonFields(),
                const SizedBox(height: 24),
                Text(
                  '${widget.role.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')} Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.role == 'driver') _buildDriverFields(),
                if (widget.role == 'warehouse_owner') _buildWarehouseFields(),
                if (widget.role == 'broker') _buildBrokerFields(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          switch (widget.role) {
                            case 'driver':
                              _submitDriverProfile();
                              break;
                            case 'warehouse_owner':
                              _submitWarehouseProfile();
                              break;
                            case 'broker':
                              _submitBrokerProfile();
                              break;
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Complete Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _licenseNumberController.dispose();
    _vehicleTypeController.dispose();
    _experienceYearsController.dispose();
    _warehouseNameController.dispose();
    _storageCapacityController.dispose();
    _operatingHoursController.dispose();
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _yearsInBusinessController.dispose();
    super.dispose();
  }
}
