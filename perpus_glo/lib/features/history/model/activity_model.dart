import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  borrowBook,     // Peminjaman buku
  returnBook,     // Pengembalian buku
  addBook,        // Menambah buku
  updateBook,     // Update informasi buku
  deleteBook,     // Hapus buku
  payFine,        // Pembayaran denda
  login,          // Login ke aplikasi
  logout,         // Logout dari aplikasi
  updateProfile,  // Update profil
  register,       // Pendaftaran akun
  addCategory,    // Tambah kategori
  updateCategory, // Update kategori
  deleteCategory, // Hapus kategori
  adminAction,    // Tindakan admin lainnya
  userAction,     // Tindakan pengguna lainnya
  general,        // Aktivitas umum
}

class ActivityModel {
  final String id;
  final String userId;
  final String? userName;
  final String? userRole; // Role pengguna (admin/pustakawan)
  final ActivityType activityType;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? metadata;
  
  ActivityModel({
    required this.id,
    required this.userId,
    this.userName,
    this.userRole,
    required this.activityType,
    required this.timestamp,
    required this.description,
    this.metadata,
  });
  
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    ActivityType type;
    try {
      // Konversi string ke ActivityType
      type = ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['activityType'] as String),
        orElse: () => ActivityType.general,
      );
    } catch (_) {
      type = ActivityType.general;
    }
    
    return ActivityModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      userRole: json['userRole'] as String?,
      activityType: type,
      timestamp: json['timestamp'] is Timestamp 
          ? (json['timestamp'] as Timestamp).toDate() 
          : (json['timestamp'] as DateTime),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userRole': userRole,
      'activityType': activityType.toString().split('.').last,
      'timestamp': timestamp,
      'description': description,
      'metadata': metadata,
    };
  }
}