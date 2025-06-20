import 'package:cloud_firestore/cloud_firestore.dart';

class ModelUtils {
  /// Mem-parsing berbagai format waktu menjadi DateTime.
  /// Bisa menangani:
  /// - Timestamp (dari Firestore)
  /// - String (format ISO 8601 dari API)
  /// - int (millisecondsSinceEpoch dari data lama)
  static DateTime parseDateTime(dynamic value) {
    if (value is Timestamp) {
      // * Paling umum dari Firestore
      return value.toDate();
    } else if (value is String) {
      // * Dari API atau JSON
      return DateTime.parse(value);
    } else if (value is int) {
      // * Untuk data lama yang mungkin masih pakai integer
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    // * Jika format tidak dikenali, lempar error agar kita tahu ada masalah.
    // * Atau kembalikan nilai default jika itu lebih cocok untuk kasusmu.
    throw ArgumentError('Invalid date format. Value: "$value"');
  }
}
