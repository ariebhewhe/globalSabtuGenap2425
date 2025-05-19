import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';

class CategoryModel extends BaseModel {
  final String name;
  String? description;
  String? picture;

  CategoryModel({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.name,
    this.description,
    this.picture,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? picture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picture: picture ?? this.picture,
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
      'picture': picture,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description:
          map['description'] != null ? map['description'] as String : null,
      picture: map['picture'] != null ? map['picture'] as String : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory CategoryModel.fromJson(String source) =>
      CategoryModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'CategoryModel(id: $id, name: $name, description: $description, picture: $picture, createdAt: $createdAt, updatedAt: $updatedAt)';

  @override
  bool operator ==(covariant CategoryModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.description == description &&
        other.picture == picture &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      picture.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}

class CreateCategoryDto {
  final String name;
  String? description;
  String? picture;

  CreateCategoryDto({required this.name, this.description, this.picture});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'picture': picture,
    };
  }
}

class UpdateCategoryDto {
  final String? name;
  String? description;
  String? picture;

  UpdateCategoryDto({this.name, this.description, this.picture});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'picture': picture,
    };
  }
}
