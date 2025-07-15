import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/job_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../providers/error_provider.dart';
import '../../../../widgets/performance_optimized_widgets.dart' as job_widgets;
import '../../../../widgets/error_display_widget.dart';
import '../../../../services/performance_service.dart';
import '../../../../core/errors/app_errors.dart';
import '../../../../middleware/rate_limit_middleware.dart';

class DriverHomePage extends ConsumerWidget with PerformanceMonitoringMixin {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget result = ErrorDisplayWidget(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Driver Dashboard'),
          backgroundColor: Color(0xFF1A1A1A),
          actions: [
            // Job count indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFE53935).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
        ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
          children: [
                  Icon(Icons.work, color: Color(0xFFE53935), size: 16),
                  SizedBox(width: 6),
            Text(
                    '${ref.watch(jobCountProvider)} Jobs',
              style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
            ),
            SizedBox(width: 16),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _handleRefresh(ref),
          child: Column(
            children: [
              // Welcome section
              if (ref.watch(userProvider).profile != null)
                _buildWelcomeSection(ref.watch(userProvider)),
              // Main content with optimized rendering
              Expanded(
                child: _buildOptimizedJobList(
                  context,
                  ref,
                  ref.watch(openJobsProvider),
                  ref.watch(isLoadingProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return trackOperation('driver_homepage_build', () => result);
  }

  Widget _buildWelcomeSection(userState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
          ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE53935),
            child: Text(
              (userState.profile!['name'] ?? 'D')[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${userState.profile!['name'] ?? 'Driver'}! ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Find your next delivery opportunity',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedJobList(BuildContext context, WidgetRef ref, List<Job> jobs, bool isLoading) {
    if (isLoading && jobs.isEmpty) {
      return _buildLoadingState();
    }
    if (jobs.isEmpty && !isLoading) {
      return _buildEmptyState(ref);
    }
    return job_widgets.OptimizedJobListView(
      jobs: jobs,
      isLoading: isLoading,
      onJobApply: (jobId) => _applyForJob(context, ref, jobId),
      onStatusUpdate: (jobId, newStatus) => _updateJobStatus(context, ref, jobId, newStatus),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE53935),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading available jobs...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
        ),
      );
    }

  Widget _buildEmptyState(WidgetRef ref) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.work_off,
              color: Colors.grey[400],
              size: 48,
            ),
            ),
          SizedBox(height: 24),
            Text(
            'No jobs available right now',
              style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pull down to refresh or check back later',
            style: TextStyle(color: Colors.grey[400]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(jobProvider.notifier).refreshJobs(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE53935),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: Icon(Icons.refresh),
            label: Text('Refresh Jobs'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh(WidgetRef ref) async {
    return trackAsyncOperation('job_refresh', () async {
      try {
        await ref.read(jobProvider.notifier).refreshJobs();
      } catch (error) {
        ref.read(errorProvider.notifier).showError(error);
      }
    });
  }

  void _applyForJob(BuildContext context, WidgetRef ref, String jobId) {
    trackOperation('job_application_dialog', () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Apply for Job', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to apply for this job? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[400]),
              ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performJobApplication(context, ref, jobId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE53935)),
              child: Text('Apply'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _performJobApplication(BuildContext context, WidgetRef ref, String jobId) async {
    try {
      final userState = ref.read(userProvider);
      // Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Applying for job...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
      // Apply with rate limiting (handled in JobApplicationService)
      final result = await ref.read(jobProvider.notifier).applyForJob(
        jobId,
        userState.user!.id,
      );
      // Hide loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.success ? 'Application Successful!' : 'Application Failed',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      result.message,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: Duration(seconds: result.success ? 3 : 5),
          action: result.success ? null : SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _performJobApplication(context, ref, jobId),
          ),
        ),
      );
      // Show persistent error for failures
      if (!result.success) {
        ref.read(errorProvider.notifier).showError(
          BusinessLogicError(result.message)
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ref.read(errorProvider.notifier).showError(error);
    }
  }

  void _updateJobStatus(BuildContext context, WidgetRef ref, String jobId, String newStatus) {
    // Implementation for status updates
    final statusDisplayName = newStatus.replaceAll('_', ' ').toLowerCase();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text('Update Job Status', style: TextStyle(color: Colors.white)),
        content: Text(
          'Mark this job as $statusDisplayName?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement status update logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Job status updated to $statusDisplayName'),
                  backgroundColor: Colors.green,
        ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE53935)),
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
