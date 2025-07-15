import '../services/encryption_service.dart';

class ProtectedJob {
  final String id;
  final String title;
  final String description;
  final String _encryptedPickupLocation;
  final String _encryptedDestinationLocation;
  final String _encryptedPrice;
  final double weight;
  final String status;
  final String warehouseOwnerId;
  final String? assignedDriverId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProtectedJob({
    required this.id,
    required this.title,
    required this.description,
    required String pickupLocation,
    required String destinationLocation,
    required double price,
    required this.weight,
    required this.status,
    required this.warehouseOwnerId,
    this.assignedDriverId,
    required this.createdAt,
    required this.updatedAt,
  })  : _encryptedPickupLocation = EncryptionService.encryptPersonalData(pickupLocation),
        _encryptedDestinationLocation = EncryptionService.encryptPersonalData(destinationLocation),
        _encryptedPrice = EncryptionService.encryptFinancialData(price);

  // Getters for decrypted data
  String get pickupLocation => EncryptionService.decryptPersonalData(_encryptedPickupLocation);
  String get destinationLocation => EncryptionService.decryptPersonalData(_encryptedDestinationLocation);
  double get price => EncryptionService.decryptFinancialData(_encryptedPrice);

  // Factory constructor from database
  factory ProtectedJob.fromDatabase(Map data) {
    return ProtectedJob(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      pickupLocation: data['encrypted_pickup_location'] ?? data['pickup_location'] ?? '',
      destinationLocation: data['encrypted_destination_location'] ?? data['destination_location'] ?? '',
      price: data['encrypted_price'] != null 
          ? EncryptionService.decryptFinancialData(data['encrypted_price'])
          : (data['price'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      status: data['status'] ?? 'open',
      warehouseOwnerId: data['warehouse_owner_id'],
      assignedDriverId: data['assigned_driver_id'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  // Convert to database format
  Map toDatabase() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'encrypted_pickup_location': _encryptedPickupLocation,
      'encrypted_destination_location': _encryptedDestinationLocation,
      'encrypted_price': _encryptedPrice,
      'weight': weight,
      'status': status,
      'warehouse_owner_id': warehouseOwnerId,
      'assigned_driver_id': assignedDriverId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from existing job for migration
  factory ProtectedJob.fromExisting(Map data) {
    return ProtectedJob(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      pickupLocation: data['pickup_location'] ?? '',
      destinationLocation: data['destination_location'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      weight: (data['weight'] ?? 0).toDouble(),
      status: data['status'] ?? 'open',
      warehouseOwnerId: data['warehouse_owner_id'],
      assignedDriverId: data['assigned_driver_id'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.now(),
    );
  }
} 