# Project Source Code and Configuration Dump

## 1. Core Entry and Configuration

### File: `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truxlo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: Supabase.instance.client.auth.currentUser != null
          ? const HomePage()
          : const LoginPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Truxlo')),
      body: const Center(child: Text('Welcome to Truxlo')),
    );
  }
}

```

### File: `lib/core/app_config.dart`
```dart
import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'Truxlo';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
    );
  }
}

```

### File: `lib/core/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFFE53935); // Main red color
  static const Color primaryDark = Color(0xFFC62828); // Darker red shade
  static const Color primaryLight = Color(0xFFEF5350); // Lighter red shade

  // Background Colors
  static const Color backgroundColor = Color(0xFF121212); // Darker background
  static const Color surfaceColor = Color(0xFF1E1E1E); // Surface color
  static const Color cardColor = Color(0xFF2D2D2D); // Card background

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF8A8A8A);

  // Accent Colors
  static const Color accentSuccess = Color(0xFF43A047); // Green
  static const Color accentError = Color(0xFFD32F2F); // Error red
  static const Color accentWarning = Color(0xFFFFA000); // Warning orange

  // Border and Divider Colors
  static const Color borderColor = Color(0xFF3D3D3D);

  // Opacity Levels
  static const double emphasisHigh = 1.0;
  static const double emphasisMedium = 0.74;
  static const double emphasisLow = 0.38;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  // Input Decoration Theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor.withOpacity(0.5),
    hintStyle: bodyMedium.copyWith(color: textHint),
    prefixIconColor: primaryColor,
    suffixIconColor: textHint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: accentError),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: const BorderSide(color: accentError, width: 2),
    ),
  );

  // Button Theme
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: textPrimary,
      padding: const EdgeInsets.symmetric(vertical: paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      elevation: 0,
      shadowColor: primaryColor.withOpacity(0.3),
    ).copyWith(
      overlayColor: MaterialStateProperty.resolveWith<Color?>(
        (Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return primaryDark;
          }
          if (states.contains(MaterialState.hovered)) {
            return primaryLight;
          }
          return null;
        },
      ),
    ),
  );

  // Card Theme
  static CardTheme cardTheme = CardTheme(
    color: cardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
  );

  // Snackbar Theme
  static SnackBarThemeData snackBarTheme = SnackBarThemeData(
    backgroundColor: surfaceColor,
    contentTextStyle: bodyMedium,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radiusMedium)),
    ),
    elevation: 4,
    actionTextColor: primaryLight,
  );

  // App Bar Theme
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: backgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryColor),
    titleTextStyle: headingMedium,
  );

  // Get ThemeData
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        headlineLarge: headingLarge,
        headlineMedium: headingMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: buttonText,
      ),
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      cardTheme: cardTheme,
      snackBarTheme: snackBarTheme,
      appBarTheme: appBarTheme,
      iconTheme: IconThemeData(color: primaryColor),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryLight,
        surface: surfaceColor,
        background: backgroundColor,
        error: accentError,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
        brightness: Brightness.dark,
      ),
    );
  }
}

