import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';

final restaurantTableRepoProvider = Provider.autoDispose<RestaurantTableRepo>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);

  return RestaurantTableRepo(firestore);
});

class RestaurantTableRepo {
  final FirebaseFirestore _firebaseFirestore;

  final String _collectionPath = 'restaurantTables';
  final AppLogger logger = AppLogger();

  RestaurantTableRepo(this._firebaseFirestore);

  Future<Either<ErrorResponse, SuccessResponse<RestaurantTableModel>>>
  addRestaurantTable(CreateRestaurantTableDto dto) async {
    try {
      final restaurantTablesCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = restaurantTablesCollection.doc();

      final restaurantTableData = dto.toMap();

      restaurantTableData['id'] = docRef.id;
      restaurantTableData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      restaurantTableData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await docRef.set(restaurantTableData);

      final restaurantTable = RestaurantTableModel.fromMap(restaurantTableData);

      return Right(
        SuccessResponse(
          data: restaurantTable,
          message: 'New restaurant table added',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new cart ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<RestaurantTableModel>>>>
  getAllRestaurantTable() async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).get();

      final restaurantTables =
          querySnapshot.docs
              .map((doc) => RestaurantTableModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: restaurantTables));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get all restaurant tables ${e.toString()}',
        ),
      );
    }
  }

  Future<
    Either<
      ErrorResponse,
      SuccessResponse<PaginatedResult<RestaurantTableModel>>
    >
  >
  getPaginatedRestaurantTables({
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

      // * Tambahkan startAfter jika disediakan (untuk load more)
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      // * Konversi hasil query menjadi model
      final restaurantTables =
          querySnapshot.docs
              .map(
                (doc) => RestaurantTableModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      // * Cek apakah masih ada data lagi yang bisa dimuat
      final hasMore = querySnapshot.docs.length >= limit;

      // * Simpan dokumen terakhir untuk digunakan sebagai startAfter pada request berikutnya
      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      // * Kembalikan hasil dengan metadata pagination
      print(restaurantTables);
      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: restaurantTables,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Restaurant tables retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated restaurant tables: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<RestaurantTableModel>>>
  getRestaurantTableById(String id) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "Restaurant table not found"));
      }

      final restaurantTable = RestaurantTableModel.fromMap(
        querySnapshot.data()!,
      );

      return Right(SuccessResponse(data: restaurantTable));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get restaurant table"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<RestaurantTableModel>>>
  updateRestaurantTable(String id, UpdateRestaurantTableDto dto) async {
    try {
      final restaurantTableResult = await getRestaurantTableById(id);

      if (restaurantTableResult.isLeft()) {
        return Left(ErrorResponse(message: 'Restaurant table not found'));
      }

      final currentRestaurantTable =
          restaurantTableResult.getRight().toNullable()!.data;

      final updateData = dto.toMap();

      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(updateData);

      final updatedRestaurantTable = currentRestaurantTable.copyWith(
        updatedAt: DateTime.now(),
      );

      return Right(
        SuccessResponse(
          data: updatedRestaurantTable,
          message: "Restaurant table updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update cart ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteRestaurantTable(
    String id,
  ) async {
    try {
      final restaurantTableResult = await getRestaurantTableById(id);

      if (restaurantTableResult.isLeft()) {
        return Left(ErrorResponse(message: 'Restaurant table not found'));
      }

      await _firebaseFirestore.collection(_collectionPath).doc(id).delete();

      return Right(
        SuccessResponse(data: id, message: "Restaurant table deleted"),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete cart ${e.toString()}'),
      );
    }
  }
}
