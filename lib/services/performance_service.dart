import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class PerformanceService {
  static final Map<String, DateTime> _timers = {};
  static final Map<String, int> _counters = {};

  // Start timing an operation
  static void startTimer(String operation) {
    _timers[operation] = DateTime.now();
  }

  // End timing and log result
  static void endTimer(String operation) {
    final startTime = _timers[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _logPerformance(operation, duration);
      _timers.remove(operation);
    }
  }

  // Increment counter for tracking operations
  static void incrementCounter(String operation) {
    _counters[operation] = (_counters[operation] ?? 0) + 1;
  }

  // Log performance metrics
  static void _logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      developer.log(
        'Performance: $operation took ${duration.inMilliseconds}ms',
        name: 'PerformanceService',
      );
      if (duration.inMilliseconds > 1000) {
        developer.log(
          'WARNING: Slow operation detected: $operation',
          name: 'PerformanceService',
        );
      }
    }
  }

  static Map<String, dynamic> getPerformanceSummary() {
    return {
      'active_timers': _timers.keys.toList(),
      'counters': Map.from(_counters),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static void clearMetrics() {
    _timers.clear();
    _counters.clear();
  }
}

mixin PerformanceMonitoringMixin {
  void trackOperation(String operation, Function() callback) {
    PerformanceService.startTimer(operation);
    try {
      callback();
    } finally {
      PerformanceService.endTimer(operation);
    }
  }

  Future<T> trackAsyncOperation<T>(String operation, Future<T> Function() callback) async {
    PerformanceService.startTimer(operation);
    try {
      return await callback();
    } finally {
      PerformanceService.endTimer(operation);
    }
  }
} 