```

---

## 2. Core Services

### File: `lib/core/services/supabase_service.dart`
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/domain/models/user_profile.dart';
import '../../features/jobs/domain/models/job.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<void> initialize() async {
    await dotenv.load();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phone,
  }) async {
    try {
      debugPrint('Starting signup process for email: $email');
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'phone': phone ?? '',
          'is_profile_complete': false,
        },
      );

      if (response.user != null) {
        debugPrint('User created successfully with ID: ${response.user!.id}');
        
        // Wait a moment for the trigger to create the profile
        await Future.delayed(const Duration(milliseconds: 1000));
        
        try {
          // Verify that the profile was created
          final profile = await client
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .single();
              
          if (profile == null) {
            debugPrint('Warning: Profile not found after creation, attempting to create manually');
            // Try to create the profile manually if the trigger failed
            await client.from('profiles').insert({
              'id': response.user!.id,
              'email': email,
              'full_name': fullName,
              'phone': phone ?? '',
              'role': role,
              'is_profile_complete': false,
              'created_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
            debugPrint('Profile created manually');
          }
          
          debugPrint('Profile verified: $profile');

          // Update the profile with phone if provided
          if (phone != null && phone.isNotEmpty) {
            await client.from('profiles')
                .update({'phone': phone})
                .eq('id', response.user!.id);
          }
          
          debugPrint('Profile updated successfully');

          // Create role-specific details
          final roleTable = _getRoleTable(role);
          if (roleTable != null) {
            debugPrint('Creating role-specific details in table: $roleTable');
            try {
              await client.from(roleTable).insert({
                'user_id': response.user!.id,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }).select();
              debugPrint('Role-specific details created successfully');
            } catch (e) {
              debugPrint('Warning: Failed to create role-specific details: $e');
              // Don't throw here - the user can still sign in and complete their profile later
            }
          }
        } catch (e) {
          debugPrint('Warning: Error during profile setup: $e');
          debugPrint('Stack trace: ${StackTrace.current}');
          // Don't throw here - the user can still sign in and complete their profile later
        }
      }

      return response;
    } catch (e) {
      debugPrint('Supabase signup error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<String?> getUserFullName(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      return response['full_name'] as String?;
    } catch (e) {
      print('Error getting user full name: $e');
      return null;
    }
  }

  static Future<UserProfile?> getUserProfile() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Error: No user ID found in getUserProfile');
        return null;
      }

      debugPrint('Fetching profile for user: $userId');
      
      // First, get the basic profile without any joins
      final profileResponse = await client
          .from('profiles')
          .select('id, email, full_name, role, is_profile_complete, updated_at')
          .eq('id', userId)
          .single();
          
      debugPrint('Basic profile response: $profileResponse');

      if (profileResponse == null) {
        debugPrint('No profile found for user: $userId');
        return null;
      }

      // Then, based on the role, fetch the role-specific details
      final role = profileResponse['role'] as String;
      final roleTable = _getRoleTable(role);
      Map<String, dynamic>? roleDetails;
      
      if (roleTable != null) {
        debugPrint('Fetching role details from table: $roleTable');
        try {
          final roleResponse = await client
              .from(roleTable)
              .select()
              .eq('user_id', userId)
              .maybeSingle();
              
          debugPrint('Role details response: $roleResponse');
          roleDetails = roleResponse;
        } catch (e) {
          debugPrint('Error fetching role details: $e');
          // Continue without role details
        }
      }

      // Combine the data
      final Map<String, dynamic> combinedProfile = Map.from(profileResponse);
      if (roleDetails != null) {
        switch (role) {
          case 'warehouse_owner':
            combinedProfile['warehouse_details'] = roleDetails;
            break;
          case 'driver':
            combinedProfile['driver_details'] = roleDetails;
            break;
          case 'broker':
            combinedProfile['broker_details'] = roleDetails;
            break;
        }
      }
      
      debugPrint('Combined profile data: $combinedProfile');
      return UserProfile.fromJson(combinedProfile);
    } catch (e, stackTrace) {
      debugPrint('Error in getUserProfile: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getRoleDetails(
    String userId,
    String role,
  ) async {
    final roleTable = _getRoleTable(role);
    if (roleTable == null) return null;

    final response =
        await client.from(roleTable).select().eq('user_id', userId).single();
    return response;
  }

  static Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    await client.from('profiles').update(data).eq('id', userId);
  }

  static Future<void> updateRoleDetails(
    String userId,
    String role,
    Map<String, dynamic> data,
  ) async {
    final roleTable = _getRoleTable(role);
    if (roleTable != null) {
      await client.from(roleTable).update(data).eq('user_id', userId);
    }
  }

  static String? _getRoleTable(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return 'driver_details';
      case 'warehouse_owner':
        return 'warehouse_details';
      case 'broker':
        return 'broker_details';
      default:
        return null;
    }
  }

  // Broker-related methods
  static Future<Map<String, dynamic>> addDriverForBroker({
    required String brokerId,
    required String fullName,
    required String phone,
  }) async {
    try {
      // Check if driver already exists by phone
      final existing = await client.from('profiles').select().eq('phone', phone).maybeSingle();
      if (existing != null) {
        throw Exception('A user with this phone number already exists.');
      }
      // Create profile
      final profileRes = await client.from('profiles').insert({
        'full_name': fullName,
        'phone': phone,
        'role': 'driver',
        'is_profile_complete': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();
      final driverId = profileRes['id'];
      // Create driver_details
      await client.from('driver_details').insert({
        'user_id': driverId,
        'broker_id': brokerId,
        'status': 'inactive',
        'rating': 0,
        'total_deliveries': 0,
        'current_location': '',
        'last_active': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return profileRes;
    } catch (e) {
      debugPrint('Error adding driver for broker: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getBrokerDrivers(String brokerId) async {
    try {
      // Join driver_details with profiles, filter by broker_id
      final response = await client
          .from('driver_details')
          .select('''
            user_id,
            status,
            rating,
            total_deliveries,
            current_location,
            last_active,
            broker_id,
            profiles!driver_details_user_id_fkey (
              id,
              full_name,
              phone
            )
          ''')
          .eq('broker_id', brokerId);
      return List<Map<String, dynamic>>.from(response.map((d) => {
        'id': d['profiles']?['id'] ?? '',
        'name': d['profiles']?['full_name'] ?? '',
        'phone': d['profiles']?['phone'] ?? '',
        'status': d['status'] ?? 'inactive',
        'rating': (d['rating'] ?? 0).toDouble(),
        'totalDeliveries': d['total_deliveries'] ?? 0,
        'currentLocation': d['current_location'] ?? '',
        'lastActive': d['last_active'] != null ? DateTime.tryParse(d['last_active']) : null,
      }));
    } catch (e) {
      debugPrint('Error fetching broker drivers: $e');
      rethrow;
    }
  }

// Job-related methods
  static Future<String> postJob(Map<String, dynamic> jobData) async {
    final response =
        await client.from('jobs').insert(jobData).select().single();
    return response['id'];
  }

  static Future<List<Map<String, dynamic>>> getOpenJobs() async {
    try {
      debugPrint('Querying open jobs from database...');

      final response = await client.from('jobs').select('''
        id,
        title,
        description,
        goods_type,
        weight,
        price,
        pickup_location,
        destination,
        distance,
        job_status,
        posted_date,
        assigned_date,
        completion_date,
        created_at,
        updated_at,
        warehouse_owner_id,
        assigned_driver_id,
        warehouse_owner:profiles!jobs_warehouse_owner_id_fkey (
          id,
          email,
          full_name,
          role,
          is_profile_complete
        )
      ''').eq('job_status', 'open')
        .order('posted_date', ascending: false);

      debugPrint('Open jobs response: $response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      debugPrint('Error in getOpenJobs: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getWarehouseOwnerJobs(String warehouseOwnerId) async {
    try {
      final response = await client.from('jobs').select('''
        id,
        title,
        description,
        goods_type,
        weight,
        price,
        pickup_location,
        destination,
        distance,
        job_status,
        posted_date,
        assigned_date,
        completion_date,
        created_at,
        updated_at,
        warehouse_owner_id,
        assigned_driver_id,
        warehouse_owner:profiles!jobs_warehouse_owner_id_fkey (
          id,
          email,
          full_name,
          role,
          is_profile_complete
        ),
        assigned_driver:profiles!jobs_assigned_driver_id_fkey (
          id,
          email,
          full_name,
          role,
          is_profile_complete
        )
      ''').eq('warehouse_owner_id', warehouseOwnerId)
        .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting warehouse owner jobs: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverJobs(String driverId) async {
    try {
      final response = await client.from('jobs').select('''
        id,
        title,
        description,
        goods_type,
        weight,
        price,
        pickup_location,
        destination,
        distance,
        job_status,
        posted_date,
        assigned_date,
        completion_date,
        created_at,
        updated_at,
        warehouse_owner_id,
        assigned_driver_id,
        warehouse_owner:profiles!jobs_warehouse_owner_id_fkey (
          id,
          email,
          full_name,
          role,
          is_profile_complete
        )
      ''').eq('assigned_driver_id', driverId)
        .order('assigned_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting driver jobs: $e');
      rethrow;
    }
  }

  static Future<bool> hasActiveJob(String driverId) async {
    try {
      final response = await client
          .from('jobs')
          .select('id')
          .eq('assigned_driver_id', driverId)
          .or('job_status.in.(assigned,awaitingPickupVerification,inTransit)')
          .limit(1)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking active job status: $e');
      rethrow;
    }
  }

  static Future<void> applyForJob(String jobId, String driverId) async {
    try {
      // Check if driver has active jobs
      final hasActive = await hasActiveJob(driverId);
      if (hasActive) {
        throw Exception(
            'You already have an active job. Please complete your current job before applying for new ones.');
      }

      // Check if job is still open
      final job = await client.from('jobs').select('job_status').eq('id', jobId).single();
      if (job['job_status'] != 'open') {
        throw Exception('This job is no longer available');
      }

      // Check if driver has already applied
      final existingApplication = await client
          .from('job_applications')
          .select('id')
          .eq('job_id', jobId)
          .eq('driver_id', driverId)
          .maybeSingle();

      if (existingApplication != null) {
        throw Exception('You have already applied for this job');
      }

      final now = DateTime.now().toUtc();
      await client.from('job_applications').insert({
        'job_id': jobId,
        'driver_id': driverId,
        'status': 'pending',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error applying for job: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getJobApplications(String jobId) async {
    try {
      debugPrint('Fetching job applications for job ID: $jobId');
      final response = await client
          .from('job_applications')
          .select('''
            id,
            job_id,
            driver_id,
            status,
            created_at,
            updated_at,
            driver:profiles!job_applications_driver_id_fkey (
              id,
              email,
              full_name,
              role,
              is_profile_complete,
              phone
            )
          ''')
          .eq('job_id', jobId)
          .order('created_at', ascending: false);
      
      debugPrint('Raw response from database: $response');
      final applications = List<Map<String, dynamic>>.from(response);
      debugPrint('Number of applications found: ${applications.length}');
      
      for (var app in applications) {
        debugPrint('Application data:');
        debugPrint('  ID: ${app['id']}');
        debugPrint('  Job ID: ${app['job_id']}');
        debugPrint('  Driver ID: ${app['driver_id']}');
        debugPrint('  Status: ${app['status']}');
        debugPrint('  Driver data: ${app['driver']}');
        
        // If driver data is missing or incomplete, try to fetch it directly
        if (app['driver'] == null || 
            app['driver']['full_name'] == null || 
            app['driver']['email'] == null) {
          try {
            final driverProfile = await client
                .from('profiles')
                .select()
                .eq('id', app['driver_id'])
                .single();
                
            if (driverProfile != null) {
              app['driver'] = {
                'id': driverProfile['id'],
                'email': driverProfile['email'] ?? 'not provided',
                'full_name': driverProfile['full_name'] ?? 'Unknown Driver',
                'role': driverProfile['role'],
                'is_profile_complete': driverProfile['is_profile_complete'],
                'phone': driverProfile['phone'],
              };
              debugPrint('Retrieved missing driver profile: $driverProfile');
            } else {
              debugPrint('Warning: Driver profile not found for ID: ${app['driver_id']}');
              app['driver'] = {
                'id': app['driver_id'],
                'email': 'not provided',
                'full_name': 'Unknown Driver',
                'role': 'driver',
                'is_profile_complete': false,
                'phone': null,
              };
            }
          } catch (e) {
            debugPrint('Error fetching driver profile: $e');
            app['driver'] = {
              'id': app['driver_id'],
              'email': 'not provided',
              'full_name': 'Unknown Driver',
              'role': 'driver',
              'is_profile_complete': false,
              'phone': null,
            };
          }
        }
      }
      
      return applications;
    } catch (e) {
      debugPrint('Error getting job applications: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverApplications(String driverId) async {
    try {
      final response = await client
          .from('job_applications')
          .select('''
            id,
            job_id,
            driver_id,
            status,
            created_at,
            updated_at,
            job:jobs!job_applications_job_id_fkey (
              id,
              title,
              description,
              goods_type,
              weight,
              price,
              pickup_location,
              destination,
              distance,
              job_status,
              posted_date,
              assigned_date,
              completion_date,
              created_at,
              updated_at,
              warehouse_owner:profiles!jobs_warehouse_owner_id_fkey (
                id,
                email,
                full_name,
                role,
                is_profile_complete
              )
            )
          ''')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting driver applications: $e');
      rethrow;
    }
  }

  static Future<void> updateJobStatus(String jobId, String status) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'job_status': status,
        'updated_at': now.toIso8601String(),
      };

      // Add completion date if the job is being marked as completed
      if (status == 'completed') {
        data['completion_date'] = now.toIso8601String();
      }

      await client.from('jobs').update(data).eq('id', jobId);
    } catch (e) {
      debugPrint('Error updating job status: $e');
      rethrow;
    }
  }

  static Future<void> updateApplicationStatus(
    String applicationId,
    String status,
    String jobId, {
    String? driverId,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      
      // Get minimal application details
      final application = await client
          .from('job_applications')
          .select('id, status, job:jobs(job_status)')
          .eq('id', applicationId)
          .single();

      if (application == null) {
        throw Exception('Application not found');
      }

      // If accepting the application
      if (status == 'accepted') {
        // Check if job is still open
        if (application['job']['job_status'] != 'open') {
          throw Exception('This job is no longer available');
        }

        // Check if driver has active jobs
        if (driverId != null) {
          final hasActive = await hasActiveJob(driverId);
          if (hasActive) {
            throw Exception('Driver already has an active job');
          }
        }

        // Update job status and assign driver in one query
        await client.from('jobs').update({
          'job_status': 'assigned',
          'assigned_driver_id': driverId,
          'assigned_date': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }).eq('id', jobId);

        // Reject all other pending applications in one query
        await client
            .from('job_applications')
            .update({
              'status': 'rejected',
              'updated_at': now.toIso8601String(),
            })
            .eq('job_id', jobId)
            .neq('id', applicationId)
            .eq('status', 'pending');
      }

      // Update the application status
      await client.from('job_applications').update({
        'status': status,
        'updated_at': now.toIso8601String(),
      }).eq('id', applicationId);

      debugPrint('Application status updated successfully: $status');
    } catch (e) {
      debugPrint('Error updating application status: $e');
      rethrow;
    }
  }

  static Future<void> startDelivery(String jobId) async {
    try {
      final now = DateTime.now().toUtc();
      
      // Get job details to verify status and get warehouse owner ID
      final job = await client
          .from('jobs')
          .select('job_status, assigned_driver_id, warehouse_owner_id, title')
          .eq('id', jobId)
          .single();

      if (job == null) {
        throw Exception('Job not found');
      }

      if (job['job_status'] != 'assigned') {
        throw Exception('Job is not in assigned status');
      }

      // Verify the current user is the assigned driver
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId != job['assigned_driver_id']) {
        throw Exception('You are not assigned to this job');
      }

      // Update job status to awaiting pickup verification
      await client.from('jobs').update({
        'job_status': 'awaitingPickupVerification',
        'updated_at': now.toIso8601String(),
      }).eq('id', jobId);

      // Create a notification for the warehouse owner
      await client.from('notifications').insert({
        'user_id': job['warehouse_owner_id'],
        'title': 'Pickup Verification Required',
        'message': 'Driver has arrived for pickup verification for job: ${job['title']}',
        'type': 'pickup_verification',
        'job_id': jobId,
        'created_at': now.toIso8601String(),
        'is_read': false,
      });

      debugPrint('Delivery started successfully for job: $jobId');
    } catch (e) {
      debugPrint('Error starting delivery: $e');
      rethrow;
    }
  }

  static RealtimeChannel subscribeToJobs(
      void Function(List<Map<String, dynamic>>) onJobsUpdate) {
    final channel = client.channel('public:jobs');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          callback: (payload) async {
            final jobs = await getOpenJobs();
            onJobsUpdate(jobs);
          },
        )
        .subscribe();

    return channel;
  }

  static RealtimeChannel subscribeToJobApplications(
    String jobId,
    void Function(List<Map<String, dynamic>>) onApplicationsUpdate,
  ) {
    final channel = client.channel('public:job_applications:$jobId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'job_applications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'job_id',
            value: jobId,
          ),
          callback: (payload) async {
            final applications = await getJobApplications(jobId);
            onApplicationsUpdate(applications);
          },
        )
        .subscribe();

    return channel;
  }

  static RealtimeChannel subscribeToDriverJobs(
    String driverId,
    void Function(List<Map<String, dynamic>>) onJobsUpdate,
  ) {
    final channel = client.channel('public:jobs:driver=$driverId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assigned_driver_id',
            value: driverId,
          ),
          callback: (payload) async {
            final jobs = await getDriverJobs(driverId);
            onJobsUpdate(jobs);
          },
        )
        .subscribe();

    return channel;
  }

  static Future<void> verifyPickup(String jobId) async {
    try {
      final now = DateTime.now().toUtc();
      
      // Get job details to verify status and ownership
      final job = await client
          .from('jobs')
          .select('job_status, warehouse_owner_id, assigned_driver_id')
          .eq('id', jobId)
          .single();

      if (job == null) {
        throw Exception('Job not found');
      }

      if (job['job_status'] != 'awaitingPickupVerification') {
        throw Exception('Job is not awaiting pickup verification');
      }

      // Verify the current user is the warehouse owner
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId != job['warehouse_owner_id']) {
        throw Exception('You are not authorized to verify this pickup');
      }

      // Update job status to in transit
      await client.from('jobs').update({
        'job_status': 'inTransit',
        'pickup_verified_at': now.toIso8601String(),
        'pickup_verified_by': currentUserId,
        'updated_at': now.toIso8601String(),
      }).eq('id', jobId);

      debugPrint('Pickup verified successfully for job: $jobId');
    } catch (e) {
      debugPrint('Error verifying pickup: $e');
      rethrow;
    }
  }

  static Future<void> verifyDelivery(String jobId) async {
    try {
      final now = DateTime.now().toUtc();
      final currentUserId = client.auth.currentUser?.id;
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      // Get job details to verify status and ownership
      final job = await client
          .from('jobs')
          .select('job_status, warehouse_owner_id, assigned_driver_id')
          .eq('id', jobId)
          .single();

      if (job == null) {
        throw Exception('Job not found');
      }

      if (job['job_status'] != 'awaitingDeliveryVerification') {
        throw Exception('Job is not awaiting delivery verification');
      }

      // Verify the current user is the warehouse owner
      if (currentUserId != job['warehouse_owner_id']) {
        throw Exception('You are not authorized to verify this delivery');
      }

      // Update job status to completed with all necessary fields
      final response = await client
          .from('jobs')
          .update({
            'job_status': 'completed',
            'delivery_verified_at': now.toIso8601String(),
            'delivery_verified_by': currentUserId,
            'completion_date': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', jobId)
          .eq('job_status', 'awaitingDeliveryVerification')
          .eq('warehouse_owner_id', currentUserId)
          .select();

      debugPrint('Update response: $response');

      if (response == null || response.isEmpty) {
        throw Exception('Failed to update job status');
      }

      debugPrint('Delivery verified successfully for job: $jobId');
    } catch (e) {
      debugPrint('Error verifying delivery: $e');
      rethrow;
    }
  }

  static Future<void> completeDelivery(String jobId) async {
    try {
      debugPrint('Starting completeDelivery for job ID: $jobId');
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First, get the job details to verify the status and ownership
      final jobResponse = await client
          .from('jobs')
          .select('id, job_status, assigned_driver_id')
          .eq('id', jobId)
          .single();

      debugPrint('Job details: $jobResponse');

      if (jobResponse == null) {
        throw Exception('Job not found');
      }

      // Verify that the current user is the assigned driver
      if (jobResponse['assigned_driver_id'] != userId) {
        throw Exception('You are not authorized to complete this delivery');
      }

      // Check current job status and handle accordingly
      final currentStatus = jobResponse['job_status'];
      switch (currentStatus) {
        case 'awaitingDeliveryVerification':
          debugPrint('Job is already awaiting delivery verification');
          return; // Exit without error since the job is already in the correct state
        case 'completed':
          throw Exception('This delivery has already been completed');
        case 'cancelled':
          throw Exception('This delivery has been cancelled');
        case 'inTransit':
          // Proceed with the update
          break;
        default:
          throw Exception('Cannot complete delivery: Job is in $currentStatus status');
      }

      // Update the job status to awaitingDeliveryVerification
      final now = DateTime.now().toUtc();
      final response = await client
          .from('jobs')
          .update({
            'job_status': 'awaitingDeliveryVerification',
            'updated_at': now.toIso8601String(),
          })
          .eq('id', jobId)
          .eq('assigned_driver_id', userId)
          .eq('job_status', 'inTransit');

      debugPrint('Update response: $response');

      if (response == null || response.isEmpty) {
        throw Exception('Failed to update job status');
      }

      debugPrint('Delivery completed successfully');
    } catch (e) {
      debugPrint('Error completing delivery: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }


  static Future<int> getBrokerTotalLoads() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('jobs')
          .select('id')
          .eq('broker_id', currentUserId);

      // Return the number of jobs
      return response.length;
    } catch (e) {
      debugPrint('Error getting broker total loads: $e');
      rethrow;
    }
  }

  static Future<void> inviteDriver({
    required String email,
    required String name,
    required String phone,
  }) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Check if driver already exists
      final existingDriver = await client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .single();

      if (existingDriver != null) {
        // Check if already in broker_drivers
        final existingRelationship = await client
            .from('broker_drivers')
            .select('id')
            .eq('broker_id', currentUserId)
            .eq('driver_id', existingDriver['id'])
            .single();

        if (existingRelationship != null) {
          throw Exception('Driver is already associated with you');
        }

        // Add to broker_drivers
        await client.from('broker_drivers').insert({
          'broker_id': currentUserId,
          'driver_id': existingDriver['id'],
          'status': 'pending',
        });
      } else {
        // Create new user and profile
        final authResponse = await client.auth.admin.createUser(
          AdminUserAttributes(
            email: email,
          ),
        );

        if (authResponse.user == null) {
          throw Exception('Failed to create user');
        }

        // Create profile
        await client.from('profiles').insert({
          'id': authResponse.user!.id,
          'email': email,
          'full_name': name,
          'phone': phone,
          'role': 'driver',
        });

        // Add to broker_drivers
        await client.from('broker_drivers').insert({
          'broker_id': currentUserId,
          'driver_id': authResponse.user!.id,
          'status': 'pending',
        });
      }
    } catch (e) {
      debugPrint('Error inviting driver: $e');
      rethrow;
    }
  }

  static Future<void> removeDriver(String driverId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await client
          .from('broker_drivers')
          .delete()
          .eq('broker_id', currentUserId)
          .eq('driver_id', driverId);
    } catch (e) {
      debugPrint('Error removing driver: $e');
      rethrow;
    }
  }

  static Future<void> updateDriverStatus(String driverId, String status) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await client
          .from('broker_drivers')
          .update({'status': status})
          .eq('broker_id', currentUserId)
          .eq('driver_id', driverId);
    } catch (e) {
      debugPrint('Error updating driver status: $e');
      rethrow;
    }
  }
}

```

