import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';

class MenuItemModel extends BaseModel {
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final int spiceLevel;

  MenuItemModel({
    required String id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
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
    String? categoryId,
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
      categoryId: categoryId ?? this.categoryId,
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
      'categoryId': categoryId,
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
      categoryId: map['categoryId'] as String,
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
    return 'MenuItemModel(id: $id, name: $name, description: $description, price: $price, categoryId: $categoryId, imageUrl: $imageUrl, isAvailable: $isAvailable, isVegetarian: $isVegetarian, spiceLevel: $spiceLevel, createdAt: $createdAt, updatedAt: $updatedAt)';
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
        categoryId.hashCode ^
        imageUrl.hashCode ^
        isAvailable.hashCode ^
        isVegetarian.hashCode ^
        spiceLevel.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreateMenuItemDto {
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final int spiceLevel;

  CreateMenuItemDto({
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    this.imageUrl,
    required this.isAvailable,
    required this.isVegetarian,
    required this.spiceLevel,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'spiceLevel': spiceLevel,
    };
  }

  String toJson() => json.encode(toMap());
}

class UpdateMenuItemDto {
  final String? name;
  final String? description;
  final double? price;
  final String? categoryId;
  final String? imageUrl;
  final bool? isAvailable;
  final bool? isVegetarian;
  final int? spiceLevel;

  UpdateMenuItemDto({
    this.name,
    this.description,
    this.price,
    this.categoryId,
    this.imageUrl,
    this.isAvailable,
    this.isVegetarian,
    this.spiceLevel,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (description != null) map['description'] = description;
    if (price != null) map['price'] = price;
    if (categoryId != null) map['categoryId'] = categoryId;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (isAvailable != null) map['isAvailable'] = isAvailable;
    if (isVegetarian != null) map['isVegetarian'] = isVegetarian;
    if (spiceLevel != null) map['spiceLevel'] = spiceLevel;
    return map;
  }

  String toJson() => json.encode(toMap());
}

class DenormalizedMenuItemModel {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  DenormalizedMenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  DenormalizedMenuItemModel copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
  }) {
    return DenormalizedMenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory DenormalizedMenuItemModel.fromMap(Map<String, dynamic> map) {
    return DenormalizedMenuItemModel(
      id: map['id'] as String,
      name: map['name'] as String,
      price: map['price'] as double,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DenormalizedMenuItemModel.fromJson(String source) =>
      DenormalizedMenuItemModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'DenormalizedMenuItemModel(id: $id, name: $name, price: $price, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(covariant DenormalizedMenuItemModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.price == price &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ price.hashCode ^ imageUrl.hashCode;
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
