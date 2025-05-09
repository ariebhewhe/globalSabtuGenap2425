import 'dart:convert';

import 'package:jamal/data/models/menu_item_model.dart';

class OrderItemModel {
  final String id;
  final int orderId;
  final int itemId;
  final int quantity;
  final double itemPrice;
  final double subtotal;
  final String? specialRequests;
  final MenuItemModel? menuItem; // * Populated kalo perlu
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.quantity,
    required this.itemPrice,
    required this.subtotal,
    this.specialRequests,
    this.menuItem,
    required this.createdAt,
    required this.updatedAt,
  });

  OrderItemModel copyWith({
    String? id,
    int? orderId,
    int? itemId,
    int? quantity,
    double? itemPrice,
    double? subtotal,
    String? specialRequests,
    MenuItemModel? menuItem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      itemPrice: itemPrice ?? this.itemPrice,
      subtotal: subtotal ?? this.subtotal,
      specialRequests: specialRequests ?? this.specialRequests,
      menuItem: menuItem ?? this.menuItem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'orderId': orderId,
      'itemId': itemId,
      'quantity': quantity,
      'itemPrice': itemPrice,
      'subtotal': subtotal,
      'specialRequests': specialRequests,
      'menuItem': menuItem?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String,
      orderId: map['orderId'] as int,
      itemId: map['itemId'] as int,
      quantity: map['quantity'] as int,
      itemPrice: map['itemPrice'] as double,
      subtotal: map['subtotal'] as double,
      specialRequests:
          map['specialRequests'] != null
              ? map['specialRequests'] as String
              : null,
      menuItem:
          map['menuItem'] != null
              ? MenuItemModel.fromMap(map['menuItem'] as Map<String, dynamic>)
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory OrderItemModel.fromJson(String source) =>
      OrderItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrderItemModel(id: $id, orderId: $orderId, itemId: $itemId, quantity: $quantity, itemPrice: $itemPrice, subtotal: $subtotal, specialRequests: $specialRequests, menuItem: $menuItem, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant OrderItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.orderId == orderId &&
        other.itemId == itemId &&
        other.quantity == quantity &&
        other.itemPrice == itemPrice &&
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
        itemId.hashCode ^
        quantity.hashCode ^
        itemPrice.hashCode ^
        subtotal.hashCode ^
        specialRequests.hashCode ^
        menuItem.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