### File: `lib/core/services/broker_service.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class BrokerService {
  static final _client = Supabase.instance.client;

  // Add a driver to broker's network
  static Future<void> addDriver({
    required String brokerId,
    required String driverPhone,
  }) async {
    try {
      // First, find the driver by phone number
      final driverProfile = await _client
          .from('profiles')
          .select()
          .eq('phone', driverPhone)
          .eq('role', 'driver')
          .single();

      if (driverProfile == null) {
        throw Exception('Driver not found');
      }

      // Check if relationship already exists
      final existingRelation = await _client
          .from('broker_drivers')
          .select()
          .eq('broker_id', brokerId)
          .eq('driver_id', driverProfile['id'])
          .maybeSingle();

      if (existingRelation != null) {
        if (existingRelation['status'] == 'active') {
          throw Exception('Driver is already in your network');
        } else if (existingRelation['status'] == 'pending') {
          throw Exception('Invitation already sent to this driver');
        }
      }

      // Create new relationship
      await _client.from('broker_drivers').insert({
        'broker_id': brokerId,
        'driver_id': driverProfile['id'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all drivers in broker's network
  static Future<List<Map<String, dynamic>>> getDrivers(String brokerId) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            driver:driver_id (
              id,
              full_name,
              phone,
              address,
              city,
              state
            )
          ''').eq('broker_id', brokerId).eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get pending driver invitations
  static Future<List<Map<String, dynamic>>> getPendingInvitations(
    String brokerId,
  ) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            driver:driver_id (
              id,
              full_name,
              phone,
              address,
              city,
              state
            )
          ''').eq('broker_id', brokerId).eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Accept or reject broker invitation (for drivers)
  static Future<void> respondToInvitation({
    required String driverId,
    required String brokerId,
    required bool accept,
  }) async {
    try {
      await _client
          .from('broker_drivers')
          .update({
            'status': accept ? 'active' : 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('broker_id', brokerId)
          .eq('driver_id', driverId);
    } catch (e) {
      rethrow;
    }
  }

  // Remove driver from network
  static Future<void> removeDriver({
    required String brokerId,
    required String driverId,
  }) async {
    try {
      await _client
          .from('broker_drivers')
          .update({
            'status': 'removed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('broker_id', brokerId)
          .eq('driver_id', driverId);
    } catch (e) {
      rethrow;
    }
  }

  // Get broker invitations for a driver
  static Future<List<Map<String, dynamic>>> getDriverInvitations(
    String driverId,
  ) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            broker:broker_id (
              id,
              full_name,
              phone,
              company_name:broker_details(company_name)
            )
          ''').eq('driver_id', driverId).eq('status', 'pending');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get all brokers for a driver
  static Future<List<Map<String, dynamic>>> getDriverBrokers(
    String driverId,
  ) async {
    try {
      final response = await _client.from('broker_drivers').select('''
            *,
            broker:broker_id (
              id,
              full_name,
              phone,
              company_name:broker_details(company_name)
            )
          ''').eq('driver_id', driverId).eq('status', 'active');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }
}

```

---

## 3. Auth Feature

### File: `lib/features/auth/presentation/pages/login_page.dart`
```dart
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
                        'assets/images/Truxlo-removebg-preview.png',
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

```

### File: `lib/features/auth/presentation/pages/signup_page.dart`
```dart
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
                    'assets/images/Truxlo-removebg-preview.png',
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

```

### File: `lib/features/auth/domain/models/user_profile.dart`
```dart
import 'package:flutter/foundation.dart';

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final bool isProfileComplete;
  final DateTime? updatedAt;
  final Map<String, dynamic>? warehouseDetails;
  final Map<String, dynamic>? driverDetails;
  final Map<String, dynamic>? brokerDetails;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.isProfileComplete,
    this.updatedAt,
    this.warehouseDetails,
    this.driverDetails,
    this.brokerDetails,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing UserProfile from JSON: $json');
      
      final id = json['id'] as String?;
      final email = json['email'] as String?;
      final fullName = json['full_name'] as String?;
      final role = json['role'] as String?;
      final isProfileComplete = json['is_profile_complete'] as bool?;
      final updatedAt = json['updated_at'] as String?;
      final warehouseDetails = json['warehouse_details'] as Map<String, dynamic>?;
      final driverDetails = json['driver_details'] as Map<String, dynamic>?;
      final brokerDetails = json['broker_details'] as Map<String, dynamic>?;
      
      debugPrint('Parsed values:');
      debugPrint('id: $id');
      debugPrint('email: $email');
      debugPrint('fullName: $fullName');
      debugPrint('role: $role');
      debugPrint('isProfileComplete: $isProfileComplete');
      debugPrint('updatedAt: $updatedAt');
      debugPrint('warehouseDetails: $warehouseDetails');
      debugPrint('driverDetails: $driverDetails');
      debugPrint('brokerDetails: $brokerDetails');

      if (id == null || id.isEmpty) {
        debugPrint('Warning: UserProfile ID is null or empty');
      }
      if (email == null || email.isEmpty) {
        debugPrint('Warning: UserProfile email is null or empty');
      }
      if (fullName == null || fullName.isEmpty) {
        debugPrint('Warning: UserProfile fullName is null or empty');
      }

      return UserProfile(
        id: id ?? '',
        email: email ?? '',
        fullName: fullName,
        role: role ?? 'user',
        isProfileComplete: isProfileComplete ?? false,
        updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : null,
        warehouseDetails: warehouseDetails,
        driverDetails: driverDetails,
        brokerDetails: brokerDetails,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing UserProfile from JSON: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_profile_complete': isProfileComplete,
      'updated_at': updatedAt?.toIso8601String(),
      'warehouse_details': warehouseDetails,
      'driver_details': driverDetails,
      'broker_details': brokerDetails,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    bool? isProfileComplete,
    DateTime? updatedAt,
    Map<String, dynamic>? warehouseDetails,
    Map<String, dynamic>? driverDetails,
    Map<String, dynamic>? brokerDetails,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      updatedAt: updatedAt ?? this.updatedAt,
      warehouseDetails: warehouseDetails ?? this.warehouseDetails,
      driverDetails: driverDetails ?? this.driverDetails,
      brokerDetails: brokerDetails ?? this.brokerDetails,
    );
  }
} 
```

---

## 4. Broker Feature

### File: `lib/features/broker/presentation/pages/broker_home_page.dart`
```dart
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Total Drivers', totalDrivers.toString(), Icons.people),
              _buildStatCard('Active Drivers', activeDrivers.toString(), Icons.directions_car),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Pending Apps', pendingApplications.toString(), Icons.hourglass_empty),
              _buildStatCard('Deliveries', totalDeliveries.toString(), Icons.local_shipping),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard('Earnings', '₹$earnings', Icons.attach_money),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showAddDriverDialog,
                icon: Icon(Icons.person_add),
                label: Text('Add Driver'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showAssignJobDialog,
                icon: Icon(Icons.assignment),
                label: Text('Assign Job'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(value, style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall ?? AppTheme.bodyMedium),
          ],
        ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
        title: const Text('Broker Dashboard', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Drivers'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
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

```

### File: `lib/features/broker/presentation/pages/manage_drivers_page.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../core/services/broker_service.dart';
import '../../../../core/services/supabase_service.dart';
import 'package:trux/core/theme/app_theme.dart';

class ManageDriversPage extends StatefulWidget {
  const ManageDriversPage({super.key});

  @override
  State<ManageDriversPage> createState() => _ManageDriversPageState();
}

class _ManageDriversPageState extends State<ManageDriversPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _pendingInvitations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final drivers = await BrokerService.getDrivers(userId);
      final pendingInvitations =
          await BrokerService.getPendingInvitations(userId);

      if (mounted) {
        setState(() {
          _drivers = drivers;
          _pendingInvitations = pendingInvitations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _inviteDriver() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      await SupabaseService.inviteDriver(
        email: _emailController.text,
        name: _nameController.text,
        phone: _phoneController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver invited successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inviting driver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeDriver(String driverId, String driverName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Remove Driver',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove $driverName from your network?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      await BrokerService.removeDriver(
        brokerId: userId,
        driverId: driverId,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing driver: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDriverList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    if (_drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No drivers in your network',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _drivers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final driver = _drivers[index]['driver'];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              driver['full_name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  driver['phone'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                if (driver['address'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${driver['address']}, ${driver['city']}, ${driver['state']}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
              ),
              onPressed: () => _removeDriver(
                driver['id'],
                driver['full_name'],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitations() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    if (_pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending invitations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingInvitations.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final driver = _pendingInvitations[index]['driver'];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              driver['full_name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  driver['phone'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Invitation pending',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          'Manage Drivers',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6B5ECD),
          tabs: const [
            Tab(text: 'My Drivers'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriverList(),
          _buildPendingInvitations(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B5ECD),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Invite New Driver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _inviteDriver,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B5ECD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                              'Send Invitation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

```

---

## 5. Driver Feature

### File: `lib/features/driver/presentation/pages/manage_brokers_page.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../core/services/broker_service.dart';
import '../../../../core/services/supabase_service.dart';

class ManageBrokersPage extends StatefulWidget {
  const ManageBrokersPage({super.key});

  @override
  State<ManageBrokersPage> createState() => _ManageBrokersPageState();
}

class _ManageBrokersPageState extends State<ManageBrokersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _brokers = [];
  List<Map<String, dynamic>> _invitations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      final brokers = await BrokerService.getDriverBrokers(userId);
      final invitations = await BrokerService.getDriverInvitations(userId);

      if (mounted) {
        setState(() {
          _brokers = brokers;
          _invitations = invitations;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToInvitation(
    String brokerId,
    String brokerName,
    bool accept,
  ) async {
    setState(() => _isLoading = true);
    try {
      final userId = SupabaseService.client.auth.currentUser!.id;
      await BrokerService.respondToInvitation(
        driverId: userId,
        brokerId: brokerId,
        accept: accept,
      );

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'You are now working with $brokerName'
                  : 'Invitation rejected',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error responding to invitation: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBrokerList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6B5ECD),
        ),
      );
    }

    if (_brokers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No active brokers',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _brokers.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final broker = _brokers[index]['broker'];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              broker['company_name'] ?? broker['full_name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  broker['phone'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitationList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6B5ECD),
        ),
      );
    }

    if (_invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending invitations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _invitations.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final broker = _invitations[index]['broker'];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  broker['company_name'] ?? broker['full_name'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  broker['phone'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _respondToInvitation(
                          broker['id'],
                          broker['company_name'] ?? broker['full_name'],
                          true,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B5ECD),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _respondToInvitation(
                          broker['id'],
                          broker['company_name'] ?? broker['full_name'],
                          false,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
          'My Brokers',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6B5ECD),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBrokerList(),
          _buildInvitationList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

```

---

## 6. Home Feature

### File: `lib/features/home/presentation/pages/home_page.dart`
```dart
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
              MaterialPageRoute(builder: (_) => const ProfilePage()),
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

```

### File: `lib/features/home/presentation/pages/later/marketplace_home_page.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';

class MarketplaceHomePage extends StatelessWidget {
  const MarketplaceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'TruX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome Back!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Driver', // TODO: Get actual user role
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      'Find Jobs',
                      Icons.work,
                      Colors.blue,
                      () {
                        // TODO: Navigate to job search
                      },
                    ),
                    _buildActionCard(
                      context,
                      'My Applications',
                      Icons.description,
                      Colors.green,
                      () {
                        // TODO: Navigate to applications
                      },
                    ),
                    _buildActionCard(
                      context,
                      'Active Deliveries',
                      Icons.local_shipping,
                      Colors.orange,
                      () {
                        // TODO: Navigate to active deliveries
                      },
                    ),
                    _buildActionCard(
                      context,
                      'Earnings',
                      Icons.attach_money,
                      Colors.purple,
                      () {
                        // TODO: Navigate to earnings
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Jobs
                const Text(
                  'Recent Jobs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildJobCard(
                  'Package Delivery',
                  'From: New York\nTo: Boston',
                  '₹150',
                  '2.5 kg',
                ),
                _buildJobCard(
                  'Furniture Moving',
                  'From: Chicago\nTo: Detroit',
                  '₹300',
                  '50 kg',
                ),
                _buildJobCard(
                  'Food Delivery',
                  'From: Restaurant\nTo: Customer',
                  '₹25',
                  '1 kg',
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to post job page
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(
    String title,
    String locations,
    String price,
    String weight,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            locations,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                weight,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

```

---

## 7. Jobs Feature

### File: `lib/features/jobs/domain/models/job.dart`
```dart
import 'package:flutter/foundation.dart';
import '../../../auth/domain/models/user_profile.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String goodsType;
  final double weight;
  final double price;
  final String pickupLocation;
  final String destination;
  final double distance;
  final String jobStatus;
  final DateTime? postedDate;
  final DateTime? assignedDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String warehouseOwnerId;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final UserProfile? warehouseOwner;
  final UserProfile? assignedDriver;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.goodsType,
    required this.weight,
    required this.price,
    required this.pickupLocation,
    required this.destination,
    required this.distance,
    required this.jobStatus,
    this.postedDate,
    this.assignedDate,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.warehouseOwnerId,
    this.assignedDriverId,
    this.assignedDriverName,
    this.warehouseOwner,
    this.assignedDriver,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing Job from JSON: $json');
      
      final id = json['id'] as String?;
      final title = json['title'] as String?;
      final description = json['description'] as String?;
      final goodsType = json['goods_type'] as String?;
      final weight = json['weight'] as num?;
      final price = json['price'] as num?;
      final pickupLocation = json['pickup_location'] as String?;
      final destination = json['destination'] as String?;
      final distance = json['distance'] as num?;
      final jobStatus = json['job_status'] as String?;
      final postedDate = json['posted_date'] as String?;
      final assignedDate = json['assigned_date'] as String?;
      final completionDate = json['completion_date'] as String?;
      final createdAt = json['created_at'] as String?;
      final updatedAt = json['updated_at'] as String?;
      final warehouseOwnerId = json['warehouse_owner_id'] as String?;
      final assignedDriverId = json['assigned_driver_id'] as String?;
      final assignedDriverName = json['assigned_driver_name'] as String?;
      
      debugPrint('Parsed values:');
      debugPrint('id: $id');
      debugPrint('title: $title');
      debugPrint('description: $description');
      debugPrint('goodsType: $goodsType');
      debugPrint('weight: $weight');
      debugPrint('price: $price');
      debugPrint('pickupLocation: $pickupLocation');
      debugPrint('destination: $destination');
      debugPrint('distance: $distance');
      debugPrint('jobStatus: $jobStatus');
      debugPrint('postedDate: $postedDate');
      debugPrint('assignedDate: $assignedDate');
      debugPrint('completionDate: $completionDate');
      debugPrint('createdAt: $createdAt');
      debugPrint('updatedAt: $updatedAt');
      debugPrint('warehouseOwnerId: $warehouseOwnerId');
      debugPrint('assignedDriverId: $assignedDriverId');
      debugPrint('assignedDriverName: $assignedDriverName');

      return Job(
        id: id ?? '',
        title: title ?? '',
        description: description ?? '',
        goodsType: goodsType ?? '',
        weight: weight?.toDouble() ?? 0.0,
        price: price?.toDouble() ?? 0.0,
        pickupLocation: pickupLocation ?? '',
        destination: destination ?? '',
        distance: distance?.toDouble() ?? 0.0,
        jobStatus: jobStatus ?? 'open',
        postedDate: postedDate != null ? DateTime.parse(postedDate) : null,
        assignedDate: assignedDate != null ? DateTime.parse(assignedDate) : null,
        completionDate: completionDate != null ? DateTime.parse(completionDate) : null,
        createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
        updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : DateTime.now(),
        warehouseOwnerId: warehouseOwnerId ?? '',
        assignedDriverId: assignedDriverId,
        assignedDriverName: assignedDriverName,
        warehouseOwner: json['warehouse_owner'] != null 
            ? UserProfile.fromJson(json['warehouse_owner'] as Map<String, dynamic>) 
            : null,
        assignedDriver: json['assigned_driver'] != null 
            ? UserProfile.fromJson(json['assigned_driver'] as Map<String, dynamic>) 
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Job from JSON: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'goods_type': goodsType,
      'weight': weight,
      'price': price,
      'pickup_location': pickupLocation,
      'destination': destination,
      'distance': distance,
      'job_status': jobStatus,
      'posted_date': postedDate?.toIso8601String(),
      'assigned_date': assignedDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'warehouse_owner_id': warehouseOwnerId,
      'assigned_driver_id': assignedDriverId,
      'assigned_driver_name': assignedDriverName,
      'warehouse_owner': warehouseOwner?.toJson(),
      'assigned_driver': assignedDriver?.toJson(),
    };
  }

  // Helper method to create a new job
  static Map<String, dynamic> createJob({
    required String warehouseOwnerId,
    required String title,
    required String description,
    required String goodsType,
    required String pickupLocation,
    required String destination,
    required double weight,
    required double price,
    required double distance,
  }) {
    final now = DateTime.now().toUtc();
    return {
      'warehouse_owner_id': warehouseOwnerId,
      'title': title,
      'description': description,
      'goods_type': goodsType,
      'pickup_location': pickupLocation,
      'destination': destination,
      'weight': weight,
      'price': price,
      'distance': distance,
      'posted_date': now.toIso8601String(),
      'job_status': 'open',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  // Placeholder data
  static List<Job> getPlaceholderJobs() {
    return [
      Job(
        id: '1',
        title: 'Furniture Delivery',
        description: 'Deliver furniture from warehouse to residential address',
        goodsType: 'Furniture',
        weight: 150.0,
        price: 2500.0,
        pickupLocation: 'Warehouse A, Industrial Area',
        destination: '123 Main Street, City Center',
        distance: 8.5,
        jobStatus: 'open',
        postedDate: DateTime.now().subtract(const Duration(hours: 2)),
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        warehouseOwnerId: 'Warehouse A',
        assignedDriverId: null,
        assignedDriverName: null,
        warehouseOwner: null,
        assignedDriver: null,
      ),
      Job(
        id: '2',
        title: 'Electronics Transport',
        description: 'Transport electronic goods to retail store',
        goodsType: 'Electronics',
        weight: 75.0,
        price: 1800.0,
        pickupLocation: 'Electronics Hub, Tech Park',
        destination: '456 Market Street, Shopping District',
        distance: 5.2,
        jobStatus: 'open',
        postedDate: DateTime.now().subtract(const Duration(hours: 4)),
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        warehouseOwnerId: 'Electronics Hub',
        assignedDriverId: null,
        assignedDriverName: null,
        warehouseOwner: null,
        assignedDriver: null,
      ),
      Job(
        id: '3',
        title: 'Food Items Delivery',
        description: 'Deliver food items to restaurant chain',
        goodsType: 'Food Items',
        weight: 200.0,
        price: 3000.0,
        pickupLocation: 'Food Processing Unit, Industrial Zone',
        destination: '789 Restaurant Street, Food Court',
        distance: 12.0,
        jobStatus: 'open',
        postedDate: DateTime.now().subtract(const Duration(hours: 1)),
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        warehouseOwnerId: 'Food Processing Unit',
        assignedDriverId: null,
        assignedDriverName: null,
        warehouseOwner: null,
        assignedDriver: null,
      ),
    ];
  }

  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? goodsType,
    double? weight,
    double? price,
    String? pickupLocation,
    String? destination,
    double? distance,
    String? jobStatus,
    DateTime? postedDate,
    DateTime? assignedDate,
    DateTime? completionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? warehouseOwnerId,
    String? assignedDriverId,
    String? assignedDriverName,
    UserProfile? warehouseOwner,
    UserProfile? assignedDriver,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goodsType: goodsType ?? this.goodsType,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      distance: distance ?? this.distance,
      jobStatus: jobStatus ?? this.jobStatus,
      postedDate: postedDate ?? this.postedDate,
      assignedDate: assignedDate ?? this.assignedDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      warehouseOwnerId: warehouseOwnerId ?? this.warehouseOwnerId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      warehouseOwner: warehouseOwner ?? this.warehouseOwner,
      assignedDriver: assignedDriver ?? this.assignedDriver,
    );
  }
}

```

### File: `lib/features/jobs/domain/models/job_application.dart`
```dart
import 'package:flutter/foundation.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'job.dart';

class JobApplication {
  final String id;
  final String jobId;
  final String driverId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Job? job;
  final UserProfile? driver;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.driverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.job,
    this.driver,
  });

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing JobApplication from JSON: $json');
      
      final id = json['id'] as String?;
      final jobId = json['job_id'] as String?;
      final driverId = json['driver_id'] as String?;
      final status = json['status'] as String?;
      final createdAt = json['created_at'] as String?;
      final updatedAt = json['updated_at'] as String?;
      final driverData = json['driver'] as Map<String, dynamic>?;
      
      debugPrint('Parsed values:');
      debugPrint('id: $id');
      debugPrint('jobId: $jobId');
      debugPrint('driverId: $driverId');
      debugPrint('status: $status');
      debugPrint('createdAt: $createdAt');
      debugPrint('updatedAt: $updatedAt');
      debugPrint('driverData: $driverData');

      if (driverData == null) {
        debugPrint('Warning: Driver data is null');
      } else {
        debugPrint('Driver data fields:');
        debugPrint('  id: ${driverData['id']}');
        debugPrint('  email: ${driverData['email']}');
        debugPrint('  full_name: ${driverData['full_name']}');
        debugPrint('  role: ${driverData['role']}');
        debugPrint('  is_profile_complete: ${driverData['is_profile_complete']}');
      }

      return JobApplication(
        id: id ?? '',
        jobId: jobId ?? '',
        driverId: driverId ?? '',
        status: status ?? 'pending',
        createdAt: createdAt != null 
            ? DateTime.parse(createdAt)
            : DateTime.now(),
        updatedAt: updatedAt != null 
            ? DateTime.parse(updatedAt)
            : DateTime.now(),
        job: json['job'] != null ? Job.fromJson(json['job'] as Map<String, dynamic>) : null,
        driver: driverData != null ? UserProfile.fromJson(driverData) : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing JobApplication from JSON: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'job_id': jobId,
      'driver_id': driverId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'job': job?.toJson(),
      'driver': driver?.toJson(),
    };
  }

  JobApplication copyWith({
    String? id,
    String? jobId,
    String? driverId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Job? job,
    UserProfile? driver,
  }) {
    return JobApplication(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      job: job ?? this.job,
      driver: driver ?? this.driver,
    );
  }
} 
```

### File: `lib/features/jobs/presentation/pages/job_details_page.dart`
```dart
import 'package:flutter/material.dart';
import '../../domain/models/job.dart';
import '../../../../core/services/supabase_service.dart';

class JobDetailsPage extends StatefulWidget {
  final Job job;

  const JobDetailsPage({super.key, required this.job});

  @override
  _JobDetailsPageState createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  late Job job;
  bool _hasActiveJob = false;

  @override
  void initState() {
    super.initState();
    job = widget.job;
    _checkActiveJob();
  }

  Future<void> _checkActiveJob() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final hasActive = await SupabaseService.hasActiveJob(userId);
      if (mounted) {
        setState(() {
          _hasActiveJob = hasActive;
        });
      }
    } catch (e) {
      print('Error checking active job status: $e');
    }
  }

  Future<void> _applyForJob() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to apply for jobs'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
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
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      final loadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
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
          duration:
              Duration(seconds: 30), // Long duration as we'll close it manually
          behavior: SnackBarBehavior.floating,
        ),
      );

      await SupabaseService.applyForJob(widget.job.id, userId);

      // Hide loading indicator
      loadingSnackBar.close();

      // Show success message after a short delay
      await Future.delayed(Duration(milliseconds: 100));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Color(0xFF6B5ECD),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Close the details page after a short delay
      await Future.delayed(Duration(milliseconds: 1500));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      print('Error applying for job: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying for job: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.05),
        title: Text(
          job.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              'Goods Information',
              [
                _buildDetailRow('Type', job.goodsType),
                _buildDetailRow('Weight', '${job.weight} kg'),
                _buildDetailRow('Price', '₹${job.price.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _buildDetailSection(
              'Additional Information',
              [
                _buildDetailRow('Posted', _formatDate(job.postedDate ?? DateTime.now())),
                _buildDetailRow('Status', job.jobStatus.toUpperCase()),
              ],
            ),
            const SizedBox(height: 32),
            if (_hasActiveJob)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have an active job',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please complete your current job before applying for new ones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else if (job.jobStatus == 'open')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyForJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply for Job',
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
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
          const SizedBox(height: 12),
          ...children,
        ],
      ),
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
                const SizedBox(width: 4),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

```

---

## 8. Profile Feature

### File: `lib/features/profile/presentation/pages/profile_page.dart`
```dart
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
                          MaterialPageRoute(builder: (_) => const LoginPage()),
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

```

### File: `lib/features/profile/presentation/pages/profile_completion_page.dart`
```dart
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

```

---

## 9. Warehouse Feature

### File: `lib/features/warehouse/presentation/pages/warehouse_home_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../jobs/domain/models/job.dart';
import '../../../jobs/domain/models/job_application.dart';
import '../../../jobs/presentation/pages/job_details_page.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/models/user_profile.dart';
import 'post_job_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class WarehouseHomePage extends StatefulWidget {
  const WarehouseHomePage({super.key});

  @override
  State<WarehouseHomePage> createState() => _WarehouseHomePageState();
}

class _WarehouseHomePageState extends State<WarehouseHomePage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  UserProfile? _profile;
  List<Job> _postedJobs = [];
  List<Job> _activeJobs = [];
  Map<String, List<JobApplication>> _jobApplications = {};
  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _applicationsChannel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final profile = await SupabaseService.getUserProfile();
      if (profile != null) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
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
                job.jobStatus == 'assigned' ||
                job.jobStatus == 'awaitingPickupVerification' ||
                job.jobStatus == 'inTransit' ||
                job.jobStatus == 'awaitingDeliveryVerification')
            .toList();
      });
    } catch (e) {
      print('Error loading active jobs: $e');
    }
  }

  Future<void> _loadJobApplications(String jobId) async {
    try {
      final applications = await SupabaseService.getJobApplications(jobId);
      if (mounted) {
        setState(() {
          _jobApplications[jobId] = applications.map((app) => JobApplication.fromJson(app)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading applications: $e');
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
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'warehouse_owner_id',
            value: userId,
          ),
          callback: (payload) async {
            debugPrint('Job change detected: ${payload.eventType}');
            await _loadPostedJobs();
            await _loadActiveJobs();
          },
        )
        .subscribe();
  }

  void _setupApplicationsSubscription() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    _applicationsChannel = SupabaseService.client.channel('public:job_applications');
    _applicationsChannel!
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
            debugPrint('Application change detected: ${payload.eventType}');

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
                    final jobIndex = _postedJobs.indexWhere((job) => job.id == jobId);
                    if (jobIndex != -1) {
                      _postedJobs[jobIndex] = _postedJobs[jobIndex].copyWith(
                        jobStatus: 'assigned',
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
  ) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Updating status...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update application status
      await SupabaseService.updateApplicationStatus(
        applicationId,
        status,
        jobId,
        driverId: driverId,
      );

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted' 
                ? 'Application accepted successfully'
                : 'Application rejected successfully',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Update local state
      setState(() {
        final applications = _jobApplications[jobId];
        if (applications != null) {
          final index = applications.indexWhere((app) => app.id == applicationId);
          if (index != -1) {
            applications[index] = applications[index].copyWith(status: status);
          }
        }
      });

      // If accepting, update the job status
      if (status == 'accepted') {
        setState(() {
          final jobIndex = _postedJobs.indexWhere((job) => job.id == jobId);
          if (jobIndex != -1) {
            _postedJobs[jobIndex] = _postedJobs[jobIndex].copyWith(
              jobStatus: 'assigned',
              assignedDriverId: driverId,
              assignedDate: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating application status: $e');
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status: ${e.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Revert local state changes
      setState(() {
        final applications = _jobApplications[jobId];
        if (applications != null) {
          final index = applications.indexWhere((app) => app.id == applicationId);
          if (index != -1) {
            applications[index] = applications[index].copyWith(status: 'pending');
          }
        }
      });
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Recently';
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
                          color: _getJobStatusColor(job.jobStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getJobStatusText(job.jobStatus),
                          style: TextStyle(
                            color: _getJobStatusColor(job.jobStatus),
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
    final isActive = _isJobActive(job.jobStatus);
    final statusColor = _getJobStatusColor(job.jobStatus);
    final statusText = _getJobStatusText(job.jobStatus);

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
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
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
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${job.pickupLocation} → ${job.destination}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '₹${job.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (job.assignedDriverId != null)
                Text(
                  'Assigned to: ${job.assignedDriver?.fullName ?? "Unknown Driver"}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPickup(String jobId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Verifying pickup...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update job status to 'inTransit' through SupabaseService
      await SupabaseService.updateJobStatus(jobId, 'inTransit');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pickup verified successfully',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        final jobIndex = _activeJobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          _activeJobs[jobIndex] = _activeJobs[jobIndex].copyWith(
            jobStatus: 'inTransit',
          );
        }
      });
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to verify pickup: ${e.toString()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                              AlwaysStoppedAnimation<Color>(Colors.red),
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

  Widget _buildApplicationCard(JobApplication application, Job job) {
    final driver = application.driver;
    final status = application.status;
    final createdAt = application.createdAt;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? statusMessage;

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Accepted';
        statusMessage = 'Application has been accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        statusMessage = 'Application has been rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending';
        statusMessage = 'Application is pending review';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver?.fullName ?? 'Unknown Driver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver?.email ?? 'Email not provided',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Applied ${_formatTimeAgo(createdAt)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              statusMessage,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
              ),
            ),
          ],
          if (status == 'pending' && driver != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateApplicationStatus(
                        application.id,
                        'accepted',
                        job.id,
                        driver.id,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateApplicationStatus(
                        application.id,
                        'rejected',
                        job.id,
                        null,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
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
                  color: _getJobStatusColor(job.jobStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getJobStatusText(job.jobStatus),
                  style: TextStyle(
                    color: _getJobStatusColor(job.jobStatus),
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
          // Show 'Verify Pickup' button for warehouse owner if job is awaiting pickup verification
          if (job.jobStatus == 'awaitingPickupVerification')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _verifyPickup(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Verify Pickup',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Existing delivery verification button
          if (job.jobStatus == 'awaitingDeliveryVerification')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _verifyDelivery(job.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Verify Delivery',
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
    );
  }

  Future<void> _verifyDelivery(String jobId) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Verifying delivery...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Verify delivery
      await SupabaseService.verifyDelivery(jobId);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery verified successfully',
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
            borderRadius: BorderRadius.circular(8),
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Update local state
      setState(() {
        final jobIndex = _activeJobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          _activeJobs[jobIndex] = _activeJobs[jobIndex].copyWith(
            jobStatus: 'completed',
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error verifying delivery: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
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
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
        ),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Posted Jobs'),
            Tab(icon: Icon(Icons.local_shipping), text: 'Active Jobs'),
            Tab(icon: Icon(Icons.people), text: 'Applications'),
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
      color: Colors.red,
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
                        'Welcome back, ${_profile!.fullName}',
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
      color: Colors.red,
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
                        'Welcome back, ${_profile!.fullName}',
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
      color: Colors.red,
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

  Color _getJobStatusColor(String jobStatus) {
    switch (jobStatus.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'awaitingpickupverification':
        return Colors.purple;
      case 'intransit':
        return Colors.green;
      case 'awaitingdeliveryverification':
        return Colors.amber;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getJobStatusText(String jobStatus) {
    switch (jobStatus.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'assigned':
        return 'Assigned';
      case 'awaitingpickupverification':
        return 'Awaiting Pickup';
      case 'intransit':
        return 'In Transit';
      case 'awaitingdeliveryverification':
        return 'Awaiting Delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool _isJobActive(String jobStatus) {
    return jobStatus.toLowerCase() == 'assigned' ||
           jobStatus.toLowerCase() == 'awaitingpickupverification' ||
           jobStatus.toLowerCase() == 'intransit' ||
           jobStatus.toLowerCase() == 'awaitingdeliveryverification';
  }
}

```

### File: `lib/features/warehouse/presentation/pages/post_job_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../jobs/domain/models/job.dart';

class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  State<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Autofill warehouse location from user profile
    _loadWarehouseLocation();
  }

  Future<void> _loadWarehouseLocation() async {
    try {
      final profile = await SupabaseService.getUserProfile();
      if (profile != null && profile.warehouseDetails != null) {
        setState(() {
          _pickupLocationController.text =
              profile.warehouseDetails!['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading warehouse location: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _pickupLocationController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No user ID found');
      }

      final jobData = Job.createJob(
        warehouseOwnerId: userId,
        title: _titleController.text,
        description: _descriptionController.text,
        goodsType: _typeController.text,
        pickupLocation: _pickupLocationController.text,
        destination: _destinationController.text,
        weight: double.parse(_weightController.text),
        price: double.parse(_priceController.text),
        distance: double.parse(_distanceController.text),
      );

      await SupabaseService.postJob(jobData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Job posted successfully',
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

      Navigator.pop(context);
    } catch (e) {
      print('Error posting job: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to post job',
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red,
              ),
            ),
          ),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
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
        backgroundColor: Colors.white.withOpacity(0.05),
        title: Text(
          'Post New Job',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Job Title',
                hint: 'Enter job title',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter job description',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Goods Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _typeController,
                label: 'Type of Goods',
                hint: 'Enter type of goods',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                hint: 'Enter weight in kg',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Price (₹)',
                hint: 'Enter price',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Location Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pickupLocationController,
                label: 'Pickup Location',
                hint: 'Enter pickup location',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _destinationController,
                label: 'Destination',
                hint: 'Enter destination',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _distanceController,
                label: 'Distance (km)',
                hint: 'Enter distance in km',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter distance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Post Job',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

```

---

## 10. Verification Feature

### File: `lib/features/verification/presentation/pages/`
```dart
// Paste full content here (add individual files if present)
```

---

## 11. Configuration and Database

### File: `pubspec.yaml`
```yaml
name: truxlo
description: "A new Flutter project."
# The following line prevents the package from being accidentally published to
# pub.dev using `flutter pub publish`. This is preferred for private packages.
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

# The following defines the version and build number for your application.
# A version number is three numbers separated by dots, like 1.2.43
# followed by an optional build number separated by a +.
# Both the version and the builder number may be overridden in flutter
# build by specifying --build-name and --build-number, respectively.
# In Android, build-name is used as versionName while build-number used as versionCode.
# Read more about Android versioning at https://developer.android.com/studio/publish/versioning
# In iOS, build-name is used as CFBundleShortVersionString while build-number is used as CFBundleVersion.
# Read more about iOS versioning at
# https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html
# In Windows, build-name is used as the major, minor, and patch parts
# of the product and file versions while build-number is used as the build suffix.
version: 1.0.0+1

environment:
  sdk: '>=3.2.3 <4.0.0'

# Dependencies specify other packages that your package needs in order to work.
# To automatically upgrade your package dependencies to the latest versions
# consider running `flutter pub upgrade --major-versions`. Alternatively,
# dependencies can be manually updated by changing the version numbers below to
# the latest version available on pub.dev. To see which dependencies have newer
# versions available, run `flutter pub outdated`.
dependencies:
  flutter:
    sdk: flutter

  # The following adds the Cupertino Icons font to your application.
  # Use with the CupertinoIcons class for iOS style icons.
  cupertino_icons: ^1.0.2
  supabase_flutter: ^2.3.3
  flutter_dotenv: ^5.1.0
  flutter_secure_storage: ^9.0.0
  flutter_launcher_icons: ^0.14.3
  timeago: ^3.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # The "flutter_lints" package below contains a set of recommended lints to
  # encourage good coding practices. The lint set provided by the package is
  # activated in the `analysis_options.yaml` file located at the root of your
  # package. See that file for information about deactivating specific lint
  # rules and activating additional ones.
  flutter_lints: ^2.0.0
  flutter_launcher_icons: ^0.14.3

# For information on the generic Dart part of this file, see the
# following page: https://dart.dev/tools/pub/pubspec

# The following section is specific to Flutter packages.
flutter:

  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  assets:
    - .env
    - assets/images/

  # An image asset can refer to one or more resolution-specific "variants", see
  # https://flutter.dev/to/resolution-aware-images

  # For details regarding adding assets from package dependencies, see
  # https://flutter.dev/to/asset-from-package

  # To add custom fonts to your application, add a fonts section here,
  # in this "flutter" section. Each entry in this list should have a
  # "family" key with the font family name, and a "fonts" key with a
  # list giving the asset and other descriptors for the font. For
  # example:
  # fonts:
  #   - family: Trajan Pro
  #     fonts:
  #       - asset: fonts/TrajanPro.ttf
  #       - asset: fonts/TrajanPro_Bold.ttf
  #         weight: 700
  #
  # For details regarding fonts from package dependencies,
  # see https://flutter.dev/to/font-from-package

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/Truxlo.png"
  adaptive_icon_background: "#6B5ECD"
  adaptive_icon_foreground: "assets/images/Truxlo.png"
  min_sdk_android: 21

```

### File: `pubspec.lock`
```yaml
# Generated by pub
# See https://dart.dev/tools/pub/glossary#lockfile
packages:
  app_links:
    dependency: transitive
    description:
      name: app_links
      sha256: "85ed8fc1d25a76475914fff28cc994653bd900bc2c26e4b57a49e097febb54ba"
      url: "https://pub.dev"
    source: hosted
    version: "6.4.0"
  app_links_linux:
    dependency: transitive
    description:
      name: app_links_linux
      sha256: f5f7173a78609f3dfd4c2ff2c95bd559ab43c80a87dc6a095921d96c05688c81
      url: "https://pub.dev"
    source: hosted
    version: "1.0.3"
  app_links_platform_interface:
    dependency: transitive
    description:
      name: app_links_platform_interface
      sha256: "05f5379577c513b534a29ddea68176a4d4802c46180ee8e2e966257158772a3f"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.2"
  app_links_web:
    dependency: transitive
    description:
      name: app_links_web
      sha256: af060ed76183f9e2b87510a9480e56a5352b6c249778d07bd2c95fc35632a555
      url: "https://pub.dev"
    source: hosted
    version: "1.0.4"
  archive:
    dependency: transitive
    description:
      name: archive
      sha256: "0c64e928dcbefddecd234205422bcfc2b5e6d31be0b86fef0d0dd48d7b4c9742"
      url: "https://pub.dev"
    source: hosted
    version: "4.0.4"
  args:
    dependency: transitive
    description:
      name: args
      sha256: d0481093c50b1da8910eb0bb301626d4d8eb7284aa739614d2b394ee09e3ea04
      url: "https://pub.dev"
    source: hosted
    version: "2.7.0"
  async:
    dependency: transitive
    description:
      name: async
      sha256: d2872f9c19731c2e5f10444b14686eb7cc85c76274bd6c16e1816bff9a3bab63
      url: "https://pub.dev"
    source: hosted
    version: "2.12.0"
  boolean_selector:
    dependency: transitive
    description:
      name: boolean_selector
      sha256: "8aab1771e1243a5063b8b0ff68042d67334e3feab9e95b9490f9a6ebf73b42ea"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  characters:
    dependency: transitive
    description:
      name: characters
      sha256: f71061c654a3380576a52b451dd5532377954cf9dbd272a78fc8479606670803
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  checked_yaml:
    dependency: transitive
    description:
      name: checked_yaml
      sha256: feb6bed21949061731a7a75fc5d2aa727cf160b91af9a3e464c5e3a32e28b5ff
      url: "https://pub.dev"
    source: hosted
    version: "2.0.3"
  cli_util:
    dependency: transitive
    description:
      name: cli_util
      sha256: ff6785f7e9e3c38ac98b2fb035701789de90154024a75b6cb926445e83197d1c
      url: "https://pub.dev"
    source: hosted
    version: "0.4.2"
  clock:
    dependency: transitive
    description:
      name: clock
      sha256: fddb70d9b5277016c77a80201021d40a2247104d9f4aa7bab7157b7e3f05b84b
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  collection:
    dependency: transitive
    description:
      name: collection
      sha256: "2f5709ae4d3d59dd8f7cd309b4e023046b57d8a6c82130785d2b0e5868084e76"
      url: "https://pub.dev"
    source: hosted
    version: "1.19.1"
  crypto:
    dependency: transitive
    description:
      name: crypto
      sha256: "1e445881f28f22d6140f181e07737b22f1e099a5e1ff94b0af2f9e4a463f4855"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.6"
  cupertino_icons:
    dependency: "direct main"
    description:
      name: cupertino_icons
      sha256: ba631d1c7f7bef6b729a622b7b752645a2d076dba9976925b8f25725a30e1ee6
      url: "https://pub.dev"
    source: hosted
    version: "1.0.8"
  fake_async:
    dependency: transitive
    description:
      name: fake_async
      sha256: "6a95e56b2449df2273fd8c45a662d6947ce1ebb7aafe80e550a3f68297f3cacc"
      url: "https://pub.dev"
    source: hosted
    version: "1.3.2"
  ffi:
    dependency: transitive
    description:
      name: ffi
      sha256: "289279317b4b16eb2bb7e271abccd4bf84ec9bdcbe999e278a94b804f5630418"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  file:
    dependency: transitive
    description:
      name: file
      sha256: a3b4f84adafef897088c160faf7dfffb7696046cb13ae90b508c2cbc95d3b8d4
      url: "https://pub.dev"
    source: hosted
    version: "7.0.1"
  flutter:
    dependency: "direct main"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_dotenv:
    dependency: "direct main"
    description:
      name: flutter_dotenv
      sha256: b7c7be5cd9f6ef7a78429cabd2774d3c4af50e79cb2b7593e3d5d763ef95c61b
      url: "https://pub.dev"
    source: hosted
    version: "5.2.1"
  flutter_launcher_icons:
    dependency: "direct main"
    description:
      name: flutter_launcher_icons
      sha256: bfa04787c85d80ecb3f8777bde5fc10c3de809240c48fa061a2c2bf15ea5211c
      url: "https://pub.dev"
    source: hosted
    version: "0.14.3"
  flutter_lints:
    dependency: "direct dev"
    description:
      name: flutter_lints
      sha256: a25a15ebbdfc33ab1cd26c63a6ee519df92338a9c10f122adda92938253bef04
      url: "https://pub.dev"
    source: hosted
    version: "2.0.3"
  flutter_secure_storage:
    dependency: "direct main"
    description:
      name: flutter_secure_storage
      sha256: "9cad52d75ebc511adfae3d447d5d13da15a55a92c9410e50f67335b6d21d16ea"
      url: "https://pub.dev"
    source: hosted
    version: "9.2.4"
  flutter_secure_storage_linux:
    dependency: transitive
    description:
      name: flutter_secure_storage_linux
      sha256: bf7404619d7ab5c0a1151d7c4e802edad8f33535abfbeff2f9e1fe1274e2d705
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  flutter_secure_storage_macos:
    dependency: transitive
    description:
      name: flutter_secure_storage_macos
      sha256: "6c0a2795a2d1de26ae202a0d78527d163f4acbb11cde4c75c670f3a0fc064247"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
  flutter_secure_storage_platform_interface:
    dependency: transitive
    description:
      name: flutter_secure_storage_platform_interface
      sha256: cf91ad32ce5adef6fba4d736a542baca9daf3beac4db2d04be350b87f69ac4a8
      url: "https://pub.dev"
    source: hosted
    version: "1.1.2"
  flutter_secure_storage_web:
    dependency: transitive
    description:
      name: flutter_secure_storage_web
      sha256: f4ebff989b4f07b2656fb16b47852c0aab9fed9b4ec1c70103368337bc1886a9
      url: "https://pub.dev"
    source: hosted
    version: "1.2.1"
  flutter_secure_storage_windows:
    dependency: transitive
    description:
      name: flutter_secure_storage_windows
      sha256: b20b07cb5ed4ed74fc567b78a72936203f587eba460af1df11281c9326cd3709
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  flutter_test:
    dependency: "direct dev"
    description: flutter
    source: sdk
    version: "0.0.0"
  flutter_web_plugins:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  functions_client:
    dependency: transitive
    description:
      name: functions_client
      sha256: a49876ebae32a50eb62483c5c5ac80ed0d8da34f98ccc23986b03a8d28cee07c
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  gotrue:
    dependency: transitive
    description:
      name: gotrue
      sha256: d6362dff9a54f8c1c372bb137c858b4024c16407324d34e6473e59623c9b9f50
      url: "https://pub.dev"
    source: hosted
    version: "2.11.1"
  gtk:
    dependency: transitive
    description:
      name: gtk
      sha256: e8ce9ca4b1df106e4d72dad201d345ea1a036cc12c360f1a7d5a758f78ffa42c
      url: "https://pub.dev"
    source: hosted
    version: "2.1.0"
  http:
    dependency: transitive
    description:
      name: http
      sha256: fe7ab022b76f3034adc518fb6ea04a82387620e19977665ea18d30a1cf43442f
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  http_parser:
    dependency: transitive
    description:
      name: http_parser
      sha256: "178d74305e7866013777bab2c3d8726205dc5a4dd935297175b19a23a2e66571"
      url: "https://pub.dev"
    source: hosted
    version: "4.1.2"
  image:
    dependency: transitive
    description:
      name: image
      sha256: "13d3349ace88f12f4a0d175eb5c12dcdd39d35c4c109a8a13dfeb6d0bd9e31c3"
      url: "https://pub.dev"
    source: hosted
    version: "4.5.3"
  intl:
    dependency: transitive
    description:
      name: intl
      sha256: d6f56758b7d3014a48af9701c085700aac781a92a87a62b1333b46d8879661cf
      url: "https://pub.dev"
    source: hosted
    version: "0.19.0"
  js:
    dependency: transitive
    description:
      name: js
      sha256: f2c445dce49627136094980615a031419f7f3eb393237e4ecd97ac15dea343f3
      url: "https://pub.dev"
    source: hosted
    version: "0.6.7"
  json_annotation:
    dependency: transitive
    description:
      name: json_annotation
      sha256: "1ce844379ca14835a50d2f019a3099f419082cfdd231cd86a142af94dd5c6bb1"
      url: "https://pub.dev"
    source: hosted
    version: "4.9.0"
  jwt_decode:
    dependency: transitive
    description:
      name: jwt_decode
      sha256: d2e9f68c052b2225130977429d30f187aa1981d789c76ad104a32243cfdebfbb
      url: "https://pub.dev"
    source: hosted
    version: "0.3.1"
  leak_tracker:
    dependency: transitive
    description:
      name: leak_tracker
      sha256: c35baad643ba394b40aac41080300150a4f08fd0fd6a10378f8f7c6bc161acec
      url: "https://pub.dev"
    source: hosted
    version: "10.0.8"
  leak_tracker_flutter_testing:
    dependency: transitive
    description:
      name: leak_tracker_flutter_testing
      sha256: f8b613e7e6a13ec79cfdc0e97638fddb3ab848452eff057653abd3edba760573
      url: "https://pub.dev"
    source: hosted
    version: "3.0.9"
  leak_tracker_testing:
    dependency: transitive
    description:
      name: leak_tracker_testing
      sha256: "6ba465d5d76e67ddf503e1161d1f4a6bc42306f9d66ca1e8f079a47290fb06d3"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.1"
  lints:
    dependency: transitive
    description:
      name: lints
      sha256: "0a217c6c989d21039f1498c3ed9f3ed71b354e69873f13a8dfc3c9fe76f1b452"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.1"
  logging:
    dependency: transitive
    description:
      name: logging
      sha256: c8245ada5f1717ed44271ed1c26b8ce85ca3228fd2ffdb75468ab01979309d61
      url: "https://pub.dev"
    source: hosted
    version: "1.3.0"
  matcher:
    dependency: transitive
    description:
      name: matcher
      sha256: dc58c723c3c24bf8d3e2d3ad3f2f9d7bd9cf43ec6feaa64181775e60190153f2
      url: "https://pub.dev"
    source: hosted
    version: "0.12.17"
  material_color_utilities:
    dependency: transitive
    description:
      name: material_color_utilities
      sha256: f7142bb1154231d7ea5f96bc7bde4bda2a0945d2806bb11670e30b850d56bdec
      url: "https://pub.dev"
    source: hosted
    version: "0.11.1"
  meta:
    dependency: transitive
    description:
      name: meta
      sha256: e3641ec5d63ebf0d9b41bd43201a66e3fc79a65db5f61fc181f04cd27aab950c
      url: "https://pub.dev"
    source: hosted
    version: "1.16.0"
  mime:
    dependency: transitive
    description:
      name: mime
      sha256: "41a20518f0cb1256669420fdba0cd90d21561e560ac240f26ef8322e45bb7ed6"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.0"
  path:
    dependency: transitive
    description:
      name: path
      sha256: "75cca69d1490965be98c73ceaea117e8a04dd21217b37b292c9ddbec0d955bc5"
      url: "https://pub.dev"
    source: hosted
    version: "1.9.1"
  path_provider:
    dependency: transitive
    description:
      name: path_provider
      sha256: "50c5dd5b6e1aaf6fb3a78b33f6aa3afca52bf903a8a5298f53101fdaee55bbcd"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.5"
  path_provider_android:
    dependency: transitive
    description:
      name: path_provider_android
      sha256: "0ca7359dad67fd7063cb2892ab0c0737b2daafd807cf1acecd62374c8fae6c12"
      url: "https://pub.dev"
    source: hosted
    version: "2.2.16"
  path_provider_foundation:
    dependency: transitive
    description:
      name: path_provider_foundation
      sha256: "4843174df4d288f5e29185bd6e72a6fbdf5a4a4602717eed565497429f179942"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  path_provider_linux:
    dependency: transitive
    description:
      name: path_provider_linux
      sha256: f7a1fe3a634fe7734c8d3f2766ad746ae2a2884abe22e241a8b301bf5cac3279
      url: "https://pub.dev"
    source: hosted
    version: "2.2.1"
  path_provider_platform_interface:
    dependency: transitive
    description:
      name: path_provider_platform_interface
      sha256: "88f5779f72ba699763fa3a3b06aa4bf6de76c8e5de842cf6f29e2e06476c2334"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.2"
  path_provider_windows:
    dependency: transitive
    description:
      name: path_provider_windows
      sha256: bd6f00dbd873bfb70d0761682da2b3a2c2fccc2b9e84c495821639601d81afe7
      url: "https://pub.dev"
    source: hosted
    version: "2.3.0"
  petitparser:
    dependency: transitive
    description:
      name: petitparser
      sha256: "07c8f0b1913bcde1ff0d26e57ace2f3012ccbf2b204e070290dad3bb22797646"
      url: "https://pub.dev"
    source: hosted
    version: "6.1.0"
  platform:
    dependency: transitive
    description:
      name: platform
      sha256: "5d6b1b0036a5f331ebc77c850ebc8506cbc1e9416c27e59b439f917a902a4984"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.6"
  plugin_platform_interface:
    dependency: transitive
    description:
      name: plugin_platform_interface
      sha256: "4820fbfdb9478b1ebae27888254d445073732dae3d6ea81f0b7e06d5dedc3f02"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.8"
  posix:
    dependency: transitive
    description:
      name: posix
      sha256: a0117dc2167805aa9125b82eee515cc891819bac2f538c83646d355b16f58b9a
      url: "https://pub.dev"
    source: hosted
    version: "6.0.1"
  postgrest:
    dependency: transitive
    description:
      name: postgrest
      sha256: b74dc0f57b5dca5ce9f57a54b08110bf41d6fc8a0483c0fec10c79e9aa0fb2bb
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  realtime_client:
    dependency: transitive
    description:
      name: realtime_client
      sha256: e3089dac2121917cc0c72d42ab056fea0abbaf3c2229048fc50e64bafc731adf
      url: "https://pub.dev"
    source: hosted
    version: "2.4.2"
  retry:
    dependency: transitive
    description:
      name: retry
      sha256: "822e118d5b3aafed083109c72d5f484c6dc66707885e07c0fbcb8b986bba7efc"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.2"
  rxdart:
    dependency: transitive
    description:
      name: rxdart
      sha256: "5c3004a4a8dbb94bd4bf5412a4def4acdaa12e12f269737a5751369e12d1a962"
      url: "https://pub.dev"
    source: hosted
    version: "0.28.0"
  shared_preferences:
    dependency: transitive
    description:
      name: shared_preferences
      sha256: "846849e3e9b68f3ef4b60c60cf4b3e02e9321bc7f4d8c4692cf87ffa82fc8a3a"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.2"
  shared_preferences_android:
    dependency: transitive
    description:
      name: shared_preferences_android
      sha256: "3ec7210872c4ba945e3244982918e502fa2bfb5230dff6832459ca0e1879b7ad"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.8"
  shared_preferences_foundation:
    dependency: transitive
    description:
      name: shared_preferences_foundation
      sha256: "6a52cfcdaeac77cad8c97b539ff688ccfc458c007b4db12be584fbe5c0e49e03"
      url: "https://pub.dev"
    source: hosted
    version: "2.5.4"
  shared_preferences_linux:
    dependency: transitive
    description:
      name: shared_preferences_linux
      sha256: "580abfd40f415611503cae30adf626e6656dfb2f0cee8f465ece7b6defb40f2f"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  shared_preferences_platform_interface:
    dependency: transitive
    description:
      name: shared_preferences_platform_interface
      sha256: "57cbf196c486bc2cf1f02b85784932c6094376284b3ad5779d1b1c6c6a816b80"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  shared_preferences_web:
    dependency: transitive
    description:
      name: shared_preferences_web
      sha256: c49bd060261c9a3f0ff445892695d6212ff603ef3115edbb448509d407600019
      url: "https://pub.dev"
    source: hosted
    version: "2.4.3"
  shared_preferences_windows:
    dependency: transitive
    description:
      name: shared_preferences_windows
      sha256: "94ef0f72b2d71bc3e700e025db3710911bd51a71cefb65cc609dd0d9a982e3c1"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.1"
  sky_engine:
    dependency: transitive
    description: flutter
    source: sdk
    version: "0.0.0"
  source_span:
    dependency: transitive
    description:
      name: source_span
      sha256: "254ee5351d6cb365c859e20ee823c3bb479bf4a293c22d17a9f1bf144ce86f7c"
      url: "https://pub.dev"
    source: hosted
    version: "1.10.1"
  stack_trace:
    dependency: transitive
    description:
      name: stack_trace
      sha256: "8b27215b45d22309b5cddda1aa2b19bdfec9df0e765f2de506401c071d38d1b1"
      url: "https://pub.dev"
    source: hosted
    version: "1.12.1"
  storage_client:
    dependency: transitive
    description:
      name: storage_client
      sha256: "9f9ed283943313b23a1b27139bb18986e9b152a6d34530232c702c468d98e91a"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.1"
  stream_channel:
    dependency: transitive
    description:
      name: stream_channel
      sha256: "969e04c80b8bcdf826f8f16579c7b14d780458bd97f56d107d3950fdbeef059d"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  string_scanner:
    dependency: transitive
    description:
      name: string_scanner
      sha256: "921cd31725b72fe181906c6a94d987c78e3b98c2e205b397ea399d4054872b43"
      url: "https://pub.dev"
    source: hosted
    version: "1.4.1"
  supabase:
    dependency: transitive
    description:
      name: supabase
      sha256: c3ebddba69ddcf16d8b78e8c44c4538b0193d1cf944fde3b72eb5b279892a370
      url: "https://pub.dev"
    source: hosted
    version: "2.6.3"
  supabase_flutter:
    dependency: "direct main"
    description:
      name: supabase_flutter
      sha256: "3b5b5b492e342f63f301605d0c66f6528add285b5744f53c9fd9abd5ffdbce5b"
      url: "https://pub.dev"
    source: hosted
    version: "2.8.4"
  term_glyph:
    dependency: transitive
    description:
      name: term_glyph
      sha256: "7f554798625ea768a7518313e58f83891c7f5024f88e46e7182a4558850a4b8e"
      url: "https://pub.dev"
    source: hosted
    version: "1.2.2"
  test_api:
    dependency: transitive
    description:
      name: test_api
      sha256: fb31f383e2ee25fbbfe06b40fe21e1e458d14080e3c67e7ba0acfde4df4e0bbd
      url: "https://pub.dev"
    source: hosted
    version: "0.7.4"
  timeago:
    dependency: "direct main"
    description:
      name: timeago
      sha256: "054cedf68706bb142839ba0ae6b135f6b68039f0b8301cbe8784ae653d5ff8de"
      url: "https://pub.dev"
    source: hosted
    version: "3.7.0"
  typed_data:
    dependency: transitive
    description:
      name: typed_data
      sha256: f9049c039ebfeb4cf7a7104a675823cd72dba8297f264b6637062516699fa006
      url: "https://pub.dev"
    source: hosted
    version: "1.4.0"
  url_launcher:
    dependency: transitive
    description:
      name: url_launcher
      sha256: "9d06212b1362abc2f0f0d78e6f09f726608c74e3b9462e8368bb03314aa8d603"
      url: "https://pub.dev"
    source: hosted
    version: "6.3.1"
  url_launcher_android:
    dependency: transitive
    description:
      name: url_launcher_android
      sha256: "1d0eae19bd7606ef60fe69ef3b312a437a16549476c42321d5dc1506c9ca3bf4"
      url: "https://pub.dev"
    source: hosted
    version: "6.3.15"
  url_launcher_ios:
    dependency: transitive
    description:
      name: url_launcher_ios
      sha256: "16a513b6c12bb419304e72ea0ae2ab4fed569920d1c7cb850263fe3acc824626"
      url: "https://pub.dev"
    source: hosted
    version: "6.3.2"
  url_launcher_linux:
    dependency: transitive
    description:
      name: url_launcher_linux
      sha256: "4e9ba368772369e3e08f231d2301b4ef72b9ff87c31192ef471b380ef29a4935"
      url: "https://pub.dev"
    source: hosted
    version: "3.2.1"
  url_launcher_macos:
    dependency: transitive
    description:
      name: url_launcher_macos
      sha256: "17ba2000b847f334f16626a574c702b196723af2a289e7a93ffcb79acff855c2"
      url: "https://pub.dev"
    source: hosted
    version: "3.2.2"
  url_launcher_platform_interface:
    dependency: transitive
    description:
      name: url_launcher_platform_interface
      sha256: "552f8a1e663569be95a8190206a38187b531910283c3e982193e4f2733f01029"
      url: "https://pub.dev"
    source: hosted
    version: "2.3.2"
  url_launcher_web:
    dependency: transitive
    description:
      name: url_launcher_web
      sha256: "3ba963161bd0fe395917ba881d320b9c4f6dd3c4a233da62ab18a5025c85f1e9"
      url: "https://pub.dev"
    source: hosted
    version: "2.4.0"
  url_launcher_windows:
    dependency: transitive
    description:
      name: url_launcher_windows
      sha256: "3284b6d2ac454cf34f114e1d3319866fdd1e19cdc329999057e44ffe936cfa77"
      url: "https://pub.dev"
    source: hosted
    version: "3.1.4"
  vector_math:
    dependency: transitive
    description:
      name: vector_math
      sha256: "80b3257d1492ce4d091729e3a67a60407d227c27241d6927be0130c98e741803"
      url: "https://pub.dev"
    source: hosted
    version: "2.1.4"
  vm_service:
    dependency: transitive
    description:
      name: vm_service
      sha256: "0968250880a6c5fe7edc067ed0a13d4bae1577fe2771dcf3010d52c4a9d3ca14"
      url: "https://pub.dev"
    source: hosted
    version: "14.3.1"
  web:
    dependency: transitive
    description:
      name: web
      sha256: "868d88a33d8a87b18ffc05f9f030ba328ffefba92d6c127917a2ba740f9cfe4a"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.1"
  web_socket:
    dependency: transitive
    description:
      name: web_socket
      sha256: "3c12d96c0c9a4eec095246debcea7b86c0324f22df69893d538fcc6f1b8cce83"
      url: "https://pub.dev"
    source: hosted
    version: "0.1.6"
  web_socket_channel:
    dependency: transitive
    description:
      name: web_socket_channel
      sha256: "0b8e2457400d8a859b7b2030786835a28a8e80836ef64402abef392ff4f1d0e5"
      url: "https://pub.dev"
    source: hosted
    version: "3.0.2"
  win32:
    dependency: transitive
    description:
      name: win32
      sha256: dc6ecaa00a7c708e5b4d10ee7bec8c270e9276dfcab1783f57e9962d7884305f
      url: "https://pub.dev"
    source: hosted
    version: "5.12.0"
  xdg_directories:
    dependency: transitive
    description:
      name: xdg_directories
      sha256: "7a3f37b05d989967cdddcbb571f1ea834867ae2faa29725fd085180e0883aa15"
      url: "https://pub.dev"
    source: hosted
    version: "1.1.0"
  xml:
    dependency: transitive
    description:
      name: xml
      sha256: b015a8ad1c488f66851d762d3090a21c600e479dc75e68328c52774040cf9226
      url: "https://pub.dev"
    source: hosted
    version: "6.5.0"
  yaml:
    dependency: transitive
    description:
      name: yaml
      sha256: b9da305ac7c39faa3f030eccd175340f968459dae4af175130b3fc47e40d76ce
      url: "https://pub.dev"
    source: hosted
    version: "3.1.3"
  yet_another_json_isolate:
    dependency: transitive
    description:
      name: yet_another_json_isolate
      sha256: "56155e9e0002cc51ea7112857bbcdc714d4c35e176d43e4d3ee233009ff410c9"
      url: "https://pub.dev"
    source: hosted
    version: "2.0.3"
sdks:
  dart: ">=3.7.0 <4.0.0"
  flutter: ">=3.27.0"

```

### File: `analysis_options.yaml`
```yaml
# This file configures the analyzer, which statically analyzes Dart code to
# check for errors, warnings, and lints.
#
# The issues identified by the analyzer are surfaced in the UI of Dart-enabled
# IDEs (https://dart.dev/tools#ides-and-editors). The analyzer can also be
# invoked from the command line by running `flutter analyze`.

# The following line activates a set of recommended lints for Flutter apps,
# packages, and plugins designed to encourage good coding practices.
include: package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
  # section below to disable rules from the `package:flutter_lints/flutter.yaml`
  # included above or to enable additional rules. A list of all available lints
  # and their documentation is published at https://dart.dev/lints.
  #
  # Instead of disabling a lint rule for the entire project in the
  # section below, it can also be suppressed for a single line of code
  # or a specific dart file by using the `// ignore: name_of_lint` and
  # `// ignore_for_file: name_of_lint` syntax on the line or in the file
  # producing the lint.
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule

# Additional information about this file can be found at
# https://dart.dev/guides/language/analysis-options

```

### File: `database.sql`
```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create job_status_new enum type
CREATE TYPE job_status_new AS ENUM (
    'open',
    'assigned',
    'awaitingPickupVerification',
    'inTransit',
    'awaitingDeliveryVerification',
    'completed',
    'cancelled'
);

-- Create application_status enum type
CREATE TYPE application_status AS ENUM (
    'pending',
    'accepted',
    'rejected'
);

-- Create broker_driver_status enum type
CREATE TYPE broker_driver_status AS ENUM (
    'pending',
    'active',
    'rejected',
    'removed'
);

-- Create profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('driver', 'warehouse_owner', 'broker')),
    address TEXT,
    city TEXT,
    state TEXT,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now())
);

-- Create driver details table
CREATE TABLE public.driver_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    license_number TEXT,
    license_expiry DATE,
    vehicle_type TEXT,
    experience_years INTEGER,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(user_id)
);

-- Create warehouse details table
CREATE TABLE public.warehouse_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    warehouse_name TEXT,
    storage_capacity DECIMAL,
    operating_hours TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(user_id)
);

-- Create broker details table
CREATE TABLE public.broker_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    company_name TEXT,
    registration_number TEXT,
    years_in_business INTEGER,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(user_id)
);

-- Create jobs table
CREATE TABLE public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    goods_type TEXT NOT NULL,
    weight DECIMAL NOT NULL,
    weight_unit TEXT DEFAULT 'kg', -- e.g. kg, lb
    price DECIMAL NOT NULL,
    price_currency TEXT DEFAULT 'INR', -- e.g. INR, USD
    vehicle_type TEXT, -- e.g. Truck, Van
    pickup_location TEXT NOT NULL,
    pickup_lat DECIMAL,
    pickup_lng DECIMAL,
    destination TEXT NOT NULL,
    destination_lat DECIMAL,
    destination_lng DECIMAL,
    distance DECIMAL NOT NULL,
    scheduled_pickup_time TIMESTAMPTZ,
    estimated_duration INTERVAL,
    job_status job_status_new DEFAULT 'open',
    posted_date TIMESTAMPTZ DEFAULT timezone('utc', now()),
    assigned_driver_id UUID REFERENCES profiles(id),
    assigned_driver_name TEXT,
    assigned_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    pickup_verified_at TIMESTAMPTZ,
    pickup_verified_by UUID REFERENCES profiles(id),
    delivery_verified_at TIMESTAMPTZ,
    delivery_verified_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now())
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);
CREATE INDEX IF NOT EXISTS idx_jobs_pickup_location ON jobs(pickup_location);
CREATE INDEX IF NOT EXISTS idx_jobs_destination ON jobs(destination);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_date ON jobs(posted_date);
CREATE INDEX IF NOT EXISTS idx_jobs_owner_status ON jobs(warehouse_owner_id, job_status);
CREATE INDEX IF NOT EXISTS idx_jobs_driver_status ON jobs(assigned_driver_id, job_status);

-- Create job applications table
CREATE TABLE public.job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status application_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(job_id, driver_id)
);

-- Create broker-driver relationship table
CREATE TABLE public.broker_drivers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    broker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status broker_driver_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
    UNIQUE(broker_id, driver_id)
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broker_drivers ENABLE ROW LEVEL SECURITY;

-- Grant access to authenticated users
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.driver_details TO authenticated;
GRANT ALL ON public.warehouse_details TO authenticated;
GRANT ALL ON public.broker_details TO authenticated;
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.job_applications TO authenticated;
GRANT ALL ON public.broker_drivers TO authenticated;

-- Create private schema for security functions
CREATE SCHEMA IF NOT EXISTS private;

-- Create security function for job relationships
CREATE OR REPLACE FUNCTION private.check_job_relationship(profile_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM jobs 
        WHERE (warehouse_owner_id = auth.uid() AND assigned_driver_id = profile_id)
           OR (assigned_driver_id = auth.uid() AND warehouse_owner_id = profile_id)
    );
END;
$$;

-- Create function to check for active jobs
CREATE OR REPLACE FUNCTION private.has_active_job(driver_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM jobs
        WHERE assigned_driver_id = driver_id
        AND job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit')
    );
END;
$$;

-- Create function to check if a job is available for application
CREATE OR REPLACE FUNCTION private.can_apply_for_job(job_id uuid, driver_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if job exists and is open
    IF NOT EXISTS (
        SELECT 1 FROM jobs 
        WHERE id = job_id 
        AND job_status = 'open'
    ) THEN
        RETURN false;
    END IF;

    -- Check if driver already has an active job
    IF private.has_active_job(driver_id) THEN
        RETURN false;
    END IF;

    -- Check if driver has already applied
    IF EXISTS (
        SELECT 1 FROM job_applications
        WHERE job_id = job_id
        AND driver_id = driver_id
    ) THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$;

-- Drop existing policies
DROP POLICY IF EXISTS "jobs_owner_update_policy" ON jobs;
DROP POLICY IF EXISTS "jobs_driver_update_policy" ON jobs;

-- Create updated policies for warehouse owners
CREATE POLICY "jobs_owner_update_policy" ON jobs
    FOR UPDATE USING (
        warehouse_owner_id = auth.uid() AND
        job_status IN ('awaitingDeliveryVerification', 'awaitingPickupVerification')
    )
    WITH CHECK (
        warehouse_owner_id = auth.uid() AND
        job_status IN ('completed', 'inTransit')
    );

-- Create updated policies for drivers
CREATE POLICY "jobs_driver_update_policy" ON jobs
    FOR UPDATE USING (
        assigned_driver_id = auth.uid() AND
        job_status IN ('assigned', 'awaitingPickupVerification', 'inTransit', 'awaitingDeliveryVerification')
    )
    WITH CHECK (
        assigned_driver_id = auth.uid() AND
        job_status IN ('awaitingPickupVerification', 'inTransit', 'awaitingDeliveryVerification')
    );

-- Drop and recreate the trigger function
DROP TRIGGER IF EXISTS validate_job_status_transition ON jobs;

CREATE OR REPLACE FUNCTION private.validate_job_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- If status hasn't changed, allow the update
    IF NEW.job_status = OLD.job_status THEN
        RETURN NEW;
    END IF;

    -- Validate the status transition
    IF NOT (
        -- Warehouse owner transitions
        (OLD.job_status = 'awaitingDeliveryVerification' AND NEW.job_status = 'completed' AND NEW.warehouse_owner_id = auth.uid()) OR
        (OLD.job_status = 'awaitingPickupVerification' AND NEW.job_status = 'inTransit' AND NEW.warehouse_owner_id = auth.uid()) OR
        -- Driver transitions
        (OLD.job_status = 'assigned' AND NEW.job_status = 'awaitingPickupVerification' AND NEW.assigned_driver_id = auth.uid()) OR
        (OLD.job_status = 'awaitingPickupVerification' AND NEW.job_status = 'inTransit' AND NEW.assigned_driver_id = auth.uid()) OR
        (OLD.job_status = 'inTransit' AND NEW.job_status = 'awaitingDeliveryVerification' AND NEW.assigned_driver_id = auth.uid()) OR
        -- Cancellation (both can do)
        (OLD.job_status IN ('open', 'assigned', 'awaitingPickupVerification', 'inTransit', 'awaitingDeliveryVerification') AND 
         NEW.job_status = 'cancelled' AND 
         (NEW.warehouse_owner_id = auth.uid() OR NEW.assigned_driver_id = auth.uid()))
    ) THEN
        RAISE EXCEPTION 'Invalid job status transition from % to %', OLD.job_status, NEW.job_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER validate_job_status_transition
    BEFORE UPDATE OF job_status ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION private.validate_job_status_transition();

-- Add helpful comments
COMMENT ON COLUMN jobs.job_status IS 'Current status of the job (open, assigned, awaitingPickupVerification, inTransit, awaitingDeliveryVerification, completed, cancelled)';

-- Profiles Policies
DROP POLICY IF EXISTS "profiles_select_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_insert_policy" ON profiles;
DROP POLICY IF EXISTS "profiles_update_policy" ON profiles;
DROP POLICY IF EXISTS "enable_insert_for_authenticated" ON profiles;

-- Allow service role full access
CREATE POLICY "service_role_policy" ON profiles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- More permissive insert policy
CREATE POLICY "profiles_insert_policy" ON profiles 
    FOR INSERT 
    TO authenticated
    WITH CHECK (
        auth.uid() = id OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "profiles_select_policy" ON profiles 
    FOR SELECT 
    TO authenticated
    USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM jobs 
            WHERE 
                (warehouse_owner_id = auth.uid() AND assigned_driver_id = profiles.id)
                OR 
                (assigned_driver_id = auth.uid() AND warehouse_owner_id = profiles.id)
        )
    );

CREATE POLICY "profiles_update_policy" ON profiles 
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, authenticated, service_role;
GRANT ALL ON public.profiles TO postgres, authenticated, service_role;

-- Create index for profiles
CREATE INDEX IF NOT EXISTS idx_profiles_id ON profiles(id);

-- Driver Details Policies
CREATE POLICY "driver_details_select_policy" ON driver_details
    FOR SELECT USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT assigned_driver_id 
            FROM jobs 
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "driver_details_update_policy" ON driver_details
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "driver_details_insert_policy" ON driver_details
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Warehouse Details Policies
CREATE POLICY "warehouse_details_select_policy" ON warehouse_details
    FOR SELECT USING (
        user_id = auth.uid() OR
        user_id IN (
            SELECT warehouse_owner_id 
            FROM jobs 
            WHERE assigned_driver_id = auth.uid()
        )
    );

CREATE POLICY "warehouse_details_update_policy" ON warehouse_details
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "warehouse_details_insert_policy" ON warehouse_details
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Broker Details Policies
CREATE POLICY "broker_details_select_policy" ON broker_details
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "broker_details_update_policy" ON broker_details
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "broker_details_insert_policy" ON broker_details
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Jobs Policies
DROP POLICY IF EXISTS "jobs_open_select_policy" ON jobs;
CREATE POLICY "jobs_open_select_policy" ON jobs
    FOR SELECT
    TO authenticated, anon
    USING (job_status = 'open');

DROP POLICY IF EXISTS "jobs_own_select_policy" ON jobs;
CREATE POLICY "jobs_own_select_policy" ON jobs
    FOR SELECT USING (
        warehouse_owner_id = auth.uid() OR
        assigned_driver_id = auth.uid()
    );

DROP POLICY IF EXISTS "jobs_insert_policy" ON jobs;
CREATE POLICY "jobs_insert_policy" ON jobs
    FOR INSERT WITH CHECK (
        warehouse_owner_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'warehouse_owner'
        )
    );

DROP POLICY IF EXISTS "drivers_can_apply_for_jobs" ON job_applications;
CREATE POLICY "drivers_can_apply_for_jobs"
ON job_applications
FOR INSERT
TO authenticated
WITH CHECK (
    driver_id = (SELECT auth.uid()) AND
    private.can_apply_for_job(job_id, driver_id)
);

-- Job Applications Policies
CREATE POLICY "applications_select_policy" ON job_applications
    FOR SELECT USING (
        driver_id = auth.uid() OR
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "applications_insert_policy" ON job_applications
    FOR INSERT WITH CHECK (
        driver_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'driver'
        )
    );

CREATE POLICY "applications_driver_update_policy" ON job_applications
    FOR UPDATE USING (driver_id = auth.uid())
    WITH CHECK (driver_id = auth.uid());

CREATE POLICY "applications_owner_update_policy" ON job_applications
    FOR UPDATE USING (
        job_id IN (
            SELECT id FROM jobs
            WHERE warehouse_owner_id = auth.uid()
        )
    );

CREATE POLICY "applications_delete_policy" ON job_applications
    FOR DELETE USING (
        driver_id = auth.uid() AND
        status = 'pending'
    );

-- Broker-Driver Relationship Policies
CREATE POLICY "broker_drivers_select_policy" ON broker_drivers
    FOR SELECT USING (
        broker_id = auth.uid() OR
        driver_id = auth.uid()
    );

CREATE POLICY "broker_drivers_insert_policy" ON broker_drivers
    FOR INSERT WITH CHECK (
        broker_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'broker'
        )
    );

CREATE POLICY "broker_drivers_update_policy" ON broker_drivers
    FOR UPDATE USING (broker_id = auth.uid() OR driver_id = auth.uid());

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone);
CREATE INDEX IF NOT EXISTS idx_driver_details_user_id ON driver_details(user_id);
CREATE INDEX IF NOT EXISTS idx_warehouse_details_user_id ON warehouse_details(user_id);
CREATE INDEX IF NOT EXISTS idx_broker_details_user_id ON broker_details(user_id);
CREATE INDEX IF NOT EXISTS idx_jobs_warehouse_owner ON jobs(warehouse_owner_id);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_driver ON jobs(assigned_driver_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);
CREATE INDEX IF NOT EXISTS idx_job_applications_job ON job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_driver ON job_applications(driver_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_status ON job_applications(status);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_broker ON broker_drivers(broker_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_driver ON broker_drivers(driver_id);
CREATE INDEX IF NOT EXISTS idx_broker_drivers_status ON broker_drivers(status);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_jobs_owner_status ON jobs(warehouse_owner_id, job_status);
CREATE INDEX IF NOT EXISTS idx_jobs_driver_status ON jobs(assigned_driver_id, job_status);
CREATE INDEX IF NOT EXISTS idx_applications_job_status ON job_applications(job_id, status);
CREATE INDEX IF NOT EXISTS idx_applications_driver_status ON job_applications(driver_id, status);
```


## 12. Documentation

### Folder: `docs/`
- Paste each documentation file here, e.g.:
#### File: `docs/DATABASE_STRUCTURE.md`
```markdown
# Database Structure and API Documentation

## Database Tables

### 1. profiles
Primary table for user profiles
```sql
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    full_name TEXT,
    role TEXT NOT NULL,
    is_profile_complete BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ
);
```

### 2. driver_details
Details specific to driver users
```sql
CREATE TABLE public.driver_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    license_number TEXT,
    license_expiry TIMESTAMPTZ,
    vehicle_type TEXT,
    experience_years INTEGER,
    updated_at TIMESTAMPTZ
);
```

### 3. warehouse_details
Details specific to warehouse owners
```sql
CREATE TABLE public.warehouse_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    warehouse_name TEXT,
    location TEXT,
    storage_capacity NUMERIC,
    updated_at TIMESTAMPTZ
);
```

### 4. broker_details
Details specific to brokers
```sql
CREATE TABLE public.broker_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id),
    company_name TEXT,
    registration_number TEXT,
    years_in_business INTEGER,
    updated_at TIMESTAMPTZ
);
```

### 5. jobs
Main table for job listings
```sql
CREATE TABLE public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_owner_id UUID REFERENCES public.profiles(id),
    assigned_driver_id UUID REFERENCES public.profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    goods_type TEXT,
    weight NUMERIC,
    price NUMERIC,
    pickup_location TEXT,
    destination TEXT,
    distance NUMERIC,
    status TEXT DEFAULT 'open',
    posted_date TIMESTAMPTZ DEFAULT NOW(),
    assigned_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

### 6. job_applications
Table for tracking job applications
```sql
CREATE TABLE public.job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES public.jobs(id),
    driver_id UUID REFERENCES public.profiles(id),
    status TEXT DEFAULT 'pending',
    updated_at TIMESTAMPTZ,
    UNIQUE(job_id, driver_id)
);
```

## API Methods Documentation

### Authentication Methods

1. `initialize()`
   - Purpose: Initializes Supabase client with environment variables
   - Parameters: None
   - Returns: Future<void>
   - Implementation:
     ```dart
     static Future<void> initialize() async {
       await dotenv.load();
       await Supabase.initialize(
         url: dotenv.env['SUPABASE_URL']!,
         anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
       );
     }
     ```

2. `signUp()`
   - Purpose: Creates new user account and profile
   - Parameters:
     - email: String
     - password: String
     - fullName: String
     - role: String
   - Returns: Future<AuthResponse>
   - Process:
     1. Creates auth user
     2. Creates profile record
     3. Creates role-specific details
   - Implementation:
     ```dart
     static Future<AuthResponse> signUp({
       required String email,
       required String password,
       required String fullName,
       required String role,
     }) async {
       // Implementation details in code
     }
     ```

3. `signIn()`
   - Purpose: Authenticates existing user
   - Parameters:
     - email: String
     - password: String
   - Returns: Future<AuthResponse>
   - Implementation:
     ```dart
     static Future<AuthResponse> signIn({
       required String email,
       required String password,
     }) async {
       return await client.auth.signInWithPassword(
         email: email,
         password: password,
       );
     }
     ```

### Profile Management Methods

1. `getUserProfile()`
   - Purpose: Fetches complete user profile with role-specific details
   - Parameters: None (uses current user)
   - Returns: Future<UserProfile?>
   - Process:
     1. Fetches basic profile
     2. Fetches role-specific details
     3. Combines data into UserProfile object
   - Implementation:
     ```dart
     static Future<UserProfile?> getUserProfile() async {
       // Implementation details in code
     }
     ```

2. `updateProfile()`
   - Purpose: Updates user profile data
   - Parameters:
     - userId: String
     - data: Map<String, dynamic>
   - Returns: Future<void>
   - Implementation:
     ```dart
     static Future<void> updateProfile(
         String userId, Map<String, dynamic> data) async {
       await client.from('profiles').update(data).eq('id', userId);
     }
     ```

### Job Management Methods

1. `postJob()`
   - Purpose: Creates new job listing
   - Parameters:
     - jobData: Map<String, dynamic>
   - Returns: Future<String> (job ID)
   - Implementation:
     ```dart
     static Future<String> postJob(Map<String, dynamic> jobData) async {
       final response =
           await client.from('jobs').insert(jobData).select().single();
       return response['id'];
     }
     ```

2. `getOpenJobs()`
   - Purpose: Fetches all open job listings
   - Parameters: None
   - Returns: Future<List<Map<String, dynamic>>>
   - Includes: Full job details with warehouse owner profile
   - Implementation:
     ```dart
     static Future<List<Map<String, dynamic>>> getOpenJobs() async {
       // Implementation details in code
     }
     ```

### Job Application Methods

1. `applyForJob()`
   - Purpose: Creates job application
   - Parameters:
     - jobId: String
     - driverId: String
   - Returns: Future<void>
   - Validations:
     - No active jobs
     - Job still open
     - No duplicate applications
   - Implementation:
     ```dart
     static Future<void> applyForJob(String jobId, String driverId) async {
       // Implementation details in code
     }
     ```

### Realtime Subscriptions

1. `subscribeToJobs()`
   - Purpose: Sets up realtime updates for job listings
   - Parameters:
     - onJobsUpdate: Function callback
   - Returns: RealtimeChannel
   - Implementation:
     ```dart
     static RealtimeChannel subscribeToJobs(
         void Function(List<Map<String, dynamic>>) onJobsUpdate) {
       // Implementation details in code
     }
     ```

## Security Policies

### Profiles Table
```sql
-- Select: Own profile or profiles interacted with through jobs
CREATE POLICY profiles_select_policy ON profiles
    FOR SELECT USING (
        id = auth.uid() OR
        id IN (
            SELECT assigned_driver_id FROM jobs WHERE warehouse_owner_id = auth.uid()
            UNION
            SELECT warehouse_owner_id FROM jobs WHERE assigned_driver_id = auth.uid()
        )
    );

-- Update: Only own profile
CREATE POLICY profiles_update_policy ON profiles
    FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- Insert: Only own profile
CREATE POLICY profiles_insert_policy ON profiles
    FOR INSERT WITH CHECK (id = auth.uid());
```

### Role-Specific Tables
```sql
-- Select: Only own details
CREATE POLICY role_details_select_policy ON {table_name}
    FOR SELECT USING (user_id = auth.uid());
```

## Data Models

### UserProfile
```dart
class UserProfile {
    String id;
    String email;
    String? fullName;
    String role;
    bool isProfileComplete;
    DateTime? updatedAt;
    Map<String, dynamic>? warehouseDetails;
    Map<String, dynamic>? driverDetails;
    Map<String, dynamic>? brokerDetails;
}
```

## Important Notes

1. Database Relationships:
   - All role-specific tables reference the profiles table
   - Jobs table references profiles table twice (warehouse_owner and assigned_driver)
   - Job applications link jobs with driver profiles

2. Security Considerations:
   - Row Level Security (RLS) enabled on all tables
   - Policies ensure users can only access their own data
   - Special policies for job-related profile access

3. Timestamps:
   - All tables include updated_at for tracking changes
   - Jobs table includes additional date fields for status tracking
   - All timestamps are in UTC

4. Status Fields:
   - Jobs: 'open', 'assigned', 'in_progress', 'completed'
   - Applications: 'pending', 'accepted', 'rejected'
   - Profiles: is_profile_complete boolean flag

5. Role Types:
   - 'driver'
   - 'warehouse_owner'
   - 'broker' 
```
#### File: `docs/JOB_MANAGEMENT.md`
```markdown
# Job Management Documentation

## Overview
The job management system handles the creation, assignment, and tracking of transportation jobs between warehouse owners and drivers, with brokers facilitating connections.

## Database Schema

### Jobs Table
```sql
CREATE TABLE public.jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    warehouse_owner_id UUID REFERENCES public.profiles(id),
    assigned_driver_id UUID REFERENCES public.profiles(id),
    title TEXT NOT NULL,
    description TEXT,
    goods_type TEXT,
    weight NUMERIC,
    price NUMERIC,
    pickup_location TEXT,
    destination TEXT,
    distance NUMERIC,
    status TEXT DEFAULT 'open',
    posted_date TIMESTAMPTZ DEFAULT NOW(),
    assigned_date TIMESTAMPTZ,
    completion_date TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

### Job Applications Table
```sql
CREATE TABLE public.job_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES public.jobs(id),
    driver_id UUID REFERENCES public.profiles(id),
    status TEXT DEFAULT 'pending',
    updated_at TIMESTAMPTZ,
    UNIQUE(job_id, driver_id)
);
```

## Core Methods

### 1. postJob()
```dart
static Future<String> postJob(Map<String, dynamic> jobData) async
```
#### Purpose
Creates a new job listing.

#### Parameters
```dart
{
  'warehouse_owner_id': String,
  'title': String,
  'description': String,
  'goods_type': String,
  'weight': double,
  'price': double,
  'pickup_location': String,
  'destination': String,
  'distance': double,
}
```

#### Implementation Details
1. Validates job data
2. Sets default status to 'open'
3. Adds timestamps
4. Creates job record
5. Returns job ID

### 2. getOpenJobs()
```dart
static Future<List<Map<String, dynamic>>> getOpenJobs() async
```
#### Purpose
Fetches all available job listings.

#### Implementation Details
1. Queries jobs with status 'open'
2. Joins with warehouse owner profile
3. Orders by posted date
4. Returns formatted job list

### 3. applyForJob()
```dart
static Future<void> applyForJob(String jobId, String driverId) async
```
#### Purpose
Submits a job application.

#### Validation Checks
1. Driver has no active jobs
2. Job is still open
3. No duplicate applications

#### Implementation
```dart
// Check active jobs
final hasActive = await hasActiveJob(driverId);
if (hasActive) throw Exception('Already has active job');

// Check job status
final job = await client
    .from('jobs')
    .select('status')
    .eq('id', jobId)
    .single();
if (job['status'] != 'open') throw Exception('Job not available');

// Create application
await client.from('job_applications').insert({
  'job_id': jobId,
  'driver_id': driverId,
  'status': 'pending',
  'updated_at': DateTime.now().toUtc().toIso8601String(),
});
```

### 4. updateJobStatus()
```dart
static Future<void> updateJobStatus(String jobId, String status) async
```
#### Purpose
Updates job status and related timestamps.

#### Valid Status Values
- 'open': Initial state
- 'assigned': Driver selected
- 'in_progress': Delivery started
- 'completed': Delivery finished

#### Implementation
```dart
final now = DateTime.now().toUtc();
final data = {
  'status': status,
  'updated_at': now.toIso8601String(),
};

if (status == 'completed') {
  data['completion_date'] = now.toIso8601String();
}

await client.from('jobs').update(data).eq('id', jobId);
```

## Job Application Flow

### 1. Job Posting
```dart
// Warehouse owner creates job
final jobId = await postJob({
  'title': 'Furniture Delivery',
  'price': 1000,
  // ... other job details
});
```

### 2. Application Process
```dart
// Driver applies for job
await applyForJob(jobId, driverId);

// Warehouse owner reviews applications
final applications = await getJobApplications(jobId);

// Accept an application
await updateApplicationStatus(
  applicationId,
  'accepted',
  jobId,
  driverId: selectedDriverId
);
```

### 3. Job Progress
```dart
// Update job status as it progresses
await updateJobStatus(jobId, 'in_progress');
// ... delivery happens ...
await updateJobStatus(jobId, 'completed');
```

## Security Policies

### Jobs Table
```sql
-- Read access
CREATE POLICY "Anyone can read open jobs"
ON jobs FOR SELECT
USING (status = 'open');

CREATE POLICY "Users can read their own jobs"
ON jobs FOR SELECT
USING (
    warehouse_owner_id = auth.uid() OR
    assigned_driver_id = auth.uid()
);

-- Insert access
CREATE POLICY "Warehouse owners can create jobs"
ON jobs FOR INSERT
WITH CHECK (warehouse_owner_id = auth.uid());

-- Update access
CREATE POLICY "Job owners can update jobs"
ON jobs FOR UPDATE
USING (warehouse_owner_id = auth.uid());
```

### Job Applications Table
```sql
-- Read access
CREATE POLICY "Users can read relevant applications"
ON job_applications FOR SELECT
USING (
    driver_id = auth.uid() OR
    job_id IN (
        SELECT id FROM jobs
        WHERE warehouse_owner_id = auth.uid()
    )
);

-- Insert access
CREATE POLICY "Drivers can create applications"
ON job_applications FOR INSERT
WITH CHECK (driver_id = auth.uid());
```

## Realtime Updates

### Job Status Updates
```dart
final jobsChannel = client
    .channel('public:jobs')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'jobs',
      ),
      (payload, [ref]) {
        // Handle job updates
      },
    )
    .subscribe();
```

### Application Updates
```dart
final applicationsChannel = client
    .channel('public:job_applications')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: '*',
        schema: 'public',
        table: 'job_applications',
      ),
      (payload, [ref]) {
        // Handle application updates
      },
    )
    .subscribe();
```

## Error Handling

### Common Error Cases
1. Job Not Found
```dart
if (jobResponse == null) {
  throw Exception('Job not found: $jobId');
}
```

2. Invalid Status Transition
```dart
void validateStatusTransition(String currentStatus, String newStatus) {
  final validTransitions = {
    'open': ['assigned'],
    'assigned': ['in_progress'],
    'in_progress': ['completed'],
    'completed': [],
  };
  if (!validTransitions[currentStatus]!.contains(newStatus)) {
    throw Exception('Invalid status transition');
  }
}
```

3. Application Conflicts
```dart
try {
  await applyForJob(jobId, driverId);
} catch (e) {
  if (e.toString().contains('duplicate key')) {
    throw Exception('Already applied for this job');
  }
  rethrow;
}
```

## Best Practices

1. Job Creation
   - Validate all required fields
   - Set appropriate defaults
   - Include proper timestamps

2. Status Management
   - Use predefined status values
   - Validate status transitions
   - Update related timestamps

3. Application Handling
   - Check for conflicts
   - Validate driver availability
   - Maintain application uniqueness

4. Security
   - Enforce role-based access
   - Validate ownership
   - Protect sensitive data

## Testing Guidelines

1. Job Creation
```dart
test('should create job with valid data', () async {
  final jobId = await postJob(validJobData);
  final job = await getJob(jobId);
  expect(job.status, 'open');
});
```

2. Application Process
```dart
test('should handle job application', () async {
  await applyForJob(jobId, driverId);
  final applications = await getJobApplications(jobId);
  expect(applications.length, 1);
  expect(applications.first.status, 'pending');
});
```

3. Status Updates
```dart
test('should update job status', () async {
  await updateJobStatus(jobId, 'in_progress');
  final job = await getJob(jobId);
  expect(job.status, 'in_progress');
});
``` 
```
<!-- Repeat for all docs files -->

---

## 13. Assets and Binaries (Not Included)

- `assets/images/` — Contains image files (e.g., logo.png, Truxlo.png, Truxlo-removebg-preview.png)
- `assets/fonts/` — Contains font files (not included)

*Note: Asset and binary files are not included in this dump. Only their paths and presence are listed above.*