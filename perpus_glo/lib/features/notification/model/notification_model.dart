import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  general,
  info,            // Tambahkan info
  reminder,        // Tambahkan reminder (walaupun sudah ada returnReminder)
  borrowRequest,   // User meminta peminjaman
  borrowConfirmed, // Peminjaman disetujui
  borrowRejected,  // Peminjaman ditolak
  borrowRequestAdmin, // Notifikasi ke admin ada permintaan baru
  returnReminder,  // Pengingat pengembalian
  bookReturned,    // Buku dikembalikan
  overdue,         // Buku terlambat
  fine,            // Denda
  payment,         // Pembayaran
  announcement, 
  bookReturnedLate, bookReturnRequest,    // Pengumuman
  returnRejected // Pengembalian buku ditolak
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'Umum';
      case NotificationType.info:           // Tambahkan ini
        return 'Informasi';
      case NotificationType.reminder:       // Tambahkan ini
        return 'Pengingat';
      case NotificationType.borrowRequest:
        return 'Permintaan Peminjaman';
      case NotificationType.borrowConfirmed:
        return 'Peminjaman Disetujui';
      case NotificationType.borrowRejected:
        return 'Peminjaman Ditolak';
      case NotificationType.borrowRequestAdmin:
        return 'Permintaan Peminjaman Baru';
      case NotificationType.returnReminder:
        return 'Pengingat Pengembalian';
      case NotificationType.bookReturned:
        return 'Buku Dikembalikan';
      case NotificationType.overdue:
        return 'Terlambat';
      case NotificationType.fine:
        return 'Denda';
      case NotificationType.payment:
        return 'Pembayaran';
      case NotificationType.announcement:
        return 'Pengumuman';
      case NotificationType.bookReturnedLate: // Tambahkan ini
        return 'Buku Dikembalikan Terlambat';
      case NotificationType.bookReturnRequest: // Tambahkan ini
        return 'Permintaan Pengembalian Buku';
      case NotificationType.returnRejected: // Tambahkan ini
        return 'Pengembalian Buku Ditolak';
    }
  }
  
  IconData get icon {
    switch (this) {
      case NotificationType.general:
        return Icons.notifications;
      case NotificationType.info:           // Tambahkan ini
        return Icons.info;
      case NotificationType.reminder:       // Tambahkan ini
        return Icons.access_time;
      case NotificationType.borrowRequest:
        return Icons.book;
      case NotificationType.borrowConfirmed:
        return Icons.check_circle;
      case NotificationType.borrowRejected:
        return Icons.cancel;
      case NotificationType.borrowRequestAdmin:
        return Icons.pending_actions;
      case NotificationType.returnReminder:
        return Icons.alarm;
      case NotificationType.bookReturned:
        return Icons.assignment_turned_in;
      case NotificationType.overdue:
        return Icons.warning;
      case NotificationType.fine:
        return Icons.attach_money;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.bookReturnedLate: // Tambahkan ini
        return Icons.history;
      case NotificationType.bookReturnRequest: // Tambahkan ini
        return Icons.request_page;
      case NotificationType.returnRejected: // Tambahkan ini
        return Icons.block;
    }
  }
  
  Color get color {
    switch (this) {
      case NotificationType.general:
        return Colors.blue;
      case NotificationType.info:           // Tambahkan ini
        return Colors.lightBlue;
      case NotificationType.reminder:       // Tambahkan ini
        return Colors.amber;
      case NotificationType.borrowRequest:
        return Colors.amber;
      case NotificationType.borrowConfirmed:
        return Colors.green;
      case NotificationType.borrowRejected:
        return Colors.red;
      case NotificationType.borrowRequestAdmin:
        return Colors.purple;
      case NotificationType.returnReminder:
        return Colors.orange;
      case NotificationType.bookReturned:
        return Colors.teal;
      case NotificationType.overdue:
        return Colors.deepOrange;
      case NotificationType.fine:
        return Colors.redAccent;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.announcement:
        return Colors.indigo;
      case NotificationType.bookReturnedLate: // Tambahkan ini
        return Colors.red.shade700;
      case NotificationType.bookReturnRequest: // Tambahkan ini
        return Colors.pink;
      case NotificationType.returnRejected: // Tambahkan ini
        return Colors.red.shade800;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

 factory NotificationModel.fromJson(Map<String, dynamic> json) {
  return NotificationModel(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    type: _typeFromString(json['type'] as String? ?? 'general'),
    createdAt: json['createdAt'] is Timestamp 
        ? (json['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    isRead: json['isRead'] as bool? ?? false,
    data: json['data'] as Map<String, dynamic>?,
  );
}

static NotificationType _typeFromString(String type) {
  try {
    return NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
    );
  } catch (_) {
    return NotificationType.general;
  }
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'createdAt': createdAt,
      'isRead': isRead,
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}