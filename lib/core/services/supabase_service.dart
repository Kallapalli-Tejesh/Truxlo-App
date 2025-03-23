import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    String? phone,
    required String role,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
          'is_profile_complete': false,
        },
      );

      if (response.user != null) {
        try {
          // Create profile
          await client.from('profiles').insert({
            'id': response.user!.id,
            'full_name': fullName,
            'phone': phone,
            'role': role,
            'is_profile_complete': false,
            'updated_at': DateTime.now().toIso8601String(),
          }).select();

          // Create role-specific details
          final roleTable = _getRoleTable(role);
          if (roleTable != null) {
            await client.from(roleTable).insert({
              'user_id': response.user!.id,
              'updated_at': DateTime.now().toIso8601String(),
            }).select();
          }
        } catch (e) {
          print('Error creating profile or role details: $e');
          // Even if profile creation fails, return the auth response
          // as the user can be created later
        }
      }

      return response;
    } catch (e) {
      print('Supabase signup error: $e');
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

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('profiles').select().eq('id', userId).single();
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
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

  // Job-related methods
  static Future<String> postJob(Map<String, dynamic> jobData) async {
    final response =
        await client.from('jobs').insert(jobData).select().single();
    return response['id'];
  }

  static Future<List<Map<String, dynamic>>> getOpenJobs() async {
    try {
      print('Querying open jobs from database...');

      // Use the same query structure as warehouse owner jobs
      final response = await client.from('jobs').select('''
            *,
            warehouse_owner:profiles!jobs_warehouse_owner_id_fkey(
              id,
              full_name,
              phone
            )
          ''').eq('status', 'open').order('posted_date', ascending: false);
      print('Open jobs response: $response');

      // Transform the response to match the expected format
      final List<Map<String, dynamic>> transformedJobs = [];
      for (var job in response) {
        final transformedJob = Map<String, dynamic>.from(job);
        // The warehouse owner details are already in the correct format
        // from the join, so no need for additional transformation
        transformedJobs.add(transformedJob);
      }

      print('Transformed jobs: $transformedJobs');
      return transformedJobs;
    } catch (e, stackTrace) {
      print('Error in getOpenJobs: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getWarehouseOwnerJobs(
      String ownerId) async {
    try {
      print('Querying warehouse owner jobs...');
      final response = await client
          .from('jobs')
          .select('''
            *,
            assigned_driver:profiles!jobs_assigned_driver_id_fkey(
              id,
              full_name
            )
          ''')
          .eq('warehouse_owner_id', ownerId)
          .order('posted_date', ascending: false);
      print('Warehouse jobs response: $response');

      // Transform the response to include assigned_driver_name
      final List<Map<String, dynamic>> transformedJobs = [];
      for (var job in response) {
        final transformedJob = Map<String, dynamic>.from(job);
        if (transformedJob['assigned_driver'] != null) {
          transformedJob['assigned_driver_name'] =
              transformedJob['assigned_driver']['full_name'];
        }
        transformedJobs.add(transformedJob);
      }
      print('Transformed jobs: $transformedJobs');

      return transformedJobs;
    } catch (e, stackTrace) {
      print('Error in getWarehouseOwnerJobs: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverJobs(
      String driverId) async {
    final response = await client
        .from('jobs')
        .select('''
          *,
          warehouse_owner:profiles!jobs_warehouse_owner_id_fkey(
            id,
            full_name,
            phone
          )
        ''')
        .eq('assigned_driver_id', driverId)
        .inFilter('status', ['assigned', 'in_progress'])
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<bool> hasActiveJob(String driverId) async {
    try {
      final response = await client
          .from('jobs')
          .select('id')
          .eq('assigned_driver_id', driverId)
          .inFilter('status', ['assigned', 'in_progress'])
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking active jobs: $e');
      rethrow;
    }
  }

  static Future<void> applyForJob(String jobId, String driverId) async {
    try {
      // Check if driver has any active jobs
      final hasActive = await hasActiveJob(driverId);
      if (hasActive) {
        throw Exception(
            'You already have an active job. Please complete your current job before applying for new ones.');
      }

      // Check if job is still open
      final job =
          await client.from('jobs').select('status').eq('id', jobId).single();

      if (job['status'] != 'open') {
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

      await client.from('job_applications').insert({
        'job_id': jobId,
        'driver_id': driverId,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      print('Error applying for job: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getJobApplications(
      String jobId) async {
    try {
      final response = await client
          .from('job_applications')
          .select('''
          id,
          status,
          created_at,
          updated_at,
          driver:profiles!job_applications_driver_id_fkey(
            id,
            full_name,
            phone,
            email
          )
        ''')
          .eq('job_id', jobId as Object)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting job applications: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getDriverApplications(
      String driverId) async {
    try {
      final response = await client
          .from('job_applications')
          .select('''
          id,
          status,
          created_at,
          updated_at,
          job:jobs!job_applications_job_id_fkey(
            id,
            title,
            status,
            pickup_location,
            destination,
            price,
            warehouse_owner:profiles!jobs_warehouse_owner_id_fkey(
              id,
              full_name
            )
          )
        ''')
          .eq('driver_id', driverId as Object)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting driver applications: $e');
      rethrow;
    }
  }

  static Future<void> updateJobStatus(String jobId, String status) async {
    try {
      final now = DateTime.now().toUtc();
      final data = {
        'status': status,
        'updated_at': now.toIso8601String(),
      };

      // Add completion date if the job is being marked as completed
      if (status == 'completed') {
        data['completion_date'] = now.toIso8601String();
      }

      await client.from('jobs').update(data).eq('id', jobId);
    } catch (e) {
      print('Error updating job status: $e');
      rethrow;
    }
  }

  static Future<void> updateApplicationStatus(
      String applicationId, String status, String jobId,
      {String? driverId}) async {
    try {
      // Get minimal application details
      final application = await client
          .from('job_applications')
          .select('id, status, job:jobs(status)')
          .eq('id', applicationId)
          .single();

      if (application == null) {
        throw Exception('Application not found');
      }

      // If accepting the application
      if (status == 'accepted') {
        // Check if job is still open
        if (application['job']['status'] != 'open') {
          throw Exception('This job is no longer available');
        }

        // Update job status and assign driver in one query
        await client.from('jobs').update({
          'status': 'assigned',
          'assigned_driver_id': driverId,
          'assigned_date': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', jobId);

        // Reject all other pending applications in one query
        await client
            .from('job_applications')
            .update({
              'status': 'rejected',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('job_id', jobId)
            .neq('id', applicationId)
            .eq('status', 'pending');
      }

      // Update the application status
      await client.from('job_applications').update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', applicationId);
    } catch (e) {
      print('Error updating application status: $e');
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
}
