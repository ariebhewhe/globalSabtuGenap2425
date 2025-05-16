import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';

class PaymentTransactionModel extends BaseModel {
  final int orderId;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime transactionDate;
  final TransactionStatus status;
  final String? paymentDetails;

  PaymentTransactionModel({
    required String id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionDate,
    required this.status,
    this.paymentDetails,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  PaymentTransactionModel copyWith({
    String? id,
    int? orderId,
    double? amount,
    PaymentMethod? paymentMethod,
    DateTime? transactionDate,
    TransactionStatus? status,
    String? paymentDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentTransactionModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      status: status ?? this.status,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'paymentMethod': paymentMethod.toMap(),
      'transactionDate': transactionDate.millisecondsSinceEpoch,
      'status': status.toMap(),
      'paymentDetails': paymentDetails,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory PaymentTransactionModel.fromMap(Map<String, dynamic> map) {
    return PaymentTransactionModel(
      id: map['id'] as String,
      orderId: map['orderId'] as int,
      amount: map['amount'] as double,
      paymentMethod: PaymentMethodExtension.fromMap(
        map['paymentMethod'] as String,
      ),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transactionDate'] as int,
      ),
      status: TransactionStatusExtension.fromMap(map['status'] as String),
      paymentDetails:
          map['paymentDetails'] != null
              ? map['paymentDetails'] as String
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory PaymentTransactionModel.fromJson(String source) =>
      PaymentTransactionModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'PaymentTransactionModel(id: $id, orderId: $orderId, amount: $amount, paymentMethod: $paymentMethod, transactionDate: $transactionDate, status: $status, paymentDetails: $paymentDetails, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant PaymentTransactionModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.orderId == orderId &&
        other.amount == amount &&
        other.paymentMethod == paymentMethod &&
        other.transactionDate == transactionDate &&
        other.status == status &&
        other.paymentDetails == paymentDetails &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        orderId.hashCode ^
        amount.hashCode ^
        paymentMethod.hashCode ^
        transactionDate.hashCode ^
        status.hashCode ^
        paymentDetails.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
