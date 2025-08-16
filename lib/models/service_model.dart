class ServiceModel {
  final String id;
  final String garageId;
  final String name;
  final String description;
  final double price;
  final int estimatedTimeMinutes;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.garageId,
    required this.name,
    required this.description,
    required this.price,
    required this.estimatedTimeMinutes,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      garageId: map['garageId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      estimatedTimeMinutes: map['estimatedTimeMinutes'] ?? 0,
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'garageId': garageId,
      'name': name,
      'description': description,
      'price': price,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? garageId,
    String? name,
    String? description,
    double? price,
    int? estimatedTimeMinutes,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      garageId: garageId ?? this.garageId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}