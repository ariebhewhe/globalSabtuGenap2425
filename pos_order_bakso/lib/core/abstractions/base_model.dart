// core/abstractions/base_model.dart

import 'dart:convert';

abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Mengonversi model menjadi Map untuk disimpan ke Firestore.
  Map<String, dynamic> toMap();

  /// Mengonversi model menjadi string JSON.
  /// Biasanya digunakan untuk logging atau debugging.
  String toJson() => json.encode(toMap());

  @override
  String toString();

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
