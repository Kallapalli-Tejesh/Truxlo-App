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