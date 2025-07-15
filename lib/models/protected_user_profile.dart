import '../services/encryption_service.dart';

class ProtectedUserProfile {
  final String id;
  final String email;
  final String role;
  final String _encryptedName;
  final String _encryptedPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProtectedUserProfile({
    required this.id,
    required this.email,
    required this.role,
    required String name,
    required String phone,
    required this.createdAt,
    required this.updatedAt,
  })  : _encryptedName = EncryptionService.encryptPersonalData(name),
        _encryptedPhone = EncryptionService.encryptPersonalData(phone);

  // Getters for decrypted data
  String get name => EncryptionService.decryptPersonalData(_encryptedName);
  String get phone => EncryptionService.decryptPersonalData(_encryptedPhone);

  // Factory constructor from database
  factory ProtectedUserProfile.fromDatabase(Map data) {
    return ProtectedUserProfile(
      id: data['id'],
      email: data['email'],
      role: data['role'],
      name: data['encrypted_name'] ?? data['name'], // Handle migration
      phone: data['encrypted_phone'] ?? data['phone'] ?? '',
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Convert to database format
  Map toDatabase() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'encrypted_name': _encryptedName,
      'encrypted_phone': _encryptedPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from existing profile for migration
  factory ProtectedUserProfile.fromExisting(Map data) {
    return ProtectedUserProfile(
      id: data['id'],
      email: data['email'],
      role: data['role'],
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.now(),
    );
  }
} 