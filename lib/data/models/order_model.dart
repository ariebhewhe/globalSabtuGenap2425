import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/order_item_model.dart';
import 'package:jamal/data/models/table_reservation_model.dart';

class OrderModel extends BaseModel {
  final String userId;
  final String? paymentMethodId;
  final OrderType orderType;
  final OrderStatus status;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final DateTime orderDate;
  final DateTime? estimatedReadyTime;
  final String? specialInstructions;
  final List<OrderItemModel>? orderItems;

  OrderModel({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.userId,
    this.paymentMethodId,
    required this.orderType,
    this.status = OrderStatus.pending,
    required this.totalAmount,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.orderDate,
    this.estimatedReadyTime,
    this.specialInstructions,
    this.orderItems,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  OrderModel copyWith({
    String? id,
    String? userId,
    String? paymentMethodId,
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
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
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
      'userId': userId,
      'paymentMethodId': paymentMethodId,
      'orderType': orderType.toMap(),
      'status': status.toMap(),
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus.toMap(),
      'orderDate': orderDate.millisecondsSinceEpoch,
      'estimatedReadyTime': estimatedReadyTime?.millisecondsSinceEpoch,
      'specialInstructions': specialInstructions,
      'orderItems': orderItems?.map((x) => x.toMap()).toList(),
    };
  }

  @override
  @override
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      paymentMethodId:
          map['paymentMethodId'] != null
              ? map['paymentMethodId'] as String
              : null,
      orderType: OrderTypeExtension.fromMap(map['orderType'] as String),
      status: OrderStatusExtension.fromMap(map['status'] as String),
      totalAmount: map['totalAmount'] as double,
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
                (map['orderItems'] as List<dynamic>).map<OrderItemModel>(
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
    return 'OrderModel(userId: $userId, paymentMethodId: $paymentMethodId, orderType: $orderType, status: $status, totalAmount: $totalAmount, paymentStatus: $paymentStatus, orderDate: $orderDate, estimatedReadyTime: $estimatedReadyTime, specialInstructions: $specialInstructions, orderItems: $orderItems)';
  }

  @override
  bool operator ==(covariant OrderModel other) {
    if (identical(this, other)) return true;

    return other.userId == userId &&
        other.paymentMethodId == paymentMethodId &&
        other.orderType == orderType &&
        other.status == status &&
        other.totalAmount == totalAmount &&
        other.paymentStatus == paymentStatus &&
        other.orderDate == orderDate &&
        other.estimatedReadyTime == estimatedReadyTime &&
        other.specialInstructions == specialInstructions &&
        listEquals(other.orderItems, orderItems);
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        paymentMethodId.hashCode ^
        orderType.hashCode ^
        status.hashCode ^
        totalAmount.hashCode ^
        paymentStatus.hashCode ^
        orderDate.hashCode ^
        estimatedReadyTime.hashCode ^
        specialInstructions.hashCode ^
        orderItems.hashCode;
  }
}

class CreateOrderDto {
  final String paymentMethodId;
  final OrderType orderType;
  final DateTime? estimatedReadyTime;
  final String? specialInstructions;
  final CreateTableReservationDto? tableReservation;
  final List<OrderItemModel> orderItems;

  CreateOrderDto({
    required this.paymentMethodId,
    required this.orderType,
    this.estimatedReadyTime,
    this.specialInstructions,
    this.tableReservation,
    required this.orderItems,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'paymentMethodId': paymentMethodId,
      'orderType': orderType.toMap(),
      'estimatedReadyTime': estimatedReadyTime?.millisecondsSinceEpoch,
      'specialInstructions': specialInstructions,
      'tableReservation': tableReservation?.toMap(),
      'orderItems': orderItems.map((x) => x.toMap()).toList(),
    };
  }
}

class UpdateOrderDto {
  final OrderType? orderType;
  final OrderStatus? status;
  final PaymentStatus? paymentStatus;
  final DateTime? estimatedReadyTime;

  UpdateOrderDto({
    this.orderType,
    this.status,
    this.paymentStatus,
    this.estimatedReadyTime,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

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
