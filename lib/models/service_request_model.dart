class ServiceRequestModel {
  final String id;
  final String driverId;
  final String garageId;
  final String driverName;
  final String driverPhone;
  final String carModel;
  final String carPlate;
  final double driverLatitude;
  final double driverLongitude;
  final String driverAddress;
  final String status; // 'pending', 'accepted', 'on_way', 'arrived', 'in_progress', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final List<String> servicesRequested;
  final List<ServicePerformed> servicesPerformed;
  final double totalAmount;
  final bool isPaid;
  final String? paymentId;
  final String? notes;
  final double? consultationFee;
  final double? transportFee;

  ServiceRequestModel({
    required this.id,
    required this.driverId,
    required this.garageId,
    required this.driverName,
    required this.driverPhone,
    required this.carModel,
    required this.carPlate,
    required this.driverLatitude,
    required this.driverLongitude,
    required this.driverAddress,
    this.status = 'pending',
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.completedAt,
    this.servicesRequested = const [],
    this.servicesPerformed = const [],
    this.totalAmount = 0.0,
    this.isPaid = false,
    this.paymentId,
    this.notes,
    this.consultationFee,
    this.transportFee,
  });

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map) {
    return ServiceRequestModel(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      garageId: map['garageId'] ?? '',
      driverName: map['driverName'] ?? '',
      driverPhone: map['driverPhone'] ?? '',
      carModel: map['carModel'] ?? '',
      carPlate: map['carPlate'] ?? '',
      driverLatitude: map['driverLatitude']?.toDouble() ?? 0.0,
      driverLongitude: map['driverLongitude']?.toDouble() ?? 0.0,
      driverAddress: map['driverAddress'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      acceptedAt: map['acceptedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['acceptedAt']) 
          : null,
      arrivedAt: map['arrivedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['arrivedAt']) 
          : null,
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) 
          : null,
      servicesRequested: map['servicesRequested'] != null 
          ? List<String>.from(map['servicesRequested']) 
          : [],
      servicesPerformed: map['servicesPerformed'] != null 
          ? (map['servicesPerformed'] as List)
              .map((e) => ServicePerformed.fromMap(e))
              .toList()
          : [],
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      isPaid: map['isPaid'] ?? false,
      paymentId: map['paymentId'],
      notes: map['notes'],
      consultationFee: map['consultationFee']?.toDouble(),
      transportFee: map['transportFee']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'garageId': garageId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'carModel': carModel,
      'carPlate': carPlate,
      'driverLatitude': driverLatitude,
      'driverLongitude': driverLongitude,
      'driverAddress': driverAddress,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'acceptedAt': acceptedAt?.millisecondsSinceEpoch,
      'arrivedAt': arrivedAt?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'servicesRequested': servicesRequested,
      'servicesPerformed': servicesPerformed.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'isPaid': isPaid,
      'paymentId': paymentId,
      'notes': notes,
      'consultationFee': consultationFee,
      'transportFee': transportFee,
    };
  }
}

class ServicePerformed {
  final String serviceId;
  final String serviceName;
  final double price;
  final String description;
  final DateTime performedAt;

  ServicePerformed({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.description,
    required this.performedAt,
  });

  factory ServicePerformed.fromMap(Map<String, dynamic> map) {
    return ServicePerformed(
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      performedAt: DateTime.fromMillisecondsSinceEpoch(map['performedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'description': description,
      'performedAt': performedAt.millisecondsSinceEpoch,
    };
  }
}