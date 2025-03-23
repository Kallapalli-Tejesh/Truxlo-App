import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.accentError,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (mounted && response.user != null) {
        final fullName =
            await SupabaseService.getUserFullName(response.user!.id);
        print('Logged in user name: $fullName');

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Invalid Credentials';
        print('Login error details: $e'); // For debugging

        if (e is AuthException) {
          if (e.message.contains('Email not confirmed')) {
            errorMessage = 'Please verify your email address before logging in';
          } else if (e.message.contains('Invalid login credentials')) {
            errorMessage = 'Invalid email or password';
          } else if (e.message.contains('rate limit')) {
            errorMessage = 'Too many attempts. Please try again later';
          } else if (e.message.contains('network')) {
            errorMessage = 'Network error. Please check your connection';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.accentError,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.paddingLarge,
              AppTheme.paddingLarge,
              AppTheme.paddingLarge,
              AppTheme.paddingLarge + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo with subtle background
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.paddingLarge * 2),
                  // Login form card
                  Container(
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
                          'Welcome Back',
                          style: AppTheme.headingLarge.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        Text(
                          'Login to continue',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: AppTheme.paddingLarge),
                        TextField(
                          controller: _emailController,
                          style:
                              AppTheme.bodyLarge.copyWith(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.email, color: Colors.red),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        SizedBox(height: AppTheme.paddingMedium),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style:
                              AppTheme.bodyLarge.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.lock, color: Colors.red),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
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
                          ),
                        ),
                        SizedBox(height: AppTheme.paddingLarge),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
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
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppTheme.paddingLarge),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(
                      "Don't have an account? Sign up",
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
