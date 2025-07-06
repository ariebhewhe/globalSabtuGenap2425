// service/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qurbanqu/model/order_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qurbanqu/model/product_model.dart';
import 'package:qurbanqu/model/user_model.dart';
import 'package:qurbanqu/service/product_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'Orders';
  final ProductService _productService =
      ProductService(); // Inisialisasi ProductService

  // Mendapatkan user ID saat ini
  String? get currentUserId => _auth.currentUser?.uid;
  Future<List<FullyPopulatedOrderModel>> getAllOrders() async {
    try {
      // Langkah 1: Dapatkan semua pesanan
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();
      List<OrderModel> orderList =
          snapshot.docs.map((doc) {
            return OrderModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      // Langkah 2: Siapkan list untuk menyimpan pesanan yang sudah dipopulate
      List<FullyPopulatedOrderModel> populatedOrders = [];

      // Langkah 3: Iterasi setiap pesanan untuk mengambil data user dan product
      for (OrderModel order in orderList) {
        // Ambil data product berdasarkan hewanId
        ProductModel? product;
        if (order.hewanId.isNotEmpty) {
          product = await _productService.getProductById(order.hewanId);
        }

        // Ambil data user berdasarkan userId
        UserModel? user;
        if (order.userId.isNotEmpty) {
          // Dapatkan dokumen user dari Firestore
          DocumentSnapshot userDoc =
              await _firestore.collection('Users').doc(order.userId).get();
          if (userDoc.exists) {
            user = UserModel.fromMap(
              userDoc.data() as Map<String, dynamic>,
              userDoc.id,
            );
          }
        }

        // Buat objek FullyPopulatedOrderModel dan tambahkan ke list
        populatedOrders.add(
          FullyPopulatedOrderModel(order: order, product: product, user: user),
        );
      }

      return populatedOrders;
    } catch (e) {
      print('Error mengambil pesanan dengan populate: $e');
      throw Exception('Gagal mengambil data pesanan yang dipopulate');
    }
  }

  // Mendapatkan pesanan berdasarkan ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(orderId).get();

      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error mengambil pesanan by ID: $e');
      throw Exception('Gagal mengambil data pesanan');
    }
  }

  // Menambahkan pesanan baru
  Future<String> addOrder({
    required String hewanId, // Ini adalah ID produk tunggal
    required int jumlah,
    required double totalHarga,
    String? fotoBuktiTransfer,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User belum login');
      }

      final orderData = {
        'user_id': currentUserId,
        'hewan_id': hewanId, // ID produk tunggal
        'tanggal_pesanan': DateTime.now().millisecondsSinceEpoch,
        'jumlah': jumlah,
        'total_harga': totalHarga,
        'status': 'menunggu pembayaran', // Status awal
        'foto_bukti_transfer': fotoBuktiTransfer ?? '',
      };

      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(orderData);

      return docRef.id;
    } catch (e) {
      print('Error menambahkan pesanan: $e');
      throw Exception('Gagal menambahkan pesanan: $e');
    }
  }

  Future<void> updateOrderStatusToSuccessOrFailed(
    String orderId,
    bool isSuccess,
  ) async {
    try {
      final String newStatus = isSuccess ? 'success' : 'failed';
      await _firestore.collection(_collectionName).doc(orderId).update({
        'status': newStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error memperbarui status sukses/gagal pesanan: $e');
      throw Exception('Gagal memperbarui status pesanan');
    }
  }

  // Memperbarui bukti transfer dan status pesanan
  Future<void> updateOrderAfterPayment(
    String orderId,
    String fotoUrl,
    String newStatus,
  ) async {
    try {
      await _firestore.collection(_collectionName).doc(orderId).update({
        'foto_bukti_transfer': fotoUrl,
        'status': newStatus,
        'tanggal_pembayaran': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error memperbarui bukti transfer dan status: $e');
      throw Exception('Gagal memperbarui pesanan');
    }
  }

  Future<List<OrderModel>> getOrdersByUserId(String userId) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collectionName)
              .where('user_id', isEqualTo: userId)
              .where('status', isNotEqualTo: 'dibatalkan')
              .get();
      List<OrderModel> orderList =
          snapshot.docs.map((doc) {
            return OrderModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

      return orderList;
    } catch (e) {
      print('Error mengambil pesanan by user ID: $e');
      throw Exception('Gagal mengambil data pesanan');
    }
  }

  // BARU: Mendapatkan pesanan berdasarkan user ID dengan data produk yang dipopulate
  // Disesuaikan untuk skenario "hanya bisa order 1 produk"
  Future<List<PopulatedOrderModel>> getPopulatedOrdersByUserId(
    String userId,
  ) async {
    try {
      // Langkah 1: Dapatkan semua order untuk user tersebut
      List<OrderModel> userOrders = await getOrdersByUserId(userId);

      if (userOrders.isEmpty) {
        return []; // Tidak ada order, kembalikan list kosong
      }

      List<PopulatedOrderModel> populatedOrders = [];
      for (OrderModel order in userOrders) {
        // Langkah 2: Untuk setiap order, dapatkan produk yang terkait
        // Karena hanya ada 1 produk per order, kita langsung ambil berdasarkan order.hewanId
        ProductModel? product;
        if (order.hewanId.isNotEmpty) {
          // Pastikan hewanId tidak kosong
          product = await _productService.getProductById(order.hewanId);
        }

        // Langkah 3: Buat PopulatedOrderModel
        populatedOrders.add(
          PopulatedOrderModel(order: order, product: product),
        );
      }

      return populatedOrders;
    } catch (e) {
      print('Error mengambil populated orders by user ID: $e');
      throw Exception('Gagal mengambil data pesanan yang dipopulate: $e');
    }
  }

  // Opsional: Memperbarui status pesanan (digunakan oleh admin)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection(_collectionName).doc(orderId).update({
        'status': newStatus,
      });
    } catch (e) {
      print('Error memperbarui status pesanan: $e');
      throw Exception('Gagal memperbarui status pesanan');
    }
  }

  // metode untuk membatalkan pesanan
  Future<void> cancelOrder(String orderId) async {
    try {
      // Update status pesanan menjadi 'cancelled' atau 'dibatalkan'
      await _firestore.collection('Orders').doc(orderId).update({
        'status': 'dibatalkan',
        'cancelledAt': FieldValue.serverTimestamp(), // Timestamp pembatalan
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Pesanan $orderId berhasil dibatalkan');
    } catch (e) {
      print('Error membatalkan pesanan: $e');
      throw Exception('Gagal membatalkan pesanan: $e');
    }
  }

  // menghapus pesanan sepenuhnya dari database
  Future<void> deleteOrder(String orderId) async {
    try {
      // Hapus dokumen pesanan dari koleksi Orders
      await _firestore.collection(_collectionName).doc(orderId).delete();

      print('Pesanan $orderId berhasil dihapus permanen');
    } catch (e) {
      print('Error menghapus pesanan: $e');
      throw Exception('Gagal menghapus pesanan: $e');
    }
  }
}
