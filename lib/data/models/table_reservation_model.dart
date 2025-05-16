import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';

class TableReservationModel extends BaseModel {
  final int tableId;
  final int orderId;
  final DateTime reservationTime;
  final int duration; // ? dalam menit
  final ReservationStatus status;
  final RestaurantTableModel? table; // * Populated kalo perlu

  TableReservationModel({
    required String id,
    required this.tableId,
    required this.orderId,
    required this.reservationTime,
    required this.duration,
    required this.status,
    this.table,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  TableReservationModel copyWith({
    String? id,
    int? tableId,
    int? orderId,
    DateTime? reservationTime,
    int? duration,
    ReservationStatus? status,
    RestaurantTableModel? table,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableReservationModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      orderId: orderId ?? this.orderId,
      reservationTime: reservationTime ?? this.reservationTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      table: table ?? this.table,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'tableId': tableId,
      'orderId': orderId,
      'reservationTime': reservationTime.millisecondsSinceEpoch,
      'duration': duration,
      'status': status.toMap(),
      'table': table?.toMap(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  factory TableReservationModel.fromMap(Map<String, dynamic> map) {
    return TableReservationModel(
      id: map['id'] as String,
      tableId: map['tableId'] as int,
      orderId: map['orderId'] as int,
      reservationTime: DateTime.fromMillisecondsSinceEpoch(
        map['reservationTime'] as int,
      ),
      duration: map['duration'] as int,
      status: ReservationStatusExtension.fromMap(map['status'] as String),
      table:
          map['table'] != null
              ? RestaurantTableModel.fromMap(
                map['table'] as Map<String, dynamic>,
              )
              : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toJson() => json.encode(toMap());

  @override
  factory TableReservationModel.fromJson(String source) =>
      TableReservationModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'TableReservationModel(id: $id, tableId: $tableId, orderId: $orderId, reservationTime: $reservationTime, duration: $duration, status: $status, table: $table, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant TableReservationModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.tableId == tableId &&
        other.orderId == orderId &&
        other.reservationTime == reservationTime &&
        other.duration == duration &&
        other.status == status &&
        other.table == table &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        tableId.hashCode ^
        orderId.hashCode ^
        reservationTime.hashCode ^
        duration.hashCode ^
        status.hashCode ^
        table.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
