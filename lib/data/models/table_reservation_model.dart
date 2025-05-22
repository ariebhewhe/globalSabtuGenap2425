import 'dart:convert';

import 'package:jamal/core/abstractions/base_model.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';

class TableReservationModel extends BaseModel {
  final String userId;
  final String tableId;
  final String orderId;
  final DateTime reservationTime;
  final ReservationStatus status;
  final RestaurantTableModel? table; // * Populated kalo perlu

  TableReservationModel({
    required String id,
    required this.userId,
    required this.tableId,
    required this.orderId,
    required this.reservationTime,
    required this.status,
    this.table,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(id: id, createdAt: createdAt, updatedAt: updatedAt);

  TableReservationModel copyWith({
    String? id,
    String? userId,
    String? tableId,
    String? orderId,
    DateTime? reservationTime,
    int? duration,
    ReservationStatus? status,
    RestaurantTableModel? table,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableReservationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableId: tableId ?? this.tableId,
      orderId: orderId ?? this.orderId,
      reservationTime: reservationTime ?? this.reservationTime,
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
      'userId': userId,
      'tableId': tableId,
      'orderId': orderId,
      'reservationTime': reservationTime.millisecondsSinceEpoch,
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
      userId: map['userId'] as String,
      tableId: map['tableId'] as String,
      orderId: map['orderId'] as String,
      reservationTime: DateTime.fromMillisecondsSinceEpoch(
        map['reservationTime'] as int,
      ),
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
    return 'TableReservationModel(id: $id, userId: $userId, tableId: $tableId, orderId: $orderId, reservationTime: $reservationTime, status: $status, table: $table, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(covariant TableReservationModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        other.tableId == tableId &&
        other.orderId == orderId &&
        other.reservationTime == reservationTime &&
        other.status == status &&
        other.table == table &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        tableId.hashCode ^
        orderId.hashCode ^
        reservationTime.hashCode ^
        status.hashCode ^
        table.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

class CreateTableReservationDto {
  final String tableId;
  final DateTime reservationTime;
  final RestaurantTableModel? table;

  CreateTableReservationDto({
    required this.tableId,
    required this.reservationTime,
    this.table,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tableId': tableId,
      'reservationTime': reservationTime.millisecondsSinceEpoch,
      'table': table?.toMap(),
    };
  }
}

class UpdateTableReservationDto {
  final ReservationStatus? status;

  UpdateTableReservationDto({this.status});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'status': status?.toMap()};
  }
}
