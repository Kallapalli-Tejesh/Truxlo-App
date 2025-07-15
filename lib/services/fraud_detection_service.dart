import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class FraudDetectionService {
  static const int maxApplicationsPerHour = 10;
  static const int maxJobPostsPerDay = 50;
  static const double maxReasonableDistance = 1000; // km
  static const int minTrustScore = 30;

  static Future<FraudDetectionResult> checkRapidApplications(String driverId) async {
    try {
      final oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
      final response = await Supabase.instance.client
          .from('job_applications')
          .select('id, created_at')
          .eq('driver_id', driverId)
          .gte('created_at', oneHourAgo.toIso8601String());
      final applicationCount = response.length;
      if (applicationCount > maxApplicationsPerHour) {
        return FraudDetectionResult(
          isSuspicious: true,
          riskLevel: RiskLevel.high,
          reason: 'Rapid job applications detected',
          details: '$applicationCount applications in the last hour (limit: $maxApplicationsPerHour)',
          recommendedAction: 'Temporary application restriction',
        );
      }
      return FraudDetectionResult(
        isSuspicious: false,
        riskLevel: RiskLevel.low,
        reason: 'Normal application pattern',
        details: '$applicationCount applications in the last hour',
      );
    } catch (e) {
      return FraudDetectionResult(
        isSuspicious: false,
        riskLevel: RiskLevel.unknown,
        reason: 'Unable to check application history',
        details: e.toString(),
      );
    }
  }

  static Future<FraudDetectionResult> verifyLocationRealism(
    String pickupLocation,
    String destinationLocation,
  ) async {
    try {
      final suspiciousPatterns = [
        'test', 'fake', 'dummy', 'sample', 'example',
        '123', 'abc', 'xyz', 'null', 'undefined'
      ];
      final pickup = pickupLocation.toLowerCase();
      final destination = destinationLocation.toLowerCase();
      for (final pattern in suspiciousPatterns) {
        if (pickup.contains(pattern) || destination.contains(pattern)) {
          return FraudDetectionResult(
            isSuspicious: true,
            riskLevel: RiskLevel.high,
            reason: 'Suspicious location pattern detected',
            details: 'Locations contain test/fake patterns',
            recommendedAction: 'Manual review required',
          );
        }
      }
      if (pickup == destination) {
        return FraudDetectionResult(
          isSuspicious: true,
          riskLevel: RiskLevel.medium,
          reason: 'Identical pickup and destination',
          details: 'Same location for pickup and delivery',
          recommendedAction: 'Verify job requirements',
        );
      }
      return FraudDetectionResult(
        isSuspicious: false,
        riskLevel: RiskLevel.low,
        reason: 'Locations appear legitimate',
      );
    } catch (e) {
      return FraudDetectionResult(
        isSuspicious: false,
        riskLevel: RiskLevel.unknown,
        reason: 'Unable to verify locations',
        details: e.toString(),
      );
    }
  }

  static Future<int> calculateTrustScore(String userId) async {
    try {
      int trustScore = 50;
      final completedJobs = await Supabase.instance.client
          .from('jobs')
          .select('id')
          .eq('assigned_driver_id', userId)
          .eq('status', 'completed');
      final assignedJobs = await Supabase.instance.client
          .from('jobs')
          .select('id')
          .eq('assigned_driver_id', userId)
          .in_('status', ['assigned', 'in_transit', 'completed']);
      if (assignedJobs.isNotEmpty) {
        final completionRate = (completedJobs.length / assignedJobs.length) * 100;
        if (completionRate >= 90) {
          trustScore += 30;
        } else if (completionRate >= 70) {
          trustScore += 15;
        } else if (completionRate < 30) {
          trustScore -= 20;
        }
      }
      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select('created_at')
          .eq('id', userId)
          .maybeSingle();
      if (userProfile != null && userProfile['created_at'] != null) {
        final createdAt = DateTime.parse(userProfile['created_at']);
        final accountAge = DateTime.now().difference(createdAt).inDays;
        if (accountAge > 30) {
          trustScore += 10;
        } else if (accountAge > 7) {
          trustScore += 5;
        }
      }
      return trustScore.clamp(0, 100);
    } catch (e) {
      return 50;
    }
  }

  static Future<FraudDetectionResult> checkDeviceFingerprint(String deviceId, String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('device_sessions')
          .select('user_id')
          .eq('device_id', deviceId)
          .neq('user_id', userId);
      if (response.length > 2) {
        return FraudDetectionResult(
          isSuspicious: true,
          riskLevel: RiskLevel.high,
          reason: 'Multiple accounts detected on same device',
          details: '${response.length} different accounts used on this device',
          recommendedAction: 'Account verification required',
        );
      }
      return FraudDetectionResult(
        isSuspicious: false,
        riskLevel: RiskLevel.low,
        reason: 'Normal device usage pattern',
      );
    } catch (e) {
      return FraudDetectionResult(
        isSuspicious: false,
        riskLevel: RiskLevel.unknown,
        reason: 'Unable to check device fingerprint',
        details: e.toString(),
      );
    }
  }

  static Future<List<FraudDetectionResult>> performJobApplicationCheck(
    String driverId,
    String jobId,
  ) async {
    final results = <FraudDetectionResult>[];
    results.add(await checkRapidApplications(driverId));
    final trustScore = await calculateTrustScore(driverId);
    if (trustScore < minTrustScore) {
      results.add(FraudDetectionResult(
        isSuspicious: true,
        riskLevel: RiskLevel.high,
        reason: 'Low trust score',
        details: 'Trust score: $trustScore',
        recommendedAction: 'Account review required',
      ));
    }
    // Optionally add more checks here
    return results;
  }

  static Future<List<FraudDetectionResult>> performJobPostingCheck(
    String warehouseOwnerId,
    String pickupLocation,
    String destinationLocation,
    double price,
  ) async {
    final results = <FraudDetectionResult>[];
    results.add(await verifyLocationRealism(pickupLocation, destinationLocation));
    if (price > 100000) {
      results.add(FraudDetectionResult(
        isSuspicious: true,
        riskLevel: RiskLevel.medium,
        reason: 'Unusually high job pricing',
        details: 'Price: ₹${price.toStringAsFixed(0)}',
        recommendedAction: 'Verify job requirements',
      ));
    }
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todaysPosts = await Supabase.instance.client
        .from('jobs')
        .select('id')
        .eq('warehouse_owner_id', warehouseOwnerId)
        .gte('created_at', startOfDay.toIso8601String());
    if (todaysPosts.length > maxJobPostsPerDay) {
      results.add(FraudDetectionResult(
        isSuspicious: true,
        riskLevel: RiskLevel.high,
        reason: 'Excessive job posting',
        details: '${todaysPosts.length} jobs posted today (limit: $maxJobPostsPerDay)',
        recommendedAction: 'Account review required',
      ));
    }
    return results;
  }

  static Future logSuspiciousActivity(
    String userId,
    String activityType,
    FraudDetectionResult result,
  ) async {
    try {
      await Supabase.instance.client
          .from('fraud_alerts')
          .insert({
            'user_id': userId,
            'activity_type': activityType,
            'risk_level': result.riskLevel.toString(),
            'reason': result.reason,
            'details': result.details,
            'recommended_action': result.recommendedAction,
            'created_at': DateTime.now().toIso8601String(),
          });
      if (kDebugMode) {
        print('Fraud alert logged: ${result.reason} for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging fraud alert: $e');
      }
    }
  }
}

class FraudDetectionResult {
  final bool isSuspicious;
  final RiskLevel riskLevel;
  final String reason;
  final String? details;
  final String? recommendedAction;

  FraudDetectionResult({
    required this.isSuspicious,
    required this.riskLevel,
    required this.reason,
    this.details,
    this.recommendedAction,
  });
}

enum RiskLevel {
  low,
  medium,
  high,
  unknown,
} 