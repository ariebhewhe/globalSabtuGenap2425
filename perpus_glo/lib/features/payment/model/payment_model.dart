import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus {
  pending, // Menunggu pembayaran
  completed, // Pembayaran selesai
  failed, // Pembayaran gagal
  cancelled // Pembayaran dibatalkan
}

extension PaymentStatusExtension on PaymentStatus {
  String get name {
    switch (this) {
      case PaymentStatus.pending:
        return 'Menunggu Pembayaran';
      case PaymentStatus.completed:
        return 'Pembayaran Selesai';
      case PaymentStatus.failed:
        return 'Pembayaran Gagal';
      case PaymentStatus.cancelled:
        return 'Pembayaran Dibatalkan';
    }
  }
}

class PaymentModel {
  final String id;
  final String userId;
  final String borrowId;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? paymentMethod;
  final String? paymentProofUrl;

  // URL untuk QR Code pembayaran (misalnya QRIS)
  final String? paymentQrUrl;

// Tambahkan properti ini di PaymentModel
  final String? bookId;
  final String? bookTitle;
  final String? bookCover;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.borrowId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.paymentMethod,
    this.paymentProofUrl,
    this.paymentQrUrl,
    this.bookId,
    this.bookTitle,
    this.bookCover,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // Konversi status yang lebih aman
    PaymentStatus getStatus(String? statusStr) {
      if (statusStr == null) return PaymentStatus.pending;

      try {
        return PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusStr,
          orElse: () => PaymentStatus.pending,
        );
      } catch (e) {
        return PaymentStatus.pending;
      }
    }

    return PaymentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      borrowId: json['borrowId'] as String,
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] as num).toDouble(),
      status: getStatus(json['status'] as String?),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'].toString()),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is Timestamp
              ? (json['completedAt'] as Timestamp).toDate()
              : DateTime.parse(json['completedAt'].toString()))
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      paymentQrUrl: json['paymentQrUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'borrowId': borrowId,
      'amount': amount,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'paymentMethod': paymentMethod,
      'paymentProofUrl': paymentProofUrl,
      'paymentQrUrl': paymentQrUrl,
    };
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? borrowId,
    double? amount,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? paymentMethod,
    String? paymentProofUrl,
    String? paymentQrUrl,
    String? bookId,
    String? bookTitle,
    String? bookCover,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      borrowId: borrowId ?? this.borrowId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentQrUrl: paymentQrUrl ?? this.paymentQrUrl,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookCover: bookCover ?? this.bookCover,
    );
  }
}