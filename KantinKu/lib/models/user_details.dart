// models/user_details.dart
class UserDetails {
  final String name;
  final String email;
  final String role;
  final int createdAt;

  UserDetails({
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserDetails.fromMap(Map<String, dynamic> map) {
    return UserDetails(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }
}