import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Session status enum for stream notifications
enum SessionStatus { active, warning, expired }

class SessionInfo {
  final bool isValid;
  final DateTime? lastActivity;
  final DateTime? sessionStart;
  final Duration? timeRemaining;

  SessionInfo({
    required this.isValid,
    this.lastActivity,
    this.sessionStart,
    this.timeRemaining,
  });

  String get timeRemainingFormatted {
    if (timeRemaining == null) return '--';
    final hours = timeRemaining!.inHours;
    final minutes = timeRemaining!.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class SessionService {
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);

  // Session management keys
  static const String _lastActivityKey = 'last_activity';
  static const String _sessionStartKey = 'session_start';
  static const String _failedAttemptsKey = 'failed_attempts_';
  static const String _lockoutTimeKey = 'lockout_time_';

  static Timer? _sessionTimer;
  static StreamController<SessionStatus>? _sessionController;

  static Stream<SessionStatus> get sessionStatusStream {
    _sessionController ??= StreamController<SessionStatus>.broadcast();
    return _sessionController!.stream;
  }

  /// Initialize session management
  static Future initializeSession() async {
    await _updateLastActivity();
    await _setSessionStart();
    _startSessionTimer();
  }

  /// Update last activity timestamp
  static Future updateActivity() async {
    await _updateLastActivity();
    _resetSessionTimer();
  }

  /// Check if current session is valid
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityStr = prefs.getString(_lastActivityKey);
    if (lastActivityStr == null) return false;
    final lastActivity = DateTime.parse(lastActivityStr);
    final now = DateTime.now();
    return now.difference(lastActivity) < sessionTimeout;
  }

  /// Record a failed login attempt
  static Future recordFailedLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _failedAttemptsKey + email.toLowerCase();
    final attemptsData = prefs.getString(key);
    List<DateTime> attempts = [];
    if (attemptsData != null) {
      final List decoded = jsonDecode(attemptsData);
      attempts = decoded.map<DateTime>((e) => DateTime.parse(e)).toList();
    }
    attempts.add(DateTime.now());
    final oneHourAgo = DateTime.now().subtract(Duration(hours: 1));
    attempts.removeWhere((attempt) => attempt.isBefore(oneHourAgo));
    final encoded = jsonEncode(attempts.map((e) => e.toIso8601String()).toList());
    await prefs.setString(key, encoded);
    if (attempts.length >= maxLoginAttempts) {
      await _lockAccount(email);
    }
    if (kDebugMode) {
      print('Failed login recorded for $email. Attempts: ${attempts.length}');
    }
  }

  /// Check if account is locked
  static Future<bool> isAccountLocked(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutKey = _lockoutTimeKey + email.toLowerCase();
    final lockoutTimeStr = prefs.getString(lockoutKey);
    if (lockoutTimeStr == null) return false;
    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();
    if (now.difference(lockoutTime) > lockoutDuration) {
      await _unlockAccount(email);
      return false;
    }
    return true;
  }

  /// Get remaining lockout time
  static Future<Duration?> getRemainingLockoutTime(String email) async {
    if (!await isAccountLocked(email)) return null;
    final prefs = await SharedPreferences.getInstance();
    final lockoutKey = _lockoutTimeKey + email.toLowerCase();
    final lockoutTimeStr = prefs.getString(lockoutKey);
    if (lockoutTimeStr == null) return null;
    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();
    final elapsed = now.difference(lockoutTime);
    return lockoutDuration - elapsed;
  }

  /// Clear failed login attempts (on successful login)
  static Future clearFailedAttempts(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _failedAttemptsKey + email.toLowerCase();
    await prefs.remove(key);
    await _unlockAccount(email);
  }

  /// Force logout current session
  static Future forceLogout() async {
    await _clearSessionData();
    await Supabase.instance.client.auth.signOut();
    _sessionController?.add(SessionStatus.expired);
    _stopSessionTimer();
  }

  /// Get session info
  static Future<SessionInfo> getSessionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityStr = prefs.getString(_lastActivityKey);
    final sessionStartStr = prefs.getString(_sessionStartKey);
    DateTime? lastActivity;
    DateTime? sessionStart;
    if (lastActivityStr != null) {
      lastActivity = DateTime.parse(lastActivityStr);
    }
    if (sessionStartStr != null) {
      sessionStart = DateTime.parse(sessionStartStr);
    }
    final isValid = await isSessionValid();
    Duration? timeRemaining;
    if (isValid && lastActivity != null) {
      final elapsed = DateTime.now().difference(lastActivity);
      timeRemaining = sessionTimeout - elapsed;
    }
    return SessionInfo(
      isValid: isValid,
      lastActivity: lastActivity,
      sessionStart: sessionStart,
      timeRemaining: timeRemaining,
    );
  }

  // Private methods
  static Future _updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  static Future _setSessionStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStartKey, DateTime.now().toIso8601String());
  }

  static Future _lockAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutKey = _lockoutTimeKey + email.toLowerCase();
    await prefs.setString(lockoutKey, DateTime.now().toIso8601String());
    if (kDebugMode) {
      print('Account locked for $email');
    }
  }

  static Future _unlockAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutKey = _lockoutTimeKey + email.toLowerCase();
    final attemptsKey = _failedAttemptsKey + email.toLowerCase();
    await prefs.remove(lockoutKey);
    await prefs.remove(attemptsKey);
  }

  static Future _clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
    await prefs.remove(_sessionStartKey);
  }

  static void _startSessionTimer() {
    _stopSessionTimer();
    _sessionTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
      final isValid = await isSessionValid();
      if (!isValid) {
        await forceLogout();
      } else {
        // Check if session is about to expire (5 minutes warning)
        final sessionInfo = await getSessionInfo();
        if (sessionInfo.timeRemaining != null && sessionInfo.timeRemaining!.inMinutes <= 5 && sessionInfo.timeRemaining!.inMinutes > 0) {
          _sessionController?.add(SessionStatus.warning);
        } else {
          _sessionController?.add(SessionStatus.active);
        }
      }
    });
  }

  static void _resetSessionTimer() {
    _startSessionTimer();
  }

  static void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
} 