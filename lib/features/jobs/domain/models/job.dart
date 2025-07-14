import 'package:flutter/foundation.dart';
import '../../../auth/domain/models/user_profile.dart';

class Job {
  final String id;
  final String title;
  final String description;
  final String goodsType;
  final double weight;
  final double price;
  final String pickupLocation;
  final String destination;
  final double distance;
  final String jobStatus;
  final DateTime? postedDate;
  final DateTime? assignedDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String warehouseOwnerId;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final UserProfile? warehouseOwner;
  final UserProfile? assignedDriver;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.goodsType,
    required this.weight,
    required this.price,
    required this.pickupLocation,
    required this.destination,
    required this.distance,
    required this.jobStatus,
    this.postedDate,
    this.assignedDate,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.warehouseOwnerId,
    this.assignedDriverId,
    this.assignedDriverName,
    this.warehouseOwner,
    this.assignedDriver,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing Job from JSON: $json');
      
      final id = json['id'] as String?;
      final title = json['title'] as String?;
      final description = json['description'] as String?;
      final goodsType = json['goods_type'] as String?;
      final weight = json['weight'] as num?;
      final price = json['price'] as num?;
      final pickupLocation = json['pickup_location'] as String?;
      final destination = json['destination'] as String?;
      final distance = json['distance'] as num?;
      final jobStatus = json['job_status'] as String?;
      final postedDate = json['posted_date'] as String?;
      final assignedDate = json['assigned_date'] as String?;
      final completionDate = json['completion_date'] as String?;
      final createdAt = json['created_at'] as String?;
      final updatedAt = json['updated_at'] as String?;
      final warehouseOwnerId = json['warehouse_owner_id'] as String?;
      final assignedDriverId = json['assigned_driver_id'] as String?;
      final assignedDriverName = json['assigned_driver_name'] as String?;
      
      debugPrint('Parsed values:');
      debugPrint('id: $id');
      debugPrint('title: $title');
      debugPrint('description: $description');
      debugPrint('goodsType: $goodsType');
      debugPrint('weight: $weight');
      debugPrint('price: $price');
      debugPrint('pickupLocation: $pickupLocation');
      debugPrint('destination: $destination');
      debugPrint('distance: $distance');
      debugPrint('jobStatus: $jobStatus');
      debugPrint('postedDate: $postedDate');
      debugPrint('assignedDate: $assignedDate');
      debugPrint('completionDate: $completionDate');
      debugPrint('createdAt: $createdAt');
      debugPrint('updatedAt: $updatedAt');
      debugPrint('warehouseOwnerId: $warehouseOwnerId');
      debugPrint('assignedDriverId: $assignedDriverId');
      debugPrint('assignedDriverName: $assignedDriverName');

