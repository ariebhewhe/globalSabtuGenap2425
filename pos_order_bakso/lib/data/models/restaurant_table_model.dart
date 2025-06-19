import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/model_utils.dart';

class RestaurantTableModel extends BaseModel {
  final String tableNumber;
  final int capacity;
  final bool isAvailable;
  final Location location;

  RestaurantTableModel({
    required String id,
    required this.tableNumber,
    required this.capacity,
    required this.isAvailable,
    required this.location,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory RestaurantTableModel.dummy() {
    final now = DateTime.now();

    return RestaurantTableModel(
      id: 'id',
      tableNumber: 'tableNumber',
      capacity: 1,
      isAvailable: false,
      location: Location.indoor,
      createdAt: now.subtract(const Duration(minutes: 5)),
      updatedAt: now,
    );
  }

  RestaurantTableModel copyWith({
    String? id,
    String? tableNumber,
    int? capacity,
    bool? isAvailable,
    Location? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantTableModel(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      isAvailable: isAvailable ?? this.isAvailable,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'isAvailable': isAvailable,
      'location': location.toMap(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  factory RestaurantTableModel.fromMap(Map<String, dynamic> map) {
    return RestaurantTableModel(
      id: map['id'] as String,
      tableNumber: map['tableNumber'] as String,
      capacity: map['capacity'] as int,
      isAvailable: map['isAvailable'] as bool,
      location: LocationExtension.fromMap(map['location'] as String),
      createdAt: ModelUtils.parseDateTime(map['createdAt']),
      updatedAt: ModelUtils.parseDateTime(map['updatedAt']),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory RestaurantTableModel.fromJson(String source) =>
      RestaurantTableModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'RestaurantTableModel(id: $id, tableNumber: $tableNumber, capacity: $capacity, isAvailable: $isAvailable, location: $location, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant RestaurantTableModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.tableNumber == tableNumber &&
        other.capacity == capacity &&
        other.isAvailable == isAvailable &&
        other.location == location &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tableNumber.hashCode ^
        capacity.hashCode ^
        isAvailable.hashCode ^
        location.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreateRestaurantTableDto {
  final String tableNumber;
  final int capacity;
  final bool isAvailable;
  final Location location;

  CreateRestaurantTableDto({
    required this.tableNumber,
    required this.capacity,
    required this.isAvailable,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      "tableNumber": tableNumber,
      "capacity": capacity,
      "isAvailable": isAvailable,
      "location": location.toMap(),
    };
  }
}

class UpdateRestaurantTableDto {
  final String? tableNumber;
  final int? capacity;
  final bool? isAvailable;
  final Location? location;

  UpdateRestaurantTableDto({
    this.tableNumber,
    this.capacity,
    this.isAvailable,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      "tableNumber": tableNumber,
      "capacity": capacity,
      "isAvailable": isAvailable,
      "location": location?.toMap(),
    };
  }
}
