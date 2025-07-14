import '../services/job_application_service.dart';

class JobNotifier extends StateNotifier<JobState> {
  Future applyForJob(String jobId, String driverId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await JobApplicationService.applyForJob(jobId, driverId);
      if (result.success) {
        // Refresh jobs to show updated status
        await refreshJobs();
      }
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return JobApplicationResult.failure('Application failed:  [${e.toString()}');
    }
  }
} 