import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  borrowBook,     // Peminjaman buku
  returnBook,     // Pengembalian buku
  payFine,        // Pembayaran denda
  reserveBook,    // Reservasi buku
  cancelReserve,  // Pembatalan reservasi
  extensionBorrow,// Perpanjangan peminjaman
  login,          // Login ke aplikasi
  register,       // Pendaftaran akun baru
  updateProfile,  // Update profil
  other,          // Lain-lain
}

extension ActivityTypeExtension on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.borrowBook:
        return 'Peminjaman Buku';
      case ActivityType.returnBook:
        return 'Pengembalian Buku';
      case ActivityType.payFine:
        return 'Pembayaran Denda';
      case ActivityType.reserveBook:
        return 'Reservasi Buku';
      case ActivityType.cancelReserve:
        return 'Pembatalan Reservasi';
      case ActivityType.extensionBorrow:
        return 'Perpanjangan Peminjaman';
      case ActivityType.login:
        return 'Login';
      case ActivityType.register:
        return 'Pendaftaran Akun';
      case ActivityType.updateProfile:
        return 'Update Profil';
      case ActivityType.other:
        return 'Aktivitas Lain';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.borrowBook:
        return 'book_borrow';
      case ActivityType.returnBook:
        return 'book_return';
      case ActivityType.payFine:
        return 'payment';
      case ActivityType.reserveBook:
        return 'book_reserve';
      case ActivityType.cancelReserve:
        return 'book_cancel';
      case ActivityType.extensionBorrow:
        return 'book_extend';
      case ActivityType.login:
        return 'login';
      case ActivityType.register:
        return 'register';
      case ActivityType.updateProfile:
        return 'profile';
      case ActivityType.other:
        return 'other';
    }
  }
  
  IconData get iconData {
    switch (this) {
      case ActivityType.borrowBook:
        return Icons.book;
      case ActivityType.returnBook:
        return Icons.assignment_return;
      case ActivityType.payFine:
        return Icons.payment;
      case ActivityType.reserveBook:
        return Icons.bookmark_add;
      case ActivityType.cancelReserve:
        return Icons.bookmark_remove;
      case ActivityType.extensionBorrow:
        return Icons.update;
      case ActivityType.login:
        return Icons.login;
      case ActivityType.register:
        return Icons.person_add;
      case ActivityType.updateProfile:
        return Icons.manage_accounts;
      case ActivityType.other:
        return Icons.miscellaneous_services;
    }
  }
}

class HistoryModel {
  final String id;
  final String userId;
  final ActivityType activityType;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? metadata;
  
  HistoryModel({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.timestamp,
    required this.description,
    this.metadata,
  });
  
  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      activityType: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['activityType']}',
        orElse: () => ActivityType.other,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'activityType': activityType.toString().split('.').last,
      'timestamp': timestamp,
      'description': description,
      'metadata': metadata,
    };
  }
}