      return Job(
        id: id ?? '',
        title: title ?? '',
        description: description ?? '',
        goodsType: goodsType ?? '',
        weight: weight?.toDouble() ?? 0.0,
        price: price?.toDouble() ?? 0.0,
        pickupLocation: pickupLocation ?? '',
        destination: destination ?? '',
        distance: distance?.toDouble() ?? 0.0,
        jobStatus: jobStatus ?? 'open',
        postedDate: postedDate != null ? DateTime.parse(postedDate) : null,
        assignedDate: assignedDate != null ? DateTime.parse(assignedDate) : null,
        completionDate: completionDate != null ? DateTime.parse(completionDate) : null,
        createdAt: createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
        updatedAt: updatedAt != null ? DateTime.parse(updatedAt) : DateTime.now(),
        warehouseOwnerId: warehouseOwnerId ?? '',
        assignedDriverId: assignedDriverId,
        assignedDriverName: assignedDriverName,
        warehouseOwner: json['warehouse_owner'] != null 
            ? UserProfile.fromJson(json['warehouse_owner'] as Map<String, dynamic>) 
            : null,
        assignedDriver: json['assigned_driver'] != null 
            ? UserProfile.fromJson(json['assigned_driver'] as Map<String, dynamic>) 
            : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Job from JSON: $e');
      debugPrint('JSON data: $json');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'goods_type': goodsType,
      'weight': weight,
      'price': price,
      'pickup_location': pickupLocation,
      'destination': destination,
      'distance': distance,
      'job_status': jobStatus,
      'posted_date': postedDate?.toIso8601String(),
      'assigned_date': assignedDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'warehouse_owner_id': warehouseOwnerId,
      'assigned_driver_id': assignedDriverId,
      'assigned_driver_name': assignedDriverName,
      'warehouse_owner': warehouseOwner?.toJson(),
      'assigned_driver': assignedDriver?.toJson(),
    };
  }

  // Helper method to create a new job
  static Map<String, dynamic> createJob({
    required String warehouseOwnerId,
    required String title,
    required String description,
    required String goodsType,
    required String pickupLocation,
    required String destination,
    required double weight,
    required double price,
    required double distance,
  }) {
    final now = DateTime.now().toUtc();
    return {
      'warehouse_owner_id': warehouseOwnerId,
      'title': title,
      'description': description,
      'goods_type': goodsType,
      'pickup_location': pickupLocation,
      'destination': destination,
      'weight': weight,
      'price': price,
      'distance': distance,
      'posted_date': now.toIso8601String(),
      'job_status': 'open',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  // Placeholder data
  static List<Job> getPlaceholderJobs() {
    return [
      Job(
        id: '1',
        title: 'Furniture Delivery',
        description: 'Deliver furniture from warehouse to residential address',
        goodsType: 'Furniture',
        weight: 150.0,
        price: 2500.0,
        pickupLocation: 'Warehouse A, Industrial Area',
        destination: '123 Main Street, City Center',
        distance: 8.5,
        jobStatus: 'open',
        postedDate: DateTime.now().subtract(const Duration(hours: 2)),
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        warehouseOwnerId: 'Warehouse A',
        assignedDriverId: null,
        assignedDriverName: null,
        warehouseOwner: null,
        assignedDriver: null,
      ),
      Job(
        id: '2',
        title: 'Electronics Transport',
        description: 'Transport electronic goods to retail store',
        goodsType: 'Electronics',
        weight: 75.0,
        price: 1800.0,
        pickupLocation: 'Electronics Hub, Tech Park',
        destination: '456 Market Street, Shopping District',
        distance: 5.2,
        jobStatus: 'open',
        postedDate: DateTime.now().subtract(const Duration(hours: 4)),
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        warehouseOwnerId: 'Electronics Hub',
        assignedDriverId: null,
        assignedDriverName: null,
        warehouseOwner: null,
        assignedDriver: null,
      ),
      Job(
        id: '3',
        title: 'Food Items Delivery',
        description: 'Deliver food items to restaurant chain',
        goodsType: 'Food Items',
        weight: 200.0,
        price: 3000.0,
        pickupLocation: 'Food Processing Unit, Industrial Zone',
        destination: '789 Restaurant Street, Food Court',
        distance: 12.0,
        jobStatus: 'open',
        postedDate: DateTime.now().subtract(const Duration(hours: 1)),
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        warehouseOwnerId: 'Food Processing Unit',
        assignedDriverId: null,
        assignedDriverName: null,
        warehouseOwner: null,
        assignedDriver: null,
      ),
    ];
  }

  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? goodsType,
    double? weight,
    double? price,
    String? pickupLocation,
    String? destination,
    double? distance,
    String? jobStatus,
    DateTime? postedDate,
    DateTime? assignedDate,
    DateTime? completionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? warehouseOwnerId,
    String? assignedDriverId,
    String? assignedDriverName,
    UserProfile? warehouseOwner,
    UserProfile? assignedDriver,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goodsType: goodsType ?? this.goodsType,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      distance: distance ?? this.distance,
      jobStatus: jobStatus ?? this.jobStatus,
      postedDate: postedDate ?? this.postedDate,
      assignedDate: assignedDate ?? this.assignedDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      warehouseOwnerId: warehouseOwnerId ?? this.warehouseOwnerId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      warehouseOwner: warehouseOwner ?? this.warehouseOwner,
      assignedDriver: assignedDriver ?? this.assignedDriver,
    );
  }
}
