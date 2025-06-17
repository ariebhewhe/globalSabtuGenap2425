import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

final tableReservationRepoProvider = Provider.autoDispose<TableReservationRepo>(
  (ref) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final currentUserService = ref.watch(currentUserStorageServiceProvider);

    return TableReservationRepo(firestore, currentUserService);
  },
);

class TableReservationRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CurrentUserStorageService _currentUserStorageService;

  final String _collectionPath = 'tableReservations';
  final AppLogger logger = AppLogger();

  TableReservationRepo(
    this._firebaseFirestore,
    this._currentUserStorageService,
  );

  Future<
    Either<
      ErrorResponse,
      SuccessResponse<PaginatedResult<TableReservationModel>>
    >
  >
  getPaginatedTableReservations({
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
      final tableReservations =
          querySnapshot.docs
              .map(
                (doc) => TableReservationModel.fromMap(
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
      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: tableReservations,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'TableReservations retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated tableReservations: ${e.toString()}',
        ),
      );
    }
  }

  Future<
    Either<
      ErrorResponse,
      SuccessResponse<PaginatedResult<TableReservationModel>>
    >
  >
  getPaginatedUserTableReservations({
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
      final tableReservations =
          querySnapshot.docs
              .map(
                (doc) => TableReservationModel.fromMap(
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
      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: tableReservations,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'TableReservations retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated tableReservations: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<TableReservationModel>>>
  getTableReservationById(String id) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "TableReservation not found"));
      }

      final tableReservation = TableReservationModel.fromMap(
        querySnapshot.data()!,
      );

      return Right(
        SuccessResponse(
          data: tableReservation,
          message: 'TableReservation retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: "Failed to get tableReservation: ${e.toString()}",
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<TableReservationModel>>>
  updateTableReservation(String id, UpdateTableReservationDto dto) async {
    try {
      final userId = await _getCurrentUserId();
      final tableReservationResult = await getTableReservationById(id);

      if (tableReservationResult.isLeft()) {
        return Left(ErrorResponse(message: 'TableReservation not found'));
      }

      final currentTableReservation =
          tableReservationResult.getRight().toNullable()!.data;

      // if (currentTableReservation.userId != userId) {
      //   return Left(
      //     ErrorResponse(
      //       message: 'Unauthorized to update this tableReservation',
      //     ),
      //   );
      // }

      final updateData = dto.toMap();

      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(updateData);

      final updatedTableReservation = currentTableReservation.copyWith(
        status: dto.status,
        updatedAt: DateTime.now(),
      );

      return Right(
        SuccessResponse(
          data: updatedTableReservation,
          message: "TableReservation updated successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to update tableReservation: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteTableReservation(
    String id,
  ) async {
    try {
      final userId = await _getCurrentUserId();

      final tableReservationResult = await getTableReservationById(id);

      if (tableReservationResult.isLeft()) {
        return Left(ErrorResponse(message: 'TableReservation not found'));
      }

      final tableReservation =
          tableReservationResult.getRight().toNullable()!.data;

      if (tableReservation.userId != userId) {
        return Left(
          ErrorResponse(
            message: 'Unauthorized to delete this tableReservation',
          ),
        );
      }

      await _firebaseFirestore.collection(_collectionPath).doc(id).delete();

      return Right(
        SuccessResponse(
          data: id,
          message: "TableReservation deleted successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to delete tableReservation: ${e.toString()}',
        ),
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

  Future<Either<ErrorResponse, SuccessResponse<void>>>
  batchDeleteTableReservations(List<String> ids) async {
    if (ids.isEmpty) {
      return Right(SuccessResponse(data: null, message: 'No items to delete.'));
    }

    try {
      final collectionRef = _firebaseFirestore.collection(_collectionPath);
      final tableReservationsSnapshot =
          await collectionRef.where(FieldPath.documentId, whereIn: ids).get();

      if (tableReservationsSnapshot.docs.isEmpty) {
        return Left(
          ErrorResponse(message: 'No matching tableReservations found.'),
        );
      }

      final batch = _firebaseFirestore.batch();
      for (final doc in tableReservationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      final deletedCount = tableReservationsSnapshot.docs.length;
      logger.i('$deletedCount payment method(s) deleted.');

      return Right(
        SuccessResponse(
          data: null,
          message: '$deletedCount payment method(s) deleted successfully.',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to batch delete tableReservations: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>>
  deleteAllTableReservations() async {
    try {
      final collectionRef = _firebaseFirestore.collection(_collectionPath);
      final allDocsSnapshot = await collectionRef.limit(500).get();

      if (allDocsSnapshot.docs.isEmpty) {
        logger.i('No tableReservations to delete.');
        return Right(
          SuccessResponse(data: null, message: 'No items to delete.'),
        );
      }

      logger.i(
        'Deleting ${allDocsSnapshot.docs.length} documents from Firestore...',
      );

      final batch = _firebaseFirestore.batch();

      for (final doc in allDocsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (allDocsSnapshot.docs.length >= 500) {
        return deleteAllTableReservations();
      }

      logger.i('All tableReservations have been deleted successfully.');
      return Right(
        SuccessResponse(
          data: null,
          message: 'All tableReservations deleted successfully.',
        ),
      );
    } catch (e) {
      logger.e('Failed to delete all tableReservations: ${e.toString()}');
      return Left(
        ErrorResponse(
          message: 'Failed to delete all tableReservations: ${e.toString()}',
        ),
      );
    }
  }
}
