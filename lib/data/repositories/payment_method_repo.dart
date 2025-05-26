import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/cloudinary_service.dart';

final paymentMethodRepoProvider = Provider.autoDispose<PaymentMethodRepo>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cloudinary = ref.watch(cloudinaryProvider);

  return PaymentMethodRepo(firestore, cloudinary);
});

class PaymentMethodRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CloudinaryService _cloudinaryService;

  final String _collectionPath = 'paymentMethods';
  final String _cloudinaryFolder = 'payment_methods';
  final AppLogger logger = AppLogger();

  PaymentMethodRepo(this._firebaseFirestore, this._cloudinaryService);

  Future<Either<ErrorResponse, SuccessResponse<PaymentMethodModel>>>
  addPaymentMethod(
    PaymentMethodModel newPaymentMethod, {
    File? imageFile,
  }) async {
    try {
      final paymentMethodsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = paymentMethodsCollection.doc();

      String? logo = newPaymentMethod.logo;

      if (imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: _cloudinaryFolder,
          );

          logo = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final paymentMethodWithId = newPaymentMethod.copyWith(
        id: docRef.id,
        logo: logo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(paymentMethodWithId.toMap());

      return Right(
        SuccessResponse(
          data: paymentMethodWithId,
          message: 'New payment method item added',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to add new payment method ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<PaymentMethodModel>>>>
  getAllPaymentMethod() async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).get();

      final paymentMethods =
          querySnapshot.docs
              .map((doc) => PaymentMethodModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: paymentMethods));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get all payment method items ${e.toString()}',
        ),
      );
    }
  }

  Future<
    Either<ErrorResponse, SuccessResponse<PaginatedResult<PaymentMethodModel>>>
  >
  getPaginatedPaymentMethods({
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
      final paymentMethods =
          querySnapshot.docs
              .map(
                (doc) => PaymentMethodModel.fromMap(
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
            items: paymentMethods,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Payment methods retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message:
              'Failed to get paginated payment method items: ${e.toString()}',
        ),
      );
    }
  }

  Future<
    Either<ErrorResponse, SuccessResponse<PaginatedResult<PaymentMethodModel>>>
  >
  searchPaymentMethods({
    String searchBy = "name",
    String? searchQuery,
    Object? isEqualTo,
    int limit = 10,
    DocumentSnapshot? startAfter,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    try {
      Query query = _firebaseFirestore.collection(_collectionPath);

      if (isEqualTo != null) {
        query = query.where(searchBy, isEqualTo: isEqualTo);
      }

      query = query.orderBy(orderBy, descending: descending).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final paymentMethods =
          querySnapshot.docs
              .map(
                (doc) => PaymentMethodModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();

        paymentMethods.retainWhere((paymentMethod) {
          switch (searchBy) {
            case 'name':
              return paymentMethod.name.toLowerCase().contains(lowercaseQuery);
            default:
              return false;
          }
        });
      }

      final hasMore = querySnapshot.docs.length >= limit;

      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: paymentMethods,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'PaymentMethods retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to search paymentMethods: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaymentMethodModel>>>
  getPaymentMethodById(String id) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "Payment method not found"));
      }

      final paymentMethod = PaymentMethodModel.fromMap(querySnapshot.data()!);

      return Right(SuccessResponse(data: paymentMethod));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get payment method item"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaymentMethodModel>>>
  updatePaymentMethod(
    String id,
    PaymentMethodModel updatedPaymentMethod, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    try {
      final paymentMethodResult = await getPaymentMethodById(id);
      if (paymentMethodResult.isLeft()) {
        return Left(ErrorResponse(message: 'Payment method not found'));
      }

      final existingPaymentMethod =
          paymentMethodResult.getRight().toNullable()!.data;
      String? logo = updatedPaymentMethod.logo ?? existingPaymentMethod.logo;

      // * Hapus gambar yang ada di Cloudinary jika diminta
      if (deleteExistingImage && existingPaymentMethod.logo != null) {
        try {
          // * Ekstrak public ID dari URL gambar yang ada
          final existingImageUrl = existingPaymentMethod.logo!;
          final uri = Uri.parse(existingImageUrl);
          final pathSegments = uri.pathSegments;

          // * Format: https:// *res.cloudinary.com/{cloud_name}/image/upload/{transformations}/{public_id}.{format}
          // * Cari indeks "upload" dalam path
          final uploadIndex = pathSegments.indexOf('upload');
          if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
            // * Ambil semua segment setelah "upload", kecuali ekstensi file terakhir
            final segments = pathSegments.sublist(uploadIndex + 1);

            // * Gabungkan segments untuk mendapatkan public ID dengan folder
            String fullPath = segments.join('/');

            // * Hilangkan ekstensi file (misal .jpg, .png)
            final lastDotIndex = fullPath.lastIndexOf('.');
            if (lastDotIndex != -1) {
              fullPath = fullPath.substring(0, lastDotIndex);
            }

            await _cloudinaryService.deleteImage(fullPath);
            logo = null;
          }
        } catch (e) {
          logger.e('Failed to delete existing image: ${e.toString()}');
        }
      }

      if (imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: _cloudinaryFolder,
          );

          logo = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final paymentMethodWithUpdatedTimestamp = updatedPaymentMethod.copyWith(
        logo: logo,
        updatedAt: DateTime.now(),
      );

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(paymentMethodWithUpdatedTimestamp.toMap());

      return Right(
        SuccessResponse(
          data: paymentMethodWithUpdatedTimestamp,
          message: "Payment method updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to update payment method ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deletePaymentMethod(
    String id, {
    bool deleteImage = true,
  }) async {
    try {
      final paymentMethodResult = await getPaymentMethodById(id);
      if (paymentMethodResult.isLeft()) {
        return Left(ErrorResponse(message: 'Payment method not found'));
      }

      final paymentMethod = paymentMethodResult.getRight().toNullable()!.data;

      // * Hapus gambar dari Cloudinary jika ada dan diminta
      if (deleteImage && paymentMethod.logo != null) {
        try {
          // * Ekstrak public ID dari URL gambar
          final logo = paymentMethod.logo!;
          final uri = Uri.parse(logo);
          final pathSegments = uri.pathSegments;

          // * Cari indeks "upload" dalam path
          final uploadIndex = pathSegments.indexOf('upload');
          if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
            // * Ambil semua segment setelah "upload", kecuali ekstensi file terakhir
            final segments = pathSegments.sublist(uploadIndex + 1);

            // * Gabungkan segments untuk mendapatkan public ID dengan folder
            String fullPath = segments.join('/');

            // * Hilangkan ekstensi file (misal .jpg, .png)
            final lastDotIndex = fullPath.lastIndexOf('.');
            if (lastDotIndex != -1) {
              fullPath = fullPath.substring(0, lastDotIndex);
            }

            await _cloudinaryService.deleteImage(fullPath);
          }
        } catch (e) {
          logger.e('Failed to delete image: ${e.toString()}');
        }
      }

      await _firebaseFirestore.collection(_collectionPath).doc(id).delete();

      return Right(
        SuccessResponse(data: id, message: "Payment method deleted"),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to delete payment method ${e.toString()}',
        ),
      );
    }
  }
}
