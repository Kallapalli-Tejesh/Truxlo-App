import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../features/auth/domain/models/user_profile.dart';
import '../../features/jobs/domain/models/job.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (url == null || anonKey == null) {
        throw Exception('Missing Supabase configuration');
      }
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
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
      // Add timeout to prevent hanging
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
          'phone': phone ?? '',
          'is_profile_complete': false,
        },
      ).timeout(const Duration(seconds: 30));
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
    } on TimeoutException {
      debugPrint('Signup timeout - network issue');
      throw Exception('Network timeout. Please check your connection and try again.');
    } catch (e) {
      debugPrint('Supabase signup error: $e');
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw Exception('Network error. Please check your internet connection.');
      }
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
