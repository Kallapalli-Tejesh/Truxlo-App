import 'package:supabase_flutter/supabase_flutter.dart';
import '../middleware/rate_limit_middleware.dart';
import '../core/errors/app_errors.dart';

class JobApplicationResult {
  final bool success;
  final String message;
  final String? applicationId;

  JobApplicationResult({
    required this.success,
    required this.message,
    this.applicationId,
  });

  factory JobApplicationResult.success(String message, {String? applicationId}) =>
      JobApplicationResult(success: true, message: message, applicationId: applicationId);
  
  factory JobApplicationResult.failure(String message) =>
      JobApplicationResult(success: false, message: message);
}

class JobApplicationService {
  static Future applyForJob(String jobId, String driverId) async {
    try {
      // Apply rate limiting to job applications
      return await RateLimitMiddleware.withRateLimit(
        driverId,
        'job_application',
        () async {
          // Your existing job application logic
          final response = await Supabase.instance.client.rpc('apply_for_job_safe', params: {
            'job_id': jobId,
            'driver_id': driverId,
          });

          if (response['success'] == true) {
            return JobApplicationResult.success(
              response['message'] ?? 'Application submitted successfully',
              applicationId: response['application_id'],
            );
          } else {
            return JobApplicationResult.failure(
              response['message'] ?? 'Application failed'
            );
          }
        },
      );
    } catch (e) {
      if (e is BusinessLogicError && e.code == 'RATE_LIMIT_EXCEEDED') {
        return JobApplicationResult.failure(e.message);
      }
      return JobApplicationResult.failure('Network error:  [${e.toString()}');
    }
  }
} 