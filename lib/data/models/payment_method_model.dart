import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';

class PaymentMethodModel extends BaseModel {
  final String name;
  final String? description;
  final String? logo;
  final PaymentMethodType paymentMethodType;
  final double minimumAmount;
  final double maximumAmount;

  PaymentMethodModel({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.name,
    required this.description,
    this.logo,
    required this.paymentMethodType,
    required this.minimumAmount,
    required this.maximumAmount,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logo,
    PaymentMethodType? paymentMethodType,
    double? minimumAmount,
    double? maximumAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumAmount: maximumAmount ?? this.maximumAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'logo': logo,
      'paymentMethodType': paymentMethodType.toMap(),
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description:
          map['description'] != null ? map['description'] as String : null,
      logo: map['logo'] != null ? map['logo'] as String : null,
      paymentMethodType: PaymentMethodTypeExtension.fromMap(
        map['paymentMethodType'] as String,
      ),
      minimumAmount: map['minimumAmount'] as double,
      maximumAmount: map['maximumAmount'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory PaymentMethodModel.fromJson(String source) =>
      PaymentMethodModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PaymentMethodModel(id: $id, name: $name, description: $description, logo: $logo, paymentMethodType: $paymentMethodType, minimumAmount: $minimumAmount, maximumAmount: $maximumAmount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant PaymentMethodModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.description == description &&
        other.logo == logo &&
        other.paymentMethodType == paymentMethodType &&
        other.minimumAmount == minimumAmount &&
        other.maximumAmount == maximumAmount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        logo.hashCode ^
        paymentMethodType.hashCode ^
        minimumAmount.hashCode ^
        maximumAmount.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
