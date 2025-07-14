import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/error_handler_service.dart';
import '../core/errors/app_errors.dart';
import '../services/job_application_service.dart';

// Dummy Job class for context; replace with your actual Job model
class Job {
  final String id;
  final String title;
  final String description;
  final String pickupLocation;
  final String destinationLocation;
  final double weight;
  final double price;
  final String status;
  final String warehouseOwnerId;
  final String? assignedDriverId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.weight,
    required this.price,
    required this.status,
    required this.warehouseOwnerId,
    this.assignedDriverId,
    required this.createdAt,
    required this.updatedAt,
  });
}

// Optimized job state with immutable collections and performance tracking
class JobState {
  final List<Job> jobs;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  JobState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  JobState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return JobState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JobState &&
        const ListEquality().equals(other.jobs, jobs) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      const ListEquality().hash(jobs),
      isLoading,
      error,
    );
  }
}

class JobNotifier extends StateNotifier<JobState> {
  JobNotifier() : super(JobState()) {
    _initializeJobs();
  }

  Future<void> _initializeJobs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await refreshJobs();
    } catch (error) {
      final appError = ErrorHandlerService.handleError(error);
      state = state.copyWith(
        isLoading: false,
        error: appError.message,
      );
    }
  }

  Future<void> refreshJobs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Optimized query with proper ordering and limits
      final response = await Supabase.instance.client
          .from('jobs')
          .select()
          .order('created_at', ascending: false)
          .limit(50); // Limit for performance
      final jobs = response.map<Job>((jobData) => Job(
        id: jobData['id'],
        title: jobData['title'] ?? 'Untitled Job',
        description: jobData['description'] ?? '',
        pickupLocation: jobData['pickup_location'] ?? '',
        destinationLocation: jobData['destination_location'] ?? '',
        weight: (jobData['weight'] ?? 0).toDouble(),
        price: (jobData['price'] ?? 0).toDouble(),
        status: jobData['status'] ?? 'open',
        warehouseOwnerId: jobData['warehouse_owner_id'] ?? '',
        assignedDriverId: jobData['assigned_driver_id'],
        createdAt: DateTime.parse(jobData['created_at']),
        updatedAt: DateTime.parse(jobData['updated_at']),
      )).toList();
      state = state.copyWith(
        jobs: jobs,
        isLoading: false,
      );
    } catch (e) {
      final appError = ErrorHandlerService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: appError.message,
      );
    }
  }

  Future<JobApplicationResult> applyForJob(String jobId, String driverId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await JobApplicationService.applyForJob(jobId, driverId);
      if (result.success) {
        // Refresh jobs to show updated status
        await refreshJobs();
      } else {
        throw BusinessLogicError(result.message);
      }
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      final appError = ErrorHandlerService.handleError(e);
      state = state.copyWith(
        isLoading: false,
        error: appError.message,
      );
      return JobApplicationResult.failure(appError.message);
    }
  }
}

// Optimized selectors to prevent unnecessary rebuilds
final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier();
});

final openJobsProvider = Provider<List<Job>>((ref) {
  final jobState = ref.watch(jobProvider.select((state) => state.jobs));
  return jobState.where((job) => job.status == 'open').toList();
});

final jobCountProvider = Provider<int>((ref) {
  return ref.watch(jobProvider.select((state) => state.jobs.length));
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(jobProvider.select((state) => state.isLoading));
}); 