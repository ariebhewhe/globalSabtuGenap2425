import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class CartModel extends BaseModel {
  final int menuItemId;
  final int quantity;
  final MenuItemModel? menuItem; // * Populated kalo perlu

  CartModel({
    required String id,
    required this.menuItemId,
    required this.quantity,
    this.menuItem,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  CartModel copyWith({
    String? id,
    int? menuItemId,
    int? quantity,
    MenuItemModel? menuItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      quantity: quantity ?? this.quantity,
      menuItem: menuItem ?? this.menuItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'menuItemId': menuItemId,
      'quantity': quantity,
      'menuItem': menuItem?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: map['id'] as String,
      menuItemId: map['menuItemId'] as int,
      quantity: map['quantity'] as int,
      menuItem:
          map['menuItem'] != null
              ? MenuItemModel.fromMap(map['menuItem'] as Map<String, dynamic>)
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory CartModel.fromJson(String source) =>
      CartModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CartModel(id: $id, menuItemId: $menuItemId, quantity: $quantity, menuItem: $menuItem, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant CartModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.menuItemId == menuItemId &&
        other.quantity == quantity &&
        other.menuItem == menuItem &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        menuItemId.hashCode ^
        quantity.hashCode ^
        menuItem.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
