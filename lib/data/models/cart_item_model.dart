import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class CartItemModel extends BaseModel {
  final String menuItemId;
  final String userId;
  final int quantity;
  final DenormalizedMenuItemModel?
  menuItem; // ! Denormalization bukan populated

  CartItemModel({
    required String id,
    required this.userId,
    required this.menuItemId,
    required this.quantity,
    this.menuItem,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  CartItemModel copyWith({
    String? id,
    String? userId,
    String? menuItemId,
    int? quantity,
    DenormalizedMenuItemModel? menuItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      'userId': userId,
      'menuItemId': menuItemId,
      'quantity': quantity,
      'menuItem': menuItem?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      menuItemId: map['menuItemId'] as String,
      quantity: map['quantity'] as int,
      menuItem:
          map['menuItem'] != null
              ? DenormalizedMenuItemModel.fromMap(
                map['menuItem'] as Map<String, dynamic>,
              )
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory CartItemModel.fromJson(String source) =>
      CartItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CartItemModel(id: $id, userId: $userId,  menuItemId: $menuItemId, quantity: $quantity, menuItem: $menuItem, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant CartItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        other.menuItemId == menuItemId &&
        other.quantity == quantity &&
        other.menuItem == menuItem &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        menuItemId.hashCode ^
        quantity.hashCode ^
        menuItem.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreateCartItemDto {
  final String menuItemId;
  final int quantity;
  final DenormalizedMenuItemModel menuItem;

  CreateCartItemDto({
    required this.menuItemId,
    required this.quantity,
    required this.menuItem,
  });

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'quantity': quantity,
      'menuItem': menuItem.toMap(),
    };
  }
}

class UpdateCartItemDto {
  final int? quantity;

  UpdateCartItemDto({this.quantity});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (quantity != null) {
      map['quantity'] = quantity;
    }

    return map;
  }
}
