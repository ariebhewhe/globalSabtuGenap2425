import 'dart:convert';

abstract class BaseModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap();

  String toJson() => json.encode(toMap());

  @override
  String toString();

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  // * Helper untuk datetime serialization
  static int dateTimeToMillis(DateTime dateTime) =>
      dateTime.millisecondsSinceEpoch;
  static DateTime millisToDateTime(int millis) =>
      DateTime.fromMillisecondsSinceEpoch(millis);

  // * Static method untuk timestamp fields
  static Map<String, dynamic> getTimeStampFields(
    DateTime createdAt,
    DateTime updatedAt,
  ) {
    return {
      'createdAt': dateTimeToMillis(createdAt),
      'updatedAt': dateTimeToMillis(updatedAt),
    };
  }
}

mixin ModelHelper {
  static DateTime parseDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    }
    throw Exception('Invalid date format: $value');
  }
}
