import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class OrderItemModel extends BaseModel {
  final String orderId;
  final String menuItemId;
  final int quantity;
  final double price;
  final double subtotal;
  final String? specialRequests;
  final DenormalizedMenuItemModel? menuItem;

  OrderItemModel({
    required String id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.specialRequests,
    this.menuItem,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? menuItemId,
    int? quantity,
    double? price,
    double? subtotal,
    String? specialRequests,
    DenormalizedMenuItemModel? menuItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      specialRequests: specialRequests ?? this.specialRequests,
      menuItem: menuItem ?? this.menuItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'specialRequests': specialRequests,
      'menuItem': menuItem?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      menuItemId: map['menuItemId'] as String,
      quantity: map['quantity'] as int,
      price: map['price'] as double,
      subtotal: map['subtotal'] as double,
      specialRequests:
          map['specialRequests'] != null
              ? map['specialRequests'] as String
              : null,
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
  factory OrderItemModel.fromJson(String source) =>
      OrderItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrderItemModel(id: $id, orderId: $orderId, menuItemId: $menuItemId, quantity: $quantity, price: $price, subtotal: $subtotal, specialRequests: $specialRequests, menuItem: $menuItem, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant OrderItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.orderId == orderId &&
        other.menuItemId == menuItemId &&
        other.quantity == quantity &&
        other.price == price &&
        other.subtotal == subtotal &&
        other.specialRequests == specialRequests &&
        other.menuItem == menuItem &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        menuItemId.hashCode ^
        quantity.hashCode ^
        price.hashCode ^
        subtotal.hashCode ^
        specialRequests.hashCode ^
        menuItem.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
