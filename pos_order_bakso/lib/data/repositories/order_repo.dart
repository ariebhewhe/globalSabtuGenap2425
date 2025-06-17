import 'dart:convert';
import 'dart:io';

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
import 'package:jamal/shared/services/cloudinary_service.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

final orderRepoProvider = Provider.autoDispose<OrderRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final currentUserService = ref.watch(currentUserStorageServiceProvider);
  final cloudinary = ref.watch(cloudinaryProvider);
  return OrderRepo(firestore, currentUserService, cloudinary);
});

class OrderRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CurrentUserStorageService _currentUserStorageService;
  final CloudinaryService _cloudinaryService;

  final String _collectionPath = 'orders';
  final String _reservationsCollectionPath = 'tableReservations';
  final String _cartCollectionPath = 'cartItems';
  final String _transferProofsCloudinaryFolder = 'order_transfer_proofs';
  final AppLogger logger = AppLogger();

  OrderRepo(
    this._firebaseFirestore,
    this._currentUserStorageService,
    this._cloudinaryService,
  );

  Future<String> _getCurrentUserId() async {
    final user = await _currentUserStorageService.getCurrentUser();
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  Future<void> _deleteImageFromCloudinary(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        final segments = pathSegments.sublist(uploadIndex + 1);
        String fullPath = segments.join('/');
        final lastDotIndex = fullPath.lastIndexOf('.');
        if (lastDotIndex != -1) {
          fullPath = fullPath.substring(0, lastDotIndex);
        }
        await _cloudinaryService.deleteImage(fullPath);
      }
    } catch (e) {
      logger.e(
        'Failed to delete image from Cloudinary: $imageUrl, Error: ${e.toString()}',
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<OrderModel>>> addOrder(
    CreateOrderDto dto,
  ) async {
    try {
      final userId = await _getCurrentUserId();
      final batch = _firebaseFirestore.batch();
      final ordersCollection = _firebaseFirestore.collection(_collectionPath);
      final orderDocRef = ordersCollection.doc();
      final orderId = orderDocRef.id;

      double totalAmount = 0;
      for (var item in dto.orderItems) {
        totalAmount += item.price * item.quantity;
      }

      String? paymentProofUrl;

      if (dto.transferProofFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.transferProofFile!,
            folder: _transferProofsCloudinaryFolder,
          );
          paymentProofUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e(
            'Failed to upload transfer proof during order creation: ${e.toString()}',
          );
        }
      }

      final orderDataMap = dto.toMap();

      final orderModelData = {
        'id': orderId,
        'userId': userId,
        'paymentMethodId': orderDataMap['paymentMethodId'],
        'orderType': orderDataMap['orderType'],
        'status': OrderStatus.pending.toMap(),
        'totalAmount': totalAmount,
        'paymentStatus': PaymentStatus.pending.toMap(),
        'orderDate': DateTime.now().millisecondsSinceEpoch,
        'estimatedReadyTime': orderDataMap['estimatedReadyTime'],
        'specialInstructions': orderDataMap['specialInstructions'],
        'orderItems': orderDataMap['orderItems'],
        'paymentProof': paymentProofUrl,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      batch.set(orderDocRef, orderModelData);

      if (OrderTypeExtension.fromMap(orderDataMap['orderType']) ==
              OrderType.dineIn &&
          dto.tableReservation != null) {
        final reservationsCollection = _firebaseFirestore.collection(
          _reservationsCollectionPath,
        );
        final reservationDocRef = reservationsCollection.doc();
        final reservationData = {
          'id': reservationDocRef.id,
          'userId': userId,
          'tableId': dto.tableReservation!.tableId,
          'orderId': orderId,
          'reservationTime':
              dto.tableReservation!.reservationTime.millisecondsSinceEpoch,
          'status': ReservationStatus.reserved.toMap(),
          'table': dto.tableReservation!.table?.toMap(),
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };
        batch.set(reservationDocRef, reservationData);
      }

      if (dto.orderItems.isNotEmpty) {
        final cartCollection = _firebaseFirestore.collection(
          _cartCollectionPath,
        );
        final menuItemIds =
            dto.orderItems.map((item) => item.menuItemId).toList();
        final cartQuery =
            await cartCollection
                .where('userId', isEqualTo: userId)
                .where('menuItemId', whereIn: menuItemIds)
                .get();
        for (var cartDoc in cartQuery.docs) {
          batch.delete(cartDoc.reference);
        }
      }

      await batch.commit();
      final order = OrderModel.fromMap(orderModelData);
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

  Future<Either<ErrorResponse, SuccessResponse<OrderModel>>> updateOrder(
    String id,
    UpdateOrderDto dto, {
    File? transferProofFile,
    bool deleteExistingTransferProof = false,
  }) async {
    try {
      final orderResult = await getOrderById(id);

      if (orderResult.isLeft()) {
        return Left(ErrorResponse(message: 'Order not found'));
      }

      final currentOrder = orderResult.getRight().toNullable()!.data;
      String? paymentProofUrl = currentOrder.paymentProof;

      if (deleteExistingTransferProof && paymentProofUrl != null) {
        await _deleteImageFromCloudinary(paymentProofUrl);
        paymentProofUrl = null;
      }

      if (transferProofFile != null) {
        if (paymentProofUrl != null && !deleteExistingTransferProof) {
          await _deleteImageFromCloudinary(paymentProofUrl);
        }
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: transferProofFile,
            folder: _transferProofsCloudinaryFolder,
          );
          paymentProofUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload transfer proof: ${e.toString()}');
          return Left(
            ErrorResponse(
              message: 'Failed to upload transfer proof: ${e.toString()}',
            ),
          );
        }
      }

      final updateData = dto.toMap();
      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      if (transferProofFile != null || deleteExistingTransferProof) {
        updateData['paymentProof'] = paymentProofUrl;
      }

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(updateData);

      final updatedDoc =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();
      final updatedOrder = OrderModel.fromMap(updatedDoc.data()!);

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
      final orderResult = await getOrderById(id);

      if (orderResult.isLeft()) {
        return Left(ErrorResponse(message: 'Order not found'));
      }

      final order = orderResult.getRight().toNullable()!.data;

      if (order.paymentProof != null) {
        await _deleteImageFromCloudinary(order.paymentProof);
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

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<OrderModel>>>>
  getPaginatedOrders({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    try {
      Query query = _firebaseFirestore
          .collection(_collectionPath)
          .orderBy(orderBy, descending: descending)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final orders =
          querySnapshot.docs
              .map(
                (doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      final hasMore = querySnapshot.docs.length >= limit;
      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

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

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<OrderModel>>>>
  getPaginatedUserOrders({
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

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      final orders =
          querySnapshot.docs
              .map(
                (doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();
      final hasMore = querySnapshot.docs.length >= limit;
      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: orders,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'User orders retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated user orders: ${e.toString()}',
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

      if (!querySnapshot.exists || querySnapshot.data() == null) {
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

  // * Aggregate
  Future<Either<ErrorResponse, SuccessResponse<OrdersCountAggregate>>>
  getOrdersCount() async {
    try {
      final ordersCollection = _firebaseFirestore.collection(_collectionPath);

      // Membuat daftar future untuk setiap kueri agregat
      final totalCountFuture = ordersCollection.count().get();

      final statusCountFutures =
          OrderStatus.values.map((status) {
            return ordersCollection
                .where('status', isEqualTo: status.toMap())
                .count()
                .get();
          }).toList();

      final typeCountFutures =
          OrderType.values.map((type) {
            return ordersCollection
                .where('orderType', isEqualTo: type.toMap())
                .count()
                .get();
          }).toList();

      // Menjalankan semua kueri secara paralel untuk efisiensi
      final totalSnapshot = await totalCountFuture;
      final statusSnapshots = await Future.wait(statusCountFutures);
      final typeSnapshots = await Future.wait(typeCountFutures);

      // Memproses hasil kueri
      final totalOrders = totalSnapshot.count ?? 0;

      final statusCounts = <OrderStatus, int>{};
      for (int i = 0; i < OrderStatus.values.length; i++) {
        statusCounts[OrderStatus.values[i]] = statusSnapshots[i].count ?? 0;
      }

      final typeCounts = <OrderType, int>{};
      for (int i = 0; i < OrderType.values.length; i++) {
        typeCounts[OrderType.values[i]] = typeSnapshots[i].count ?? 0;
      }

      final orderAggregate = OrdersCountAggregate(
        totalOrders: totalOrders,
        statusCounts: statusCounts,
        typeCounts: typeCounts,
      );

      return Right(
        SuccessResponse(
          data: orderAggregate,
          message: "Order aggregates retrieved successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get order counts: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<OrdersRevenueAggregate>>>
  getOrderRevenue() async {
    try {
      final ordersCollection = _firebaseFirestore.collection(_collectionPath);
      final querySnapshot = await ordersCollection.get();

      final now = DateTime.now();
      // Mendefinisikan awal dari setiap periode waktu
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfYear = DateTime(now.year, 1, 1);

      double totalRevenueAllTime = 0;
      double totalRevenueToday = 0;
      double totalRevenueThisMonth = 0;
      double totalRevenueThisYear = 0;

      // SOLUSI: Gunakan OrderModel.fromMap untuk konversi yang aman
      for (var doc in querySnapshot.docs) {
        // Ubah data mentah menjadi objek OrderModel yang sudah jelas tipenya
        final order = OrderModel.fromMap(doc.data());

        // Akses properti langsung dari objek, ini jauh lebih aman
        final double amount = order.totalAmount;
        final DateTime orderDate = order.orderDate;

        totalRevenueAllTime += amount;

        // Logika perbandingan tanggal tetap sama, tapi sekarang dengan data yang valid
        if (!orderDate.isBefore(startOfToday)) {
          totalRevenueToday += amount;
        }
        if (!orderDate.isBefore(startOfMonth)) {
          totalRevenueThisMonth += amount;
        }
        if (!orderDate.isBefore(startOfYear)) {
          totalRevenueThisYear += amount;
        }
      }

      final revenueAggregate = OrdersRevenueAggregate(
        totalRevenueAllTime: totalRevenueAllTime,
        totalRevenueToday: totalRevenueToday,
        totalRevenueThisMonth: totalRevenueThisMonth,
        totalRevenueThisYear: totalRevenueThisYear,
      );

      return Right(
        SuccessResponse(
          data: revenueAggregate,
          message: 'Order revenue retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e('Failed to get order revenue: ${e.toString()}');
      return Left(
        ErrorResponse(message: 'Failed to get order revenue: ${e.toString()}'),
      );
    }
  }
}

class OrdersCountAggregate {
  final int totalOrders;
  final Map<OrderStatus, int> statusCounts;
  final Map<OrderType, int> typeCounts;

  OrdersCountAggregate({
    required this.totalOrders,
    required this.statusCounts,
    required this.typeCounts,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalOrders': totalOrders,
      'statusCounts': statusCounts.map(
        (key, value) => MapEntry(key.toMap(), value),
      ),
      'typeCounts': typeCounts.map(
        (key, value) => MapEntry(key.toMap(), value),
      ),
    };
  }

  factory OrdersCountAggregate.fromMap(Map<String, dynamic> map) {
    return OrdersCountAggregate(
      totalOrders: map['totalOrders'] as int,
      statusCounts: (map['statusCounts'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(OrderStatusExtension.fromMap(key), value as int),
      ),
      typeCounts: (map['typeCounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(OrderTypeExtension.fromMap(key), value as int),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdersCountAggregate.fromJson(String source) =>
      OrdersCountAggregate.fromMap(json.decode(source) as Map<String, dynamic>);
}

class OrdersRevenueAggregate {
  final double totalRevenueAllTime;
  final double totalRevenueToday;
  final double totalRevenueThisMonth;
  final double totalRevenueThisYear;

  OrdersRevenueAggregate({
    required this.totalRevenueAllTime,
    required this.totalRevenueToday,
    required this.totalRevenueThisMonth,
    required this.totalRevenueThisYear,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalRevenueAllTime': totalRevenueAllTime,
      'totalRevenueToday': totalRevenueToday,
      'totalRevenueThisMonth': totalRevenueThisMonth,
      'totalRevenueThisYear': totalRevenueThisYear,
    };
  }

  factory OrdersRevenueAggregate.fromMap(Map<String, dynamic> map) {
    return OrdersRevenueAggregate(
      totalRevenueAllTime: (map['totalRevenueAllTime'] as num).toDouble(),
      totalRevenueToday: (map['totalRevenueToday'] as num).toDouble(),
      totalRevenueThisMonth: (map['totalRevenueThisMonth'] as num).toDouble(),
      totalRevenueThisYear: (map['totalRevenueThisYear'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdersRevenueAggregate.fromJson(String source) =>
      OrdersRevenueAggregate.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
