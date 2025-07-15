import 'package:supabase_flutter/supabase_flutter.dart';
import 'fraud_detection_service.dart';

class FraudAlertService {
  static Future<List<FraudAlert>> getAllAlerts({
    RiskLevel? riskLevel,
    bool? resolved,
    int limit = 50,
  }) async {
    try {
      var query = Supabase.instance.client
          .from('fraud_alerts')
          .select('*, profiles!inner(name, email)')
          .order('created_at', ascending: false)
          .limit(limit);
      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel.toString());
      }
      if (resolved != null) {
        query = query.eq('resolved', resolved);
      }
      final response = await query;
      return response.map<FraudAlert>((data) => FraudAlert.fromDatabase(data)).toList();
    } catch (e) {
      print('Error fetching fraud alerts: $e');
      return [];
    }
  }

  static Future resolveAlert(String alertId, String adminId, String resolution) async {
    try {
      await Supabase.instance.client
          .from('fraud_alerts')
          .update({
            'resolved': true,
            'resolved_by': adminId,
            'resolution': resolution,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
    } catch (e) {
      print('Error resolving fraud alert: $e');
    }
  }

  static Future<FraudStatistics> getFraudStatistics() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final todaysAlerts = await Supabase.instance.client
          .from('fraud_alerts')
          .select('risk_level')
          .gte('created_at', startOfDay.toIso8601String());
      final unresolvedAlerts = await Supabase.instance.client
          .from('fraud_alerts')
          .select('risk_level')
          .eq('resolved', false);
      final highRiskAlerts = unresolvedAlerts
          .where((alert) => alert['risk_level'] == 'RiskLevel.high')
          .length;
      return FraudStatistics(
        totalAlertsToday: todaysAlerts.length,
        unresolvedAlerts: unresolvedAlerts.length,
        highRiskAlerts: highRiskAlerts,
        mediumRiskAlerts: unresolvedAlerts
            .where((alert) => alert['risk_level'] == 'RiskLevel.medium')
            .length,
        lowRiskAlerts: unresolvedAlerts
            .where((alert) => alert['risk_level'] == 'RiskLevel.low')
            .length,
      );
    } catch (e) {
      print('Error fetching fraud statistics: $e');
      return FraudStatistics(
        totalAlertsToday: 0,
        unresolvedAlerts: 0,
        highRiskAlerts: 0,
        mediumRiskAlerts: 0,
        lowRiskAlerts: 0,
      );
    }
  }
}

class FraudAlert {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String activityType;
  final RiskLevel riskLevel;
  final String reason;
  final String? details;
  final String? recommendedAction;
  final bool resolved;
  final String? resolvedBy;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  FraudAlert({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.activityType,
    required this.riskLevel,
    required this.reason,
    this.details,
    this.recommendedAction,
    required this.resolved,
    this.resolvedBy,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  factory FraudAlert.fromDatabase(Map data) {
    return FraudAlert(
      id: data['id'],
      userId: data['user_id'],
      userName: data['profiles']['name'],
      userEmail: data['profiles']['email'],
      activityType: data['activity_type'],
      riskLevel: RiskLevel.values.firstWhere(
        (level) => level.toString() == data['risk_level'],
        orElse: () => RiskLevel.unknown,
      ),
      reason: data['reason'],
      details: data['details'],
      recommendedAction: data['recommended_action'],
      resolved: data['resolved'] ?? false,
      resolvedBy: data['resolved_by'],
      resolution: data['resolution'],
      createdAt: DateTime.parse(data['created_at']),
      resolvedAt: data['resolved_at'] != null 
          ? DateTime.parse(data['resolved_at'])
          : null,
    );
  }
}

class FraudStatistics {
  final int totalAlertsToday;
  final int unresolvedAlerts;
  final int highRiskAlerts;
  final int mediumRiskAlerts;
  final int lowRiskAlerts;

  FraudStatistics({
    required this.totalAlertsToday,
    required this.unresolvedAlerts,
    required this.highRiskAlerts,
    required this.mediumRiskAlerts,
    required this.lowRiskAlerts,
  });
} 