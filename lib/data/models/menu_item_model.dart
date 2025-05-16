import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';

class MenuItemModel extends BaseModel {
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final int spiceLevel; // 0-5

  MenuItemModel({
    required String id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.isAvailable,
    required this.isVegetarian,
    required this.spiceLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    int? spiceLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      spiceLevel: spiceLevel ?? this.spiceLevel,
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
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'spiceLevel': spiceLevel,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] as double,
      category: map['category'] as String,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      isAvailable: map['isAvailable'] as bool,
      isVegetarian: map['isVegetarian'] as bool,
      spiceLevel: map['spiceLevel'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory MenuItemModel.fromJson(String source) =>
      MenuItemModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MenuItemModel(id: $id, name: $name, description: $description, price: $price, category: $category, imageUrl: $imageUrl, isAvailable: $isAvailable, isVegetarian: $isVegetarian, spiceLevel: $spiceLevel, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant MenuItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.category == category &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable &&
        other.isVegetarian == isVegetarian &&
        other.spiceLevel == spiceLevel &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        category.hashCode ^
        imageUrl.hashCode ^
        isAvailable.hashCode ^
        isVegetarian.hashCode ^
        spiceLevel.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
