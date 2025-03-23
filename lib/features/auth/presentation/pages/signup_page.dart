import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../profile/presentation/pages/profile_completion_page.dart';
import 'login_page.dart';

enum UserRole {
  driver,
  warehouseOwner,
  broker,
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.driver;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.warehouseOwner:
        return 'Warehouse Owner';
      case UserRole.broker:
        return 'Broker';
    }
  }

  String _getRoleDatabaseValue(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return 'driver';
      case UserRole.warehouseOwner:
        return 'warehouse_owner';
      case UserRole.broker:
        return 'broker';
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        role: _getRoleDatabaseValue(_selectedRole),
      );

      if (!mounted) return;

      if (response.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
            backgroundColor: AppTheme.accentError,
          ),
        );
        return;
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Account created successfully! Please check your email for verification.'),
          backgroundColor: AppTheme.accentSuccess,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to login page immediately
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'An error occurred during signup';

      // Parse the error message
      final error = e.toString().toLowerCase();
      if (error.contains('already registered')) {
        errorMessage = 'This email is already registered';
      } else if (error.contains('invalid email')) {
        errorMessage = 'Please enter a valid email address';
      } else if (error.contains('weak password')) {
        errorMessage = 'Password is too weak. Please use a stronger password';
      } else if (error.contains('network')) {
        errorMessage = 'Network error. Please check your connection';
      }

      print('Signup error details: $e'); // For debugging

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.accentError,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppTheme.paddingLarge,
            0,
            AppTheme.paddingLarge,
            AppTheme.paddingLarge + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: AppTheme.paddingLarge),
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(AppTheme.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create Account',
                        style: AppTheme.headingLarge.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingSmall),
                      Text(
                        'Sign up to get started',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserRole>(
                            value: _selectedRole,
                            dropdownColor: Colors.black,
                            style: AppTheme.bodyLarge
                                .copyWith(color: Colors.white),
                            icon:
                                Icon(Icons.arrow_drop_down, color: Colors.red),
                            isExpanded: true,
                            items: UserRole.values.map((UserRole role) {
                              return DropdownMenuItem<UserRole>(
                                value: role,
                                child: Text(
                                  _getRoleDisplayName(role),
                                  style: AppTheme.bodyLarge
                                      .copyWith(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (UserRole? newValue) {
                              if (newValue != null) {
                                setState(() => _selectedRole = newValue);
                              }
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      TextFormField(
                        controller: _fullNameController,
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.person, color: Colors.red),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          errorStyle:
                              TextStyle(color: Colors.red.withOpacity(0.7)),
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      TextFormField(
                        controller: _emailController,
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.email, color: Colors.red),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          errorStyle:
                              TextStyle(color: Colors.red.withOpacity(0.7)),
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      TextFormField(
                        controller: _passwordController,
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.lock, color: Colors.red),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          errorStyle:
                              TextStyle(color: Colors.red.withOpacity(0.7)),
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      TextFormField(
                        controller: _confirmPasswordController,
                        style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.lock, color: Colors.red),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.red.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide:
                                BorderSide(color: Colors.red.withOpacity(0.5)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          errorStyle:
                              TextStyle(color: Colors.red.withOpacity(0.7)),
                        ),
                      ),
                      SizedBox(height: AppTheme.paddingLarge),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: Text(
                          'Already have an account? Login',
                          style: AppTheme.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
