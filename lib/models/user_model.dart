class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role; // 'driver' or 'garage'
  final DateTime createdAt;
  final bool isActive;
  
  // Driver specific fields
  final String? carModel;
  final String? carPlate;
  
  // Garage specific fields
  final String? garageName;
  final String? ownerName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<String>? services;
  final double? rating;
  final int? totalReviews;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.carModel,
    this.carPlate,
    this.garageName,
    this.ownerName,
    this.latitude,
    this.longitude,
    this.address,
    this.services,
    this.rating,
    this.totalReviews,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isActive: map['isActive'] ?? true,
      carModel: map['carModel'],
      carPlate: map['carPlate'],
      garageName: map['garageName'],
      ownerName: map['ownerName'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      services: map['services'] != null ? List<String>.from(map['services']) : null,
      rating: map['rating']?.toDouble(),
      totalReviews: map['totalReviews'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isActive': isActive,
      'carModel': carModel,
      'carPlate': carPlate,
      'garageName': garageName,
      'ownerName': ownerName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'services': services,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    DateTime? createdAt,
    bool? isActive,
    String? carModel,
    String? carPlate,
    String? garageName,
    String? ownerName,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? services,
    double? rating,
    int? totalReviews,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      carModel: carModel ?? this.carModel,
      carPlate: carPlate ?? this.carPlate,
      garageName: garageName ?? this.garageName,
      ownerName: ownerName ?? this.ownerName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      services: services ?? this.services,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}