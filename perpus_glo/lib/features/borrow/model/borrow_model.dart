import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BorrowStatus {
  pending, // Menunggu konfirmasi
  active, // Sedang dipinjam
  pendingReturn, // Menunggu pengembalian
  returned, // Sudah dikembalikan
  overdue, // Terlambat
  rejected, // Ditolak
  rejectedReturn, // Penolakan pengembalian
  lost // Hilang
}

extension BorrowStatusExtension on BorrowStatus {
  String get name {
    switch (this) {
      case BorrowStatus.pending:
        return 'Menunggu Konfirmasi';
      case BorrowStatus.active:
        return 'Dipinjam';
      case BorrowStatus.pendingReturn:
        return 'Menunggu Pengembalian';
      case BorrowStatus.returned:
        return 'Dikembalikan';
      case BorrowStatus.overdue:
        return 'Terlambat';
      case BorrowStatus.rejected:
        return 'Ditolak';
      case BorrowStatus.rejectedReturn:
        return 'Pengembalian Ditolak';
      case BorrowStatus.lost:
        return 'Hilang';
    }
  }

  Color get color {
    switch (this) {
      case BorrowStatus.pending:
        return Colors.amber;
      case BorrowStatus.active:
        return Colors.blue;
      case BorrowStatus.pendingReturn:
        return Colors.teal;
      case BorrowStatus.returned:
        return Colors.green;
      case BorrowStatus.overdue:
        return Colors.orange;
      case BorrowStatus.rejected:
        return Colors.red.shade700;
      case BorrowStatus.rejectedReturn:
        return Colors.red.shade800;
      case BorrowStatus.lost:
        return Colors.red;
    }
  }
}

class BorrowModel {
  final String id;
  final String userId;
  final String bookId;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final BorrowStatus status;
  final double? fine; // Denda yang dikenakan jika ada
  final bool isPaid;

  // Fields for request system
  final DateTime requestDate;
  final DateTime? confirmDate;
  final String? confirmedBy;
  final DateTime? rejectDate;
  final String? rejectedBy;
  final String? rejectReason;

  // Tambahan field untuk penolakan pengembalian
  final DateTime? returnRejectDate;  // Tanggal penolakan pengembalian
  final String? returnRejectedBy;    // ID admin yang menolak pengembalian
  final String? returnRejectReason;  // Alasan penolakan pengembalian

// Properti tambahan untuk UI, tidak disimpan di Firestore
  final String? bookTitle;
  final String? bookCover;
  final String? booksAuthor;
  final String? userName; // Nama peminjam (untuk admin/librarian)
  final String? userEmail;

  BorrowModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.fine,
    required this.isPaid,
    required this.requestDate,
    this.confirmDate,
    this.confirmedBy,
    this.rejectDate,
    this.rejectedBy,
    this.rejectReason,
    this.bookTitle,
    this.bookCover,
    this.booksAuthor,
    this.userName,
    this.userEmail,
    this.returnRejectDate,
    this.returnRejectedBy,
    this.returnRejectReason,
  });

  factory BorrowModel.fromJson(Map<String, dynamic> json) {
    return BorrowModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bookId: json['bookId'] as String,
      borrowDate: (json['borrowDate'] as Timestamp).toDate(),
      dueDate: (json['dueDate'] as Timestamp).toDate(),
      returnDate: json['returnDate'] != null
          ? (json['returnDate'] as Timestamp).toDate()
          : null,
      status: _statusFromString(json['status'] as String? ?? 'active'),
      fine: json['fine']?.toDouble(),
      isPaid: json['isPaid'] as bool? ?? false,
      requestDate: (json['requestDate'] as Timestamp?)?.toDate() ??
          (json['borrowDate'] as Timestamp).toDate(),
      confirmDate: (json['confirmDate'] as Timestamp?)?.toDate(),
      confirmedBy: json['confirmedBy'] as String?,
      rejectDate: (json['rejectDate'] as Timestamp?)?.toDate(),
      rejectedBy: json['rejectedBy'] as String?,
      rejectReason: json['rejectReason'] as String?,
      bookTitle: json['bookTitle'] as String?,
      bookCover: json['bookCover'] as String?,
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
      returnRejectDate: (json['returnRejectDate'] as Timestamp?)?.toDate(),
      returnRejectedBy: json['returnRejectedBy'] as String?,
      returnRejectReason: json['returnRejectReason'] as String?,
    );
  }

  // Helper method to convert status string to enum
  static BorrowStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BorrowStatus.pending;
      case 'active':
        return BorrowStatus.active;
      case 'pendingreturn':
        return BorrowStatus.pendingReturn;
      case 'returned':
        return BorrowStatus.returned;
      case 'overdue':
        return BorrowStatus.overdue;
      case 'rejected':
        return BorrowStatus.rejected;
      case 'lost':
        return BorrowStatus.lost;
      default:
        return BorrowStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      // Base properties
      'userId': userId,
      'bookId': bookId,
      'borrowDate': borrowDate,
      'dueDate': dueDate,
      'returnDate': returnDate,
      'status': status.toString().split('.').last,
      'fine': fine,
      'isPaid': isPaid,

      
      // Request system properties
      'requestDate': requestDate,
      'confirmDate': confirmDate,
      'confirmedBy': confirmedBy,
      'rejectDate': rejectDate,
      'rejectedBy': rejectedBy,
      'rejectReason': rejectReason,

      // UI properties tidak disimpan ke Firestore
      'bookTitle': bookTitle,
      'bookCover': bookCover,
      'userName': userName,
      'userEmail': userEmail,

      // Penolakan pengembalian
      'returnRejectDate': returnRejectDate,
      'returnRejectedBy': returnRejectedBy,
      'returnRejectReason': returnRejectReason,
    };
  }

  // update method toJson() to include bookTitle and bookCover
  BorrowModel copyWith({
    String? id,
    String? userId,
    String? bookId,
    DateTime? borrowDate,
    DateTime? dueDate,
    DateTime? returnDate,
    BorrowStatus? status,
    double? fine,
    bool? isPaid,
    DateTime? requestDate,
    DateTime? confirmDate,
    String? confirmedBy,
    DateTime? rejectDate,
    String? rejectedBy,
    String? rejectReason,
    String? bookTitle,
    String? bookCover,
    String? userName,
    DateTime? returnRejectDate,
    String? returnRejectedBy,
    String? returnRejectReason,
  }) {
    return BorrowModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      borrowDate: borrowDate ?? this.borrowDate,
      dueDate: dueDate ?? this.dueDate,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      fine: fine ?? this.fine,
      isPaid: isPaid ?? this.isPaid,
      requestDate: requestDate ?? this.requestDate,
      confirmDate: confirmDate ?? this.confirmDate,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      rejectDate: rejectDate ?? this.rejectDate,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectReason: rejectReason ?? this.rejectReason,
      bookTitle: bookTitle ?? this.bookTitle,
      bookCover: bookCover ?? this.bookCover,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      returnRejectDate: returnRejectDate ?? this.returnRejectDate,
      returnRejectedBy: returnRejectedBy ?? this.returnRejectedBy,
      returnRejectReason: returnRejectReason ?? this.returnRejectReason,
    );
  }

  // Method untuk cek apakah peminjaman telah melewati tenggat waktu
  bool isOverdue() {
    if (returnDate != null) {
      return returnDate!.isAfter(dueDate);
    }
    return DateTime.now().isAfter(dueDate);
  }

  // Method untuk menghitung denda
  double calculateFine() {
    if (returnDate == null && !isOverdue()) return 0;

    final DateTime endDate = returnDate ?? DateTime.now();
    if (!endDate.isAfter(dueDate)) return 0;

    // Normalisasi tanggal untuk perhitungan yang lebih akurat
    final DateTime normalizedDueDate =
        DateTime(dueDate.year, dueDate.month, dueDate.day);
    final DateTime normalizedEndDate =
        DateTime(endDate.year, endDate.month, endDate.day);

    // Hitung selisih hari
    final difference = normalizedEndDate.difference(normalizedDueDate).inDays;

    // Minimal 1 hari jika terlambat
    final effectiveDays = difference > 0 ? difference : 1;

    // Rumus denda: Rp 2.000 per hari terlambat (konsisten dengan kode lain)
    return effectiveDays * 2000;
  }
}