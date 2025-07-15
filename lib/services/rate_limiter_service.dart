import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class RateLimiterService {
  // Rate limiting configurations
  static const int maxGeneralRequests = 60; // per minute
  static const int maxLoginAttempts = 5; // per hour
  static const int maxJobApplications = 10; // per hour
  static const int maxJobPosts = 20; // per hour

  static const Duration generalWindow = Duration(minutes: 1);
  static const Duration loginWindow = Duration(hours: 1);
  static const Duration jobWindow = Duration(hours: 1);

  // Storage keys
  static const String _generalRequestsKey = 'general_requests_';
  static const String _loginAttemptsKey = 'login_attempts_';
  static const String _jobApplicationsKey = 'job_applications_';
  static const String _jobPostsKey = 'job_posts_';

  /// Check if general API request is allowed
  static Future<RateLimitResult> checkGeneralRequest(String userId) async {
    return await _checkRateLimit(
      userId,
      _generalRequestsKey,
      maxGeneralRequests,
      generalWindow,
      'general API requests',
    );
  }

  /// Check if login attempt is allowed
  static Future<RateLimitResult> checkLoginAttempt(String email) async {
    return await _checkRateLimit(
      email.toLowerCase(),
      _loginAttemptsKey,
      maxLoginAttempts,
      loginWindow,
      'login attempts',
    );
  }

  /// Check if job application is allowed
  static Future<RateLimitResult> checkJobApplication(String userId) async {
    return await _checkRateLimit(
      userId,
      _jobApplicationsKey,
      maxJobApplications,
      jobWindow,
      'job applications',
    );
  }

  /// Check if job posting is allowed
  static Future<RateLimitResult> checkJobPost(String userId) async {
    return await _checkRateLimit(
      userId,
      _jobPostsKey,
      maxJobPosts,
      jobWindow,
      'job posts',
    );
  }

  /// Record a successful request
  static Future recordRequest(String userId, String type) async {
    final key = _getKeyForType(type) + userId;
    await _recordTimestamp(key);
  }

  // Private helper methods
  static Future<RateLimitResult> _checkRateLimit(
    String identifier,
    String keyPrefix,
    int maxRequests,
    Duration window,
    String operationType,
  ) async {
    final key = keyPrefix + identifier;
    final timestamps = await _getTimestamps(key);
    final now = DateTime.now();
    timestamps.removeWhere((timestamp) => now.difference(timestamp) > window);
    if (timestamps.length >= maxRequests) {
      final oldestTimestamp = timestamps.first;
      final resetTime = oldestTimestamp.add(window);
      final waitTime = resetTime.difference(now);
      return RateLimitResult(
        allowed: false,
        remainingRequests: 0,
        resetTime: resetTime,
        waitTime: waitTime,
        message: 'Rate limit exceeded for $operationType. Try again in ${_formatDuration(waitTime)}.',
      );
    }
    final remaining = maxRequests - timestamps.length;
    return RateLimitResult(
      allowed: true,
      remainingRequests: remaining,
      resetTime: now.add(window),
      waitTime: Duration.zero,
      message: 'Request allowed. $remaining requests remaining.',
    );
  }

  static Future<List<DateTime>> _getTimestamps(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStrings = prefs.getStringList(key) ?? [];
    return timestampStrings.map((s) => DateTime.parse(s)).toList();
  }

  static Future _recordTimestamp(String key) async {
    final timestamps = await _getTimestamps(key);
    timestamps.add(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final timestampStrings = timestamps.map((t) => t.toIso8601String()).toList();
    await prefs.setStringList(key, timestampStrings);
  }

  static String _getKeyForType(String type) {
    switch (type) {
      case 'general':
        return _generalRequestsKey;
      case 'login':
        return _loginAttemptsKey;
      case 'job_application':
        return _jobApplicationsKey;
      case 'job_post':
        return _jobPostsKey;
      default:
        return _generalRequestsKey;
    }
  }

  static String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class RateLimitResult {
  final bool allowed;
  final int remainingRequests;
  final DateTime resetTime;
  final Duration waitTime;
  final String message;

  RateLimitResult({
    required this.allowed,
    required this.remainingRequests,
    required this.resetTime,
    required this.waitTime,
    required this.message,
  });
} 