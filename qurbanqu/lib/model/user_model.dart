class UserModel {
  final String id;
  final String nama;
  final String email;
  final String telepon;
  final String alamat;
  final String role;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.telepon,
    required this.alamat,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'alamat': alamat,
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      telepon: map['telepon'] ?? '',
      alamat: map['alamat'] ?? '',
      role: map['role'] ?? userRoleToString(UserRole.user),
    );
  }

  UserModel? copyWith({
    required String nama,
    required String telepon,
    required String alamat,
  }) {}
}

enum UserRole { user, admin }

String userRoleToString(UserRole role) {
  return role.toString().split('.').last;
}

UserRole stringToUserRole(String roleString) {
  return UserRole.values.firstWhere(
    (role) => userRoleToString(role) == roleString,
    orElse: () => UserRole.user,
  );
}
