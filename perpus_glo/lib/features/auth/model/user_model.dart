import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/model/user_profile_model.dart'; // Import untuk UserRole

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final double fineAmount;
  final List<String> borrowedBooks;
  final List<String> pendingBooks;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.fineAmount,
    this.borrowedBooks = const [],
    this.pendingBooks = const [],
    this.role = UserRole.user,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      borrowedBooks: List<String>.from(json['borrowedBooks'] ?? []),
      pendingBooks: List<String>.from(json['pendingBooks'] ?? []),
      fineAmount: (json['fineAmount'] ?? 0).toDouble(),
      role: _roleFromString(json['role'] ?? 'user'), // Parse role dari string
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'borrowedBooks': borrowedBooks,
      'pendingBooks': pendingBooks,
      'fineAmount': fineAmount,
      'role': role.toString().split('.').last, // Convert enum ke string
    };
  }

  // Helper method untuk mengkonversi string ke enum UserRole
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

  // Tambahkan method copyWith untuk memudahkan update model
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    List<String>? borrowedBooks,
    List<String>? pendingBooks,
    double? fineAmount,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      borrowedBooks: borrowedBooks ?? this.borrowedBooks,
      pendingBooks: pendingBooks ?? this.pendingBooks,
      fineAmount: fineAmount ?? this.fineAmount,
      role: role ?? this.role,
    );
  }

  // Helpers untuk memeriksa role
  bool get isAdmin => role == UserRole.admin;
  bool get isLibrarian => role == UserRole.librarian;
  bool get isUser => role == UserRole.user;
}