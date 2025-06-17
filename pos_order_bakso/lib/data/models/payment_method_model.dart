import 'dart:convert';
import 'dart:io';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';

class PaymentMethodModel extends BaseModel {
  final String name;
  final String? description;
  final String? logo;
  final PaymentMethodType paymentMethodType;
  final double minimumAmount;
  final double maximumAmount;
  final String? midtransIdentifier; // Properti baru
  final String? adminPaymentCode;
  final String? adminPaymentQrCodePicture;

  PaymentMethodModel({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.name,
    this.description,
    this.logo,
    required this.paymentMethodType,
    required this.minimumAmount,
    required this.maximumAmount,
    this.midtransIdentifier, // Ditambahkan ke constructor
    this.adminPaymentCode,
    this.adminPaymentQrCodePicture,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  factory PaymentMethodModel.dummy() {
    return PaymentMethodModel(
      id: 'dummy_id',
      name: 'Loading Item...',
      description: 'lorem ipsum dolor sit amet consectetur adipiscing elit',
      minimumAmount: 0,
      maximumAmount: 0,
      paymentMethodType: PaymentMethodType.cash,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logo,
    PaymentMethodType? paymentMethodType,
    double? minimumAmount,
    double? maximumAmount,
    String? midtransIdentifier, // Ditambahkan ke copyWith
    String? adminPaymentCode,
    String? adminPaymentQrCodePicture,
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
      midtransIdentifier:
          midtransIdentifier ?? this.midtransIdentifier, // Ditambahkan
      adminPaymentCode: adminPaymentCode ?? this.adminPaymentCode,
      adminPaymentQrCodePicture:
          adminPaymentQrCodePicture ?? this.adminPaymentQrCodePicture,
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
      'midtransIdentifier': midtransIdentifier, // Ditambahkan ke toMap
      'adminPaymentCode': adminPaymentCode,
      'adminPaymentQrCodePicture': adminPaymentQrCodePicture,
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
      midtransIdentifier:
          map['midtransIdentifier'] !=
                  null // Ditambahkan ke fromMap
              ? map['midtransIdentifier'] as String
              : null,
      adminPaymentCode:
          map['adminPaymentCode'] != null
              ? map['adminPaymentCode'] as String
              : null,
      adminPaymentQrCodePicture:
          map['adminPaymentQrCodePicture'] != null
              ? map['adminPaymentQrCodePicture'] as String
              : null,
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
    return 'PaymentMethodModel(id: $id, name: $name, description: $description, logo: $logo, paymentMethodType: $paymentMethodType, minimumAmount: $minimumAmount, maximumAmount: $maximumAmount, midtransIdentifier: $midtransIdentifier, adminPaymentCode: $adminPaymentCode, adminPaymentQrCodePicture: $adminPaymentQrCodePicture, createdAt: $createdAt, updatedAt: $updatedAt)';
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
        other.midtransIdentifier ==
            midtransIdentifier && // Ditambahkan ke operator ==
        other.adminPaymentCode == adminPaymentCode &&
        other.adminPaymentQrCodePicture == adminPaymentQrCodePicture &&
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
        midtransIdentifier.hashCode ^ // Ditambahkan ke hashCode
        adminPaymentCode.hashCode ^
        adminPaymentQrCodePicture.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreatePaymentMethodDto {
  final String name;
  final String? description;
  final File? logoFile;
  final PaymentMethodType paymentMethodType;
  final double minimumAmount;
  final double maximumAmount;
  final String? midtransIdentifier; // Ditambahkan ke Create DTO
  final String? adminPaymentCode;
  final File? adminPaymentQrCodeFile;

  CreatePaymentMethodDto({
    required this.name,
    this.description,
    this.logoFile,
    required this.paymentMethodType,
    required this.minimumAmount,
    required this.maximumAmount,
    this.midtransIdentifier, // Ditambahkan
    this.adminPaymentCode,
    this.adminPaymentQrCodeFile,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'paymentMethodType': paymentMethodType.toMap(),
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
      'midtransIdentifier': midtransIdentifier, // Ditambahkan ke toMap
      'adminPaymentCode': adminPaymentCode,
    };
  }
}

class UpdatePaymentMethodDto {
  final String? name;
  final String? description;
  final File? logoFile;
  final PaymentMethodType? paymentMethodType;
  final double? minimumAmount;
  final double? maximumAmount;
  final String? midtransIdentifier; // Ditambahkan ke Update DTO
  final String? adminPaymentCode;
  final File? adminPaymentQrCodeFile;

  UpdatePaymentMethodDto({
    this.name,
    this.description,
    this.logoFile,
    this.paymentMethodType,
    this.minimumAmount,
    this.maximumAmount,
    this.midtransIdentifier, // Ditambahkan
    this.adminPaymentCode,
    this.adminPaymentQrCodeFile,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (paymentMethodType != null) {
      map['paymentMethodType'] = paymentMethodType!.toMap();
    }
    if (minimumAmount != null) map['minimumAmount'] = minimumAmount;
    if (maximumAmount != null) map['maximumAmount'] = maximumAmount;
    if (midtransIdentifier != null) {
      map['midtransIdentifier'] = midtransIdentifier; // Ditambahkan ke toMap
    }
    if (adminPaymentCode != null) map['adminPaymentCode'] = adminPaymentCode;
    return map;
  }

  String toJson() => json.encode(toMap());
}
