class Job {
  final String id;
  final String warehouseOwnerId;
  final String title;
  final String description;
  final String goodsType;
  final String pickupLocation;
  final String destination;
  final double weight; // in kg
  final double price;
  final double distance; // in km
  final DateTime postedDate;
  final String status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final DateTime? assignedDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.warehouseOwnerId,
    required this.title,
    required this.description,
    required this.goodsType,
    required this.pickupLocation,
    required this.destination,
    required this.weight,
    required this.price,
    required this.distance,
    required this.postedDate,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDate,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    // Ensure all required string fields have a default value if null
    String safeString(dynamic value, String defaultValue) {
      if (value == null || value.toString().trim().isEmpty) {
        return defaultValue;
      }
      return value.toString();
    }

    // Ensure all numeric fields have a default value if null
    double safeDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      try {
        return double.parse(value.toString());
      } catch (_) {
        return defaultValue;
      }
    }

    // Ensure all date fields have a default value if null
    DateTime safeDateTime(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return defaultValue;
      }
    }

    final now = DateTime.now().toUtc();

    // Extract warehouse owner details
    final warehouseOwner = json['warehouse_owner'] as Map<String, dynamic>?;
    final warehouseOwnerId =
        warehouseOwner?['id'] ?? json['warehouse_owner_id'];

    return Job(
      id: safeString(json['id'], ''),
      warehouseOwnerId: safeString(warehouseOwnerId, ''),
      title: safeString(json['title'], 'Untitled Job'),
      description: safeString(json['description'], 'No description available'),
      goodsType: safeString(json['goods_type'], 'General'),
      pickupLocation: safeString(json['pickup_location'], 'Not specified'),
      destination: safeString(json['destination'], 'Not specified'),
      weight: safeDouble(json['weight'], 0.0),
      price: safeDouble(json['price'], 0.0),
      distance: safeDouble(json['distance'], 0.0),
      postedDate: safeDateTime(json['posted_date'], now),
      status: safeString(json['status'], 'open'),
      assignedDriverId: json['assigned_driver_id'],
      assignedDriverName: json['assigned_driver_name'],
      assignedDate: json['assigned_date'] != null
          ? safeDateTime(json['assigned_date'], now)
          : null,
      completionDate: json['completion_date'] != null
          ? safeDateTime(json['completion_date'], now)
          : null,
      createdAt: safeDateTime(json['created_at'], now),
      updatedAt: safeDateTime(json['updated_at'], now),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'warehouse_owner_id': warehouseOwnerId,
      'title': title,
      'description': description,
      'goods_type': goodsType,
      'pickup_location': pickupLocation,
      'destination': destination,
      'weight': weight,
      'price': price,
      'distance': distance,
      'posted_date': postedDate.toIso8601String(),
      'status': status,
      'assigned_driver_id': assignedDriverId,
      'assigned_driver_name': assignedDriverName,
      'assigned_date': assignedDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
      'status':
          'open', // This will be automatically cast to job_status_new by Postgres
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  // Placeholder data
  static List<Job> getPlaceholderJobs() {
    return [
      Job(
        id: '1',
        warehouseOwnerId: 'Warehouse A',
        title: 'Furniture Delivery',
        description: 'Deliver furniture from warehouse to residential address',
        goodsType: 'Furniture',
        pickupLocation: 'Warehouse A, Industrial Area',
        destination: '123 Main Street, City Center',
        weight: 150.0,
        price: 2500.0,
        distance: 8.5,
        postedDate: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'open',
        assignedDriverId: null,
        assignedDriverName: null,
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Job(
        id: '2',
        warehouseOwnerId: 'Electronics Hub',
        title: 'Electronics Transport',
        description: 'Transport electronic goods to retail store',
        goodsType: 'Electronics',
        pickupLocation: 'Electronics Hub, Tech Park',
        destination: '456 Market Street, Shopping District',
        weight: 75.0,
        price: 1800.0,
        distance: 5.2,
        postedDate: DateTime.now().subtract(const Duration(hours: 4)),
        status: 'open',
        assignedDriverId: null,
        assignedDriverName: null,
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Job(
        id: '3',
        warehouseOwnerId: 'Food Processing Unit',
        title: 'Food Items Delivery',
        description: 'Deliver food items to restaurant chain',
        goodsType: 'Food Items',
        pickupLocation: 'Food Processing Unit, Industrial Zone',
        destination: '789 Restaurant Street, Food Court',
        weight: 200.0,
        price: 3000.0,
        distance: 12.0,
        postedDate: DateTime.now().subtract(const Duration(hours: 1)),
        status: 'open',
        assignedDriverId: null,
        assignedDriverName: null,
        assignedDate: null,
        completionDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  Job copyWith({
    String? id,
    String? warehouseOwnerId,
    String? title,
    String? description,
    String? goodsType,
    String? pickupLocation,
    String? destination,
    double? weight,
    double? price,
    double? distance,
    DateTime? postedDate,
    String? status,
    String? assignedDriverId,
    String? assignedDriverName,
    DateTime? assignedDate,
    DateTime? completionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      warehouseOwnerId: warehouseOwnerId ?? this.warehouseOwnerId,
      title: title ?? this.title,
      description: description ?? this.description,
      goodsType: goodsType ?? this.goodsType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      weight: weight ?? this.weight,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      postedDate: postedDate ?? this.postedDate,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedDate: assignedDate ?? this.assignedDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }
}
