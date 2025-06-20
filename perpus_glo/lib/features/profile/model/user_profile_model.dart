import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserRole {
  user,
  librarian,
  admin,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'Pengguna';
      case UserRole.librarian:
        return 'Pustakawan';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.user:
        return Colors.blue;
      case UserRole.librarian:
        return Colors.orange;
      case UserRole.admin:
        return Colors.red;
    }
  }
}

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final String? address;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.address,
    this.role = UserRole.user,
    required this.createdAt,
    this.lastLoginAt,
    this.metadata,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      role: _roleFromString(json['role'] ?? 'user'),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (json['lastLoginAt'] as Timestamp?)?.toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'address': address,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'metadata': metadata,
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    String? address,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'librarian':
        return UserRole.librarian;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  // Tambahkan ini di dalam class UserProfileModel
  bool get isAdmin => role == UserRole.admin;
  bool get isLibrarian => role == UserRole.librarian;
  bool get isUser => role == UserRole.user;

// Dan pastikan ada method untuk mendapatkan label dan warna role
  String get roleLabel => _getRoleLabel(role);
  Color get roleColor => _getRoleColor(role);

// Helper methods
  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.librarian:
        return 'Pustakawan';
      case UserRole.user:
        return 'Pengguna';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.librarian:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }
}