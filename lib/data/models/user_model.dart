import 'dart:convert';

import 'package:jamal/core/utils/enums.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? password;
  final Role role;
  final String? phoneNumber;
  final String? address;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    this.phoneNumber,
    this.address,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    Role? role,
    String? phoneNumber,
    String? address,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'role': role.toMap(),
      'phoneNumber': phoneNumber,
      'address': address,
      'profilePicture': profilePicture,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] != null ? map['password'] as String : null,
      role: RoleExtension.fromMap(map['role'] as String),
      phoneNumber:
          map['phoneNumber'] != null ? map['phoneNumber'] as String : null,
      address: map['address'] != null ? map['address'] as String : null,
      profilePicture:
          map['profilePicture'] != null
              ? map['profilePicture'] as String
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, email: $email, password: $password, role: $role, phoneNumber: $phoneNumber, address: $address, profilePicture: $profilePicture, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.username == username &&
        other.email == email &&
        other.password == password &&
        other.role == role &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.profilePicture == profilePicture &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        username.hashCode ^
        email.hashCode ^
        password.hashCode ^
        role.hashCode ^
        phoneNumber.hashCode ^
        address.hashCode ^
        profilePicture.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
