import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

final orderRepoProvider = Provider.autoDispose<OrderRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final currentUserService = ref.watch(currentUserStorageServiceProvider);

  return OrderRepo(firestore, currentUserService);
});

class OrderRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CurrentUserStorageService _currentUserStorageService;

  final String _collectionPath = 'orders';
  final AppLogger logger = AppLogger();

  OrderRepo(this._firebaseFirestore, this._currentUserStorageService);

  Future<Either<ErrorResponse, SuccessResponse<OrderModel>>> addOrder(
    CreateOrderDto dto,
  ) async {
    try {
      final userId = await _getCurrentUserId();

      final ordersCollection = _firebaseFirestore.collection(_collectionPath);
      final docRef = ordersCollection.doc();

      // Menghitung totalAmount dari orderItems
      double totalAmount = 0;
      for (var item in dto.orderItems) {
        totalAmount += item.price * item.quantity;
      }

      final orderData = dto.toMap();

      orderData['id'] = docRef.id;
      orderData['userId'] = userId;
      orderData['status'] = OrderStatus.pending.toMap();
      orderData['paymentStatus'] = PaymentStatus.unpaid.toMap();
      orderData['totalAmount'] = totalAmount;
      orderData['orderDate'] = DateTime.now().millisecondsSinceEpoch;
      orderData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      orderData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await docRef.set(orderData);

      final order = OrderModel.fromMap(orderData);

      return Right(
        SuccessResponse(data: order, message: 'New order added successfully'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new order: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<OrderModel>>>>
  getAllOrders() async {
    try {
      final userId = await _getCurrentUserId();
      final querySnapshot =
          await _firebaseFirestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: userId)
              .get();

      final orders =
          querySnapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data()))
              .toList();

      return Right(
        SuccessResponse(data: orders, message: 'Orders retrieved successfully'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get all orders: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<OrderModel>>>>
  getPaginatedOrders({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      Query query = _firebaseFirestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .orderBy(orderBy, descending: descending)
          .limit(limit);

      // * Tambahkan startAfter jika disediakan (untuk load more)
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      // * Konversi hasil query menjadi model
      final orders =
          querySnapshot.docs
              .map(
                (doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      // * Cek apakah masih ada data lagi yang bisa dimuat
      final hasMore = querySnapshot.docs.length >= limit;

      // * Simpan dokumen terakhir untuk digunakan sebagai startAfter pada request berikutnya
      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      // * Kembalikan hasil dengan metadata pagination
      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: orders,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Orders retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated orders: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<OrderModel>>> getOrderById(
    String id,
  ) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "Order not found"));
      }

      final order = OrderModel.fromMap(querySnapshot.data()!);

      return Right(
        SuccessResponse(data: order, message: 'Order retrieved successfully'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: "Failed to get order: ${e.toString()}"),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<OrderModel>>> updateOrder(
    String id,
    UpdateOrderDto dto,
  ) async {
    try {
      final userId = await _getCurrentUserId();
      final orderResult = await getOrderById(id);

      if (orderResult.isLeft()) {
        return Left(ErrorResponse(message: 'Order not found'));
      }

      final currentOrder = orderResult.getRight().toNullable()!.data;

      if (currentOrder.userId != userId) {
        return Left(
          ErrorResponse(message: 'Unauthorized to update this order'),
        );
      }

      final updateData = dto.toMap();

      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(updateData);

      // Perbarui model order dengan data baru
      final updatedOrder = currentOrder.copyWith(
        tableId: dto.tableId,
        orderType: dto.orderType,
        status: dto.status,
        paymentStatus: dto.paymentStatus,
        estimatedReadyTime: dto.estimatedReadyTime,
        updatedAt: DateTime.now(),
      );

      return Right(
        SuccessResponse(
          data: updatedOrder,
          message: "Order updated successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update order: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteOrder(
    String id,
  ) async {
    try {
      final userId = await _getCurrentUserId();

      final orderResult = await getOrderById(id);

      if (orderResult.isLeft()) {
        return Left(ErrorResponse(message: 'Order not found'));
      }

      final order = orderResult.getRight().toNullable()!.data;

      if (order.userId != userId) {
        return Left(
          ErrorResponse(message: 'Unauthorized to delete this order'),
        );
      }

      await _firebaseFirestore.collection(_collectionPath).doc(id).delete();

      return Right(
        SuccessResponse(data: id, message: "Order deleted successfully"),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete order: ${e.toString()}'),
      );
    }
  }

  Future<String> _getCurrentUserId() async {
    final user = await _currentUserStorageService.getCurrentUser();

    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }
}
