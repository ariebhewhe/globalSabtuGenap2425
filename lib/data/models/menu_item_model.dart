// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/data/models/category_model.dart';

class MenuItemModel extends BaseModel {
  final String name;
  final String description;
  final double price;
  final String? categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final CategoryModel? category;

  MenuItemModel({
    required String id,
    required this.name,
    required this.description,
    required this.price,
    this.categoryId,
    this.imageUrl,
    required this.isAvailable,
    this.category, // Ditambahkan di sini
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? imageUrl,
    bool? isAvailable,
    CategoryModel? category, // Ditambahkan di sini
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category, // Ditambahkan di sini
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
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'category': category?.toMap(), // Ditambahkan di sini
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
      categoryId:
          map['categoryId'] != null ? map['categoryId'] as String : null,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      isAvailable: map['isAvailable'] as bool,
      // Ditambahkan di sini
      category:
          map['category'] != null
              ? CategoryModel.fromMap(map['category'] as Map<String, dynamic>)
              : null,
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
    return 'MenuItemModel(id: $id, name: $name, description: $description, price: $price, categoryId: $categoryId, imageUrl: $imageUrl, isAvailable: $isAvailable, category: $category, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant MenuItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.categoryId == categoryId &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable &&
        other.category == category && // Ditambahkan di sini
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        categoryId.hashCode ^
        imageUrl.hashCode ^
        isAvailable.hashCode ^
        category.hashCode ^ // Ditambahkan di sini
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreateMenuItemDto {
  final String name;
  final String description;
  final double price;
  final String? categoryId;
  File? imageFile;
  final bool isAvailable;

  CreateMenuItemDto({
    required this.name,
    required this.description,
    required this.price,
    this.categoryId,
    this.imageFile,
    required this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
    };
  }

  String toJson() => json.encode(toMap());

  factory CreateMenuItemDto.fromMap(Map<String, dynamic> map) {
    return CreateMenuItemDto(
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] as double,
      categoryId:
          map['categoryId'] != null ? map['categoryId'] as String : null,
      isAvailable: map['isAvailable'] as bool,
    );
  }

  factory CreateMenuItemDto.fromJson(String source) =>
      CreateMenuItemDto.fromMap(json.decode(source) as Map<String, dynamic>);
}

class UpdateMenuItemDto {
  final String? name;
  final String? description;
  final double? price;
  final String? categoryId;
  File? imageFile;
  final bool? isAvailable;

  UpdateMenuItemDto({
    this.name,
    this.description,
    this.price,
    this.categoryId,
    this.imageFile,
    this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (categoryId != null) map['categoryId'] = categoryId;
    if (isAvailable != null) map['isAvailable'] = isAvailable;
    return map;
  }

  String toJson() => json.encode(toMap());
}

class DenormalizedMenuItemModel {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? categoryId;
  final CategoryModel? category;

  DenormalizedMenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.category,
  });

  DenormalizedMenuItemModel copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? categoryId,
    CategoryModel? category,
  }) {
    return DenormalizedMenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'category': category?.toMap(),
    };
  }

  factory DenormalizedMenuItemModel.fromMap(Map<String, dynamic> map) {
    return DenormalizedMenuItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: map['price'] as double,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      categoryId:
          map['categoryId'] != null ? map['categoryId'] as String : null,
      category:
          map['category'] != null
              ? CategoryModel.fromMap(map['category'] as Map<String, dynamic>)
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DenormalizedMenuItemModel.fromJson(String source) =>
      DenormalizedMenuItemModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'DenormalizedMenuItemModel(id: $id, name: $name, price: $price, imageUrl: $imageUrl, categoryId: $categoryId, category: $category)';
  }

  @override
  bool operator ==(covariant DenormalizedMenuItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.categoryId == categoryId &&
        other.category == category;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        price.hashCode ^
        imageUrl.hashCode ^
        categoryId.hashCode ^
        category.hashCode;
  }

  factory DenormalizedMenuItemModel.fromMenuItemModel(MenuItemModel menuItem) {
    return DenormalizedMenuItemModel(
      id: menuItem.id,
      name: menuItem.name,
      price: menuItem.price,
      imageUrl: menuItem.imageUrl,
    );
  }
}
