import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/model_utils.dart';
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
  final String? paymentProof;
  final String? paymentCode;
  final String? paymentDisplayUrl;
  final DateTime? paymentExpiry;
  // final PaymentMethodModel? paymentMethod;

  OrderModel({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.userId,
    this.paymentMethodId,
    required this.orderType,
    this.status = OrderStatus.pending,
    required this.totalAmount,
    this.paymentStatus = PaymentStatus.pending,
    required this.orderDate,
    this.estimatedReadyTime,
    this.specialInstructions,
    this.orderItems,
    this.paymentProof,
    this.paymentCode,
    this.paymentDisplayUrl,
    this.paymentExpiry,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory OrderModel.dummy() {
    final now = DateTime.now();
    return OrderModel(
      id: 'order-123',
      userId: 'user-001',
      paymentMethodId: 'pm-qris-123',
      orderType: OrderType.dineIn,
      status: OrderStatus.confirmed,
      totalAmount: 150000,
      paymentStatus: PaymentStatus.deny,
      orderDate: now,
      estimatedReadyTime: now.add(const Duration(minutes: 20)),
      specialInstructions: 'Tolong jangan pakai bawang, alergi.',
      orderItems: [
        // OrderItemModel.dummy(),
        // OrderItemModel.dummy().copyWith(id: 'item-457', quantity: 2),
      ],
      paymentProof: 'https://example.com/proof.jpg',
      paymentCode: 'QRIS123456ABC',
      paymentDisplayUrl: 'https://qris.example.com/display/12345',
      paymentExpiry: now.add(const Duration(hours: 1)),
      createdAt: now.subtract(const Duration(minutes: 5)),
      updatedAt: now,
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? paymentMethodId,
    OrderType? orderType,
    OrderStatus? status,
    double? totalAmount,
    PaymentStatus? paymentStatus,
    DateTime? orderDate,
    DateTime? estimatedReadyTime,
    String? specialInstructions,
    List<OrderItemModel>? orderItems,
    String? paymentProof,
    String? paymentCode,
    String? paymentDisplayUrl,
    DateTime? paymentExpiry,
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
      paymentProof: paymentProof ?? this.paymentProof,
      paymentCode: paymentCode ?? this.paymentCode,
      paymentDisplayUrl: paymentDisplayUrl ?? this.paymentDisplayUrl,
      paymentExpiry: paymentExpiry ?? this.paymentExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'userId': userId,
      'paymentMethodId': paymentMethodId,
      'orderType': orderType.toMap(),
      'status': status.toMap(),
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus.toMap(),
      'orderDate': orderDate.toUtc().toIso8601String(),
      'estimatedReadyTime': estimatedReadyTime?.toUtc().toIso8601String(),
      'specialInstructions': specialInstructions,
      'orderItems': orderItems?.map((x) => x.toMap()).toList(),
      'paymentProof': paymentProof,
      'paymentCode': paymentCode,
      'paymentDisplayUrl': paymentDisplayUrl,
      'paymentExpiry': paymentExpiry?.toUtc().toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    // Untuk bersihnya, kita bisa tampung value dari map ke variabel
    final dynamic estimatedReadyTimeValue = map['estimatedReadyTime'];
    final dynamic paymentExpiryValue = map['paymentExpiry'];
    final dynamic createdAtValue = map['createdAt'];
    final dynamic updatedAtValue = map['updatedAt'];

    return OrderModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      paymentMethodId:
          map['paymentMethodId'] != null
              ? map['paymentMethodId'] as String
              : null,
      orderType: OrderTypeExtension.fromMap(map['orderType'] as String),
      status: OrderStatusExtension.fromMap(map['status'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paymentStatus: PaymentStatusExtension.fromMap(
        map['paymentStatus'] as String,
      ),
      orderDate: ModelUtils.parseDateTime(
        map['orderDate'],
      ), // Anggap orderDate tidak pernah null

      estimatedReadyTime:
          estimatedReadyTimeValue != null &&
                  estimatedReadyTimeValue.toString().isNotEmpty &&
                  estimatedReadyTimeValue != 'null'
              ? ModelUtils.parseDateTime(estimatedReadyTimeValue)
              : null,

      specialInstructions: map['specialInstructions'] as String?,

      orderItems:
          map['orderItems'] != null
              ? List<OrderItemModel>.from(
                (map['orderItems'] as List<dynamic>).map<OrderItemModel>(
                  (x) => OrderItemModel.fromMap(x as Map<String, dynamic>),
                ),
              )
              : null,

      paymentProof: map['paymentProof'] as String?,
      paymentCode: map['paymentCode'] as String?,
      paymentDisplayUrl: map['paymentDisplayUrl'] as String?,

      // --- PERBAIKAN DI SINI ---
      paymentExpiry:
          paymentExpiryValue != null &&
                  paymentExpiryValue.toString().isNotEmpty &&
                  paymentExpiryValue != 'null'
              ? ModelUtils.parseDateTime(paymentExpiryValue)
              : null,

      createdAt:
          createdAtValue != null &&
                  createdAtValue.toString().isNotEmpty &&
                  createdAtValue != 'null'
              ? ModelUtils.parseDateTime(createdAtValue)
              : DateTime.now(),
      updatedAt:
          updatedAtValue != null &&
                  updatedAtValue.toString().isNotEmpty &&
                  updatedAtValue != 'null'
              ? ModelUtils.parseDateTime(updatedAtValue)
              : DateTime.now(),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory OrderModel.fromJson(String source) =>
      OrderModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrderModel(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, userId: $userId, paymentMethodId: $paymentMethodId, orderType: $orderType, status: $status, totalAmount: $totalAmount, paymentStatus: $paymentStatus, orderDate: $orderDate, estimatedReadyTime: $estimatedReadyTime, specialInstructions: $specialInstructions, orderItems: $orderItems, paymentProof: $paymentProof, paymentCode: $paymentCode, paymentDisplayUrl: $paymentDisplayUrl, paymentExpiry: $paymentExpiry)';
  }

  @override
  bool operator ==(covariant OrderModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.userId == userId &&
        other.paymentMethodId == paymentMethodId &&
        other.orderType == orderType &&
        other.status == status &&
        other.totalAmount == totalAmount &&
        other.paymentStatus == paymentStatus &&
        other.orderDate == orderDate &&
        other.estimatedReadyTime == estimatedReadyTime &&
        other.specialInstructions == specialInstructions &&
        listEquals(other.orderItems, orderItems) &&
        other.paymentProof == paymentProof &&
        other.paymentCode == paymentCode &&
        other.paymentDisplayUrl == paymentDisplayUrl &&
        other.paymentExpiry == paymentExpiry;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        userId.hashCode ^
        paymentMethodId.hashCode ^
        orderType.hashCode ^
        status.hashCode ^
        totalAmount.hashCode ^
        paymentStatus.hashCode ^
        orderDate.hashCode ^
        estimatedReadyTime.hashCode ^
        specialInstructions.hashCode ^
        orderItems.hashCode ^
        paymentProof.hashCode ^
        paymentCode.hashCode ^
        paymentDisplayUrl.hashCode ^
        paymentExpiry.hashCode;
  }
}

class CreateOrderDto {
  final String? userId;
  final String paymentMethodId;
  final OrderType orderType;
  final DateTime? estimatedReadyTime;
  final String? specialInstructions;
  final CreateTableReservationDto? tableReservation;
  final List<OrderItemModel> orderItems;
  final File? transferProofFile;

  CreateOrderDto({
    this.userId,
    required this.paymentMethodId,
    required this.orderType,
    this.estimatedReadyTime,
    this.specialInstructions,
    this.tableReservation,
    required this.orderItems,
    this.transferProofFile,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'paymentMethodId': paymentMethodId,
      'orderType': orderType.toMap(),
      'estimatedReadyTime': estimatedReadyTime?.toUtc().toIso8601String(),
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
  final String? paymentCode;
  final String? paymentDisplayUrl;
  final DateTime? paymentExpiry;

  UpdateOrderDto({
    this.orderType,
    this.status,
    this.paymentStatus,
    this.estimatedReadyTime,
    this.paymentCode,
    this.paymentDisplayUrl,
    this.paymentExpiry,
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
      map['estimatedReadyTime'] = estimatedReadyTime!.toUtc().toIso8601String();
    }
    if (paymentCode != null) {
      map['paymentCode'] = paymentCode;
    }
    if (paymentDisplayUrl != null) {
      map['paymentDisplayUrl'] = paymentDisplayUrl;
    }
    if (paymentExpiry != null) {
      map['paymentExpiry'] = paymentExpiry!.toUtc().toIso8601String();
    }

    return map;
  }
}
