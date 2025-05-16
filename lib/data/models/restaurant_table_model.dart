import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';

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
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
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
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
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
