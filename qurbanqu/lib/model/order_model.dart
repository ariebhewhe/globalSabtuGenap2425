import 'package:qurbanqu/model/product_model.dart';
import 'package:qurbanqu/model/user_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final String hewanId;
  final String? fotoBuktiTransfer;
  final DateTime tanggalPesanan;
  final int jumlah;
  final double totalHarga;
  final String status;

  OrderModel({
    required this.id,
    required this.userId,
    required this.hewanId,
    required this.tanggalPesanan,
    required this.jumlah,
    required this.totalHarga,
    required this.status,
    this.fotoBuktiTransfer,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['user_id'] ?? '',
      hewanId: map['hewan_id'] ?? '',
      fotoBuktiTransfer: map['foto_bukti_transfer'] ?? '',
      tanggalPesanan: DateTime.fromMillisecondsSinceEpoch(
        map['tanggal_pesanan'] ?? 0,
      ),
      jumlah: map['jumlah'] ?? 0,
      totalHarga: (map['total_harga'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'hewan_id': hewanId,
      'foto_bukti_transfer': fotoBuktiTransfer,
      'tanggal_pesanan': tanggalPesanan.millisecondsSinceEpoch,
      'jumlah': jumlah,
      'total_harga': totalHarga,
      'status': status,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      hewanId: json['hewan_id'] ?? '',
      fotoBuktiTransfer: json['foto_bukti_transfer'] ?? '',
      tanggalPesanan: DateTime.parse(json['tanggal_pesanan']),
      jumlah: json['jumlah'] ?? 0,
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  @override
  String toString() {
    return 'OrderModel(id: $id, userId: $userId, hewanId: $hewanId, fotoBuktiTransfer: $fotoBuktiTransfer, tanggalPesanan: $tanggalPesanan, jumlah: $jumlah, totalHarga: $totalHarga, status: $status)';
  }
}

enum StatusOrder { pending, success, failed }

String statusOrderToString(StatusOrder status) {
  return status.toString().split('.').last;
}

StatusOrder stringToStatusOrder(String statusString) {
  return StatusOrder.values.firstWhere(
    (status) => statusOrderToString(status) == statusString,
    orElse:
        () => StatusOrder.pending, // Menggunakan pending sebagai nilai default
  );
}

class PopulatedOrderModel {
  final OrderModel order;
  final ProductModel?
  product; // Produk bisa null jika hewan_id tidak valid atau produk terhapus

  PopulatedOrderModel({required this.order, this.product});

  @override
  String toString() {
    return 'PopulatedOrderModel(order: $order, product: $product)';
  }
}

class FullyPopulatedOrderModel {
  final OrderModel order;
  final ProductModel? product;
  final UserModel? user;

  FullyPopulatedOrderModel({required this.order, this.product, this.user});

  @override
  String toString() {
    return 'FullyPopulatedOrderModel(order: $order, product: $product, user: $user)';
  }
}
