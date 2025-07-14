import 'package:flutter/foundation.dart';

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final bool isProfileComplete;
  final DateTime? updatedAt;
  final Map<String, dynamic>? warehouseDetails;
  final Map<String, dynamic>? driverDetails;
  final Map<String, dynamic>? brokerDetails;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.isProfileComplete,
    this.updatedAt,
    this.warehouseDetails,
    this.driverDetails,
    this.brokerDetails,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing UserProfile from JSON: $json');
      
      final id = json['id'] as String?;
      final email = json['email'] as String?;
      final fullName = json['full_name'] as String?;
      final role = json['role'] as String?;
      final isProfileComplete = json['is_profile_complete'] as bool?;
      final updatedAt = json['updated_at'] as String?;
      final warehouseDetails = json['warehouse_details'] as Map<String, dynamic>?;
      final driverDetails = json['driver_details'] as Map<String, dynamic>?;
      final brokerDetails = json['broker_details'] as Map<String, dynamic>?;
      
      debugPrint('Parsed values:');
      debugPrint('id: $id');
      debugPrint('email: $email');
      debugPrint('fullName: $fullName');
      debugPrint('role: $role');
      debugPrint('isProfileComplete: $isProfileComplete');
      debugPrint('updatedAt: $updatedAt');
      debugPrint('warehouseDetails: $warehouseDetails');
      debugPrint('driverDetails: $driverDetails');
      debugPrint('brokerDetails: $brokerDetails');

      if (id == null || id.isEmpty) {
        debugPrint('Warning: UserProfile ID is null or empty');
      }
      if (email == null || email.isEmpty) {
        debugPrint('Warning: UserProfile email is null or empty');
      }
      if (fullName == null || fullName.isEmpty) {
        debugPrint('Warning: UserProfile fullName is null or empty');
      }

      return UserProfile(
        id: id ?? '',
        email: email ?? '',
        fullName: fullName,
        role: role ?? 'user',
        isProfileComplete: isProfileComplete ?? false,
        updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : null,
        warehouseDetails: warehouseDetails,
        driverDetails: driverDetails,
        brokerDetails: brokerDetails,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing UserProfile from JSON: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_profile_complete': isProfileComplete,
      'updated_at': updatedAt?.toIso8601String(),
      'warehouse_details': warehouseDetails,
      'driver_details': driverDetails,
      'broker_details': brokerDetails,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    bool? isProfileComplete,
    DateTime? updatedAt,
    Map<String, dynamic>? warehouseDetails,
    Map<String, dynamic>? driverDetails,
    Map<String, dynamic>? brokerDetails,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      updatedAt: updatedAt ?? this.updatedAt,
      warehouseDetails: warehouseDetails ?? this.warehouseDetails,
      driverDetails: driverDetails ?? this.driverDetails,
      brokerDetails: brokerDetails ?? this.brokerDetails,
    );
  }
} 