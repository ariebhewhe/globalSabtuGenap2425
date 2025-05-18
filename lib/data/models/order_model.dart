import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/order_item_model.dart';

class OrderModel extends BaseModel {
  final int userId;
  final int? tableId;
  final OrderType orderType;
  final OrderStatus status;
  final double totalAmount;
  final PaymentMethodType paymentMethodType;
  final PaymentStatus paymentStatus;
  final DateTime orderDate;
  final DateTime? estimatedReadyTime;
  final String? specialInstructions;
  final List<OrderItemModel>? orderItems;

  OrderModel({
    required String id,
    required this.userId,
    this.tableId,
    required this.orderType,
    this.status = OrderStatus.pending,
    required this.totalAmount,
    required this.paymentMethodType,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.orderDate,
    this.estimatedReadyTime,
    this.specialInstructions,
    this.orderItems,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  OrderModel copyWith({
    String? id,
    int? userId,
    int? tableId,
    OrderType? orderType,
    OrderStatus? status,
    double? totalAmount,
    PaymentMethodType? paymentMethodType,
    PaymentStatus? paymentStatus,
    DateTime? orderDate,
    DateTime? estimatedReadyTime,
    String? specialInstructions,
    List<OrderItemModel>? orderItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableId: tableId ?? this.tableId,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderDate: orderDate ?? this.orderDate,
      estimatedReadyTime: estimatedReadyTime ?? this.estimatedReadyTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      orderItems: orderItems ?? this.orderItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'tableId': tableId,
      'orderType': orderType.toMap(),
      'status': status.toMap(),
      'totalAmount': totalAmount,
      'paymentMethodType': paymentMethodType.toMap(),
      'paymentStatus': paymentStatus.toMap(),
      'orderDate': orderDate.millisecondsSinceEpoch,
      'estimatedReadyTime': estimatedReadyTime?.millisecondsSinceEpoch,
      'specialInstructions': specialInstructions,
      'orderItems': orderItems?.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as int,
      tableId: map['tableId'] != null ? map['tableId'] as int : null,
      orderType: OrderTypeExtension.fromMap(map['orderType'] as String),
      status: OrderStatusExtension.fromMap(map['status'] as String),
      totalAmount: map['totalAmount'] as double,
      paymentMethodType: PaymentMethodTypeExtension.fromMap(
        map['paymentMethodType'] as String,
      ),
      paymentStatus: PaymentStatusExtension.fromMap(
        map['paymentStatus'] as String,
      ),
      orderDate: DateTime.fromMillisecondsSinceEpoch(map['orderDate'] as int),
      estimatedReadyTime:
          map['estimatedReadyTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                map['estimatedReadyTime'] as int,
              )
              : null,
      specialInstructions:
          map['specialInstructions'] != null
              ? map['specialInstructions'] as String
              : null,
      orderItems:
          map['orderItems'] != null
              ? List<OrderItemModel>.from(
                (map['orderItems'] as List<int>).map<OrderItemModel?>(
                  (x) => OrderItemModel.fromMap(x as Map<String, dynamic>),
                ),
              )
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory OrderModel.fromJson(String source) =>
      OrderModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrderModel(id: $id, userId: $userId, tableId: $tableId, orderType: $orderType, status: $status, totalAmount: $totalAmount, paymentMethodType: $paymentMethodType, paymentStatus: $paymentStatus, orderDate: $orderDate, estimatedReadyTime: $estimatedReadyTime, specialInstructions: $specialInstructions, orderItems: $orderItems, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant OrderModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        other.tableId == tableId &&
        other.orderType == orderType &&
        other.status == status &&
        other.totalAmount == totalAmount &&
        other.paymentMethodType == paymentMethodType &&
        other.paymentStatus == paymentStatus &&
        other.orderDate == orderDate &&
        other.estimatedReadyTime == estimatedReadyTime &&
        other.specialInstructions == specialInstructions &&
        listEquals(other.orderItems, orderItems) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        tableId.hashCode ^
        orderType.hashCode ^
        status.hashCode ^
        totalAmount.hashCode ^
        paymentMethodType.hashCode ^
        paymentStatus.hashCode ^
        orderDate.hashCode ^
        estimatedReadyTime.hashCode ^
        specialInstructions.hashCode ^
        orderItems.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreateOrderDto {
  final int? tableId;
  final OrderType orderType;
  final PaymentMethodType paymentMethodType;
  final DateTime? estimatedReadyTime;
  final String? specialInstructions;
  final List<OrderItemModel> orderItems;

  CreateOrderDto({
    required this.tableId,
    required this.orderType,
    required this.paymentMethodType,
    required this.estimatedReadyTime,
    required this.specialInstructions,
    required this.orderItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'orderType': orderType.toMap(),
      'paymentMethodType': paymentMethodType.toMap(),
      'estimatedReadyTime': estimatedReadyTime,
      'specialInstructions': specialInstructions,
      'orderItems': orderItems.map((x) => x.toMap()).toList(),
    };
  }
}

class UpdateOrderDto {
  final int? tableId;
  final OrderType? orderType;
  final OrderStatus? status;
  final PaymentStatus? paymentStatus;
  final DateTime? estimatedReadyTime;

  UpdateOrderDto({
    this.tableId,
    this.orderType,
    this.status,
    this.paymentStatus,
    this.estimatedReadyTime,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (tableId != null) {
      map['tableId'] = tableId;
    }
    if (orderType != null) {
      map['orderType'] = orderType!.toMap();
    }
    if (status != null) {
      map['status'] = status!.toMap();
    }
    if (paymentStatus != null) {
      map['paymentStatus'] = paymentStatus!.toMap();
    }
    if (estimatedReadyTime != null) {
      map['estimatedReadyTime'] = estimatedReadyTime!.millisecondsSinceEpoch;
    }

    return map;
  }
}
