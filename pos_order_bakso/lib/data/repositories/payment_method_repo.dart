import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/data/seeders/payment_method_seeder.dart';
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

  String? _getPublicIdFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        final segments = pathSegments.sublist(uploadIndex + 2); // Skip version
        String fullPath = segments.join('/');
        final lastDotIndex = fullPath.lastIndexOf('.');
        if (lastDotIndex != -1) {
          return fullPath.substring(0, lastDotIndex);
        }
        return fullPath;
      }
      return null;
    } catch (e) {
      logger.w('Failed to parse public ID from URL: $imageUrl');
      return null;
    }
  }

  Future<void> _deleteImageByUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    final publicId = _getPublicIdFromUrl(imageUrl);
    if (publicId != null) {
      try {
        await _cloudinaryService.deleteImage(publicId);
      } catch (e) {
        logger.e(
          'Failed to delete image ($publicId) from Cloudinary: ${e.toString()}',
        );
      }
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaymentMethodModel>>>
  addPaymentMethod(CreatePaymentMethodDto dto) async {
    try {
      final paymentMethodsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = paymentMethodsCollection.doc();

      String? logoUrl;
      if (dto.logoFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.logoFile!,
            folder: _cloudinaryFolder,
          );
          logoUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload logo image: ${e.toString()}');
          return Left(
            ErrorResponse(
              message: 'Failed to upload logo image: ${e.toString()}',
            ),
          );
        }
      }

      String? adminQrCodeUrl;
      if (dto.adminPaymentQrCodeFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.adminPaymentQrCodeFile!,
            folder: _cloudinaryFolder,
          );
          adminQrCodeUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload admin QR code image: ${e.toString()}');
          return Left(
            ErrorResponse(
              message: 'Failed to upload admin QR code image: ${e.toString()}',
            ),
          );
        }
      }

      final paymentMethodData = dto.toMap();
      paymentMethodData['id'] = docRef.id;
      paymentMethodData['logo'] = logoUrl;
      paymentMethodData['adminPaymentQrCodePicture'] = adminQrCodeUrl;
      paymentMethodData['createdAt'] = DateTime.now().toUtc().toIso8601String();
      paymentMethodData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      await docRef.set(paymentMethodData);

      final paymentMethod = PaymentMethodModel.fromMap(paymentMethodData);

      return Right(
        SuccessResponse(
          data: paymentMethod,
          message: 'New payment method added',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to add new payment method: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>> batchAddPaymentMethods(
    List<CreatePaymentMethodDto> dtos,
  ) async {
    if (dtos.isEmpty) {
      return Right(
        SuccessResponse(data: null, message: 'No payment methods to add.'),
      );
    }

    try {
      final batch = _firebaseFirestore.batch();
      final collectionRef = _firebaseFirestore.collection(_collectionPath);
      final now = DateTime.now().toUtc().toIso8601String();

      for (final dto in dtos) {
        // Batch add does not support image file uploads. 'logo' and 'adminPaymentQrCodePicture' must be URLs if needed.
        final docRef = collectionRef.doc();
        final Map<String, dynamic> data = dto.toMap();

        data['id'] = docRef.id;
        data['createdAt'] = now;
        data['updatedAt'] = now;

        batch.set(docRef, data);
      }

      await batch.commit();
      logger.i('${dtos.length} payment methods successfully added in batch.');
      return Right(
        SuccessResponse(
          data: null,
          message:
              '${dtos.length} payment methods added successfully in batch.',
        ),
      );
    } catch (e) {
      logger.e('Failed to batch add payment methods: ${e.toString()}');
      return Left(
        ErrorResponse(
          message: 'Failed to batch add payment methods: ${e.toString()}',
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
          message: 'Payment methods retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated payment methods: ${e.toString()}',
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

      List<PaymentMethodModel> paymentMethods =
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
          message: 'Payment Methods retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to search payment methods: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaymentMethodModel>>>
  getPaymentMethodById(String id) async {
    try {
      final docSnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: "Payment method not found"));
      }

      final paymentMethod = PaymentMethodModel.fromMap(docSnapshot.data()!);

      return Right(SuccessResponse(data: paymentMethod));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get payment method"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaymentMethodModel>>>
  updatePaymentMethod(
    String id,
    UpdatePaymentMethodDto dto, {
    bool deleteExistingLogo = false, // Rename for clarity
    bool deleteExistingQrCode = false, // New parameter for QR code
  }) async {
    try {
      final paymentMethodResult = await getPaymentMethodById(id);
      if (paymentMethodResult.isLeft()) {
        return Left(ErrorResponse(message: 'Payment method not found'));
      }

      final existingPaymentMethod =
          paymentMethodResult.getRight().toNullable()!.data;
      final updateData = dto.toMap();

      String? finalLogoUrl = existingPaymentMethod.logo;
      String? finalAdminQrCodeUrl =
          existingPaymentMethod.adminPaymentQrCodePicture;

      // Handle logo deletion and upload
      if (deleteExistingLogo && existingPaymentMethod.logo != null) {
        await _deleteImageByUrl(existingPaymentMethod.logo);
        finalLogoUrl = null;
      }
      if (dto.logoFile != null) {
        if (finalLogoUrl != null && !deleteExistingLogo) {
          await _deleteImageByUrl(finalLogoUrl);
        }
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.logoFile!,
            folder: _cloudinaryFolder,
          );
          finalLogoUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload new logo image: ${e.toString()}');
          return Left(
            ErrorResponse(
              message: 'Failed to upload new logo image: ${e.toString()}',
            ),
          );
        }
      }

      // Handle admin QR code deletion and upload
      if (deleteExistingQrCode &&
          existingPaymentMethod.adminPaymentQrCodePicture != null) {
        await _deleteImageByUrl(
          existingPaymentMethod.adminPaymentQrCodePicture,
        );
        finalAdminQrCodeUrl = null;
      }
      if (dto.adminPaymentQrCodeFile != null) {
        if (finalAdminQrCodeUrl != null && !deleteExistingQrCode) {
          await _deleteImageByUrl(finalAdminQrCodeUrl);
        }
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.adminPaymentQrCodeFile!,
            folder: _cloudinaryFolder,
          );
          finalAdminQrCodeUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload new admin QR code image: ${e.toString()}');
          return Left(
            ErrorResponse(
              message:
                  'Failed to upload new admin QR code image: ${e.toString()}',
            ),
          );
        }
      }

      updateData['logo'] = finalLogoUrl;
      updateData['adminPaymentQrCodePicture'] = finalAdminQrCodeUrl;
      updateData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      final docRef = _firebaseFirestore.collection(_collectionPath).doc(id);
      await docRef.update(updateData);

      final updatedDocSnapshot = await docRef.get();
      final updatedPaymentMethod = PaymentMethodModel.fromMap(
        updatedDocSnapshot.data()!,
      );

      return Right(
        SuccessResponse(
          data: updatedPaymentMethod,
          message: "Payment method updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to update payment method: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deletePaymentMethod(
    String id, {
    bool deleteImages = true, // Unified parameter for all images
  }) async {
    try {
      final docRef = _firebaseFirestore.collection(_collectionPath).doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: 'Payment method not found'));
      }

      if (deleteImages) {
        final logoUrl = docSnapshot.data()?['logo'] as String?;
        final qrCodeUrl =
            docSnapshot.data()?['adminPaymentQrCodePicture'] as String?;
        await _deleteImageByUrl(logoUrl);
        await _deleteImageByUrl(qrCodeUrl);
      }

      await docRef.delete();

      return Right(
        SuccessResponse(data: id, message: "Payment method deleted"),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to delete payment method: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>>
  batchDeletePaymentMethods(
    List<String> ids, {
    bool deleteImages = true,
  }) async {
    if (ids.isEmpty) {
      return Right(SuccessResponse(data: null, message: 'No items to delete.'));
    }

    try {
      final collectionRef = _firebaseFirestore.collection(_collectionPath);
      final paymentMethodsSnapshot =
          await collectionRef.where(FieldPath.documentId, whereIn: ids).get();

      if (paymentMethodsSnapshot.docs.isEmpty) {
        return Left(
          ErrorResponse(message: 'No matching payment methods found.'),
        );
      }

      if (deleteImages) {
        final List<String> imageUrlsToDelete = [];
        for (final doc in paymentMethodsSnapshot.docs) {
          final logoUrl = doc.data()['logo'] as String?;
          final qrCodeUrl = doc.data()['adminPaymentQrCodePicture'] as String?;
          if (logoUrl != null && logoUrl.isNotEmpty) {
            imageUrlsToDelete.add(logoUrl);
          }
          if (qrCodeUrl != null && qrCodeUrl.isNotEmpty) {
            imageUrlsToDelete.add(qrCodeUrl);
          }
        }

        if (imageUrlsToDelete.isNotEmpty) {
          await Future.wait(
            imageUrlsToDelete.map((url) => _deleteImageByUrl(url)),
          );
        }
      }

      final batch = _firebaseFirestore.batch();
      for (final doc in paymentMethodsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      final deletedCount = paymentMethodsSnapshot.docs.length;
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
          message: 'Failed to batch delete payment methods: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>>
  deleteAllPaymentMethods() async {
    try {
      final collectionRef = _firebaseFirestore.collection(_collectionPath);
      final allDocsSnapshot = await collectionRef.limit(500).get();

      if (allDocsSnapshot.docs.isEmpty) {
        logger.i('No payment methods to delete.');
        return Right(
          SuccessResponse(data: null, message: 'No items to delete.'),
        );
      }

      final List<String> imageUrlsToDelete = [];
      for (final doc in allDocsSnapshot.docs) {
        final data = doc.data();
        final logoUrl = data['logo'] as String?;
        final qrCodeUrl = data['adminPaymentQrCodePicture'] as String?;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          imageUrlsToDelete.add(logoUrl);
        }
        if (qrCodeUrl != null && qrCodeUrl.isNotEmpty) {
          imageUrlsToDelete.add(qrCodeUrl);
        }
      }

      if (imageUrlsToDelete.isNotEmpty) {
        logger.i(
          'Deleting ${imageUrlsToDelete.length} images from Cloudinary...',
        );
        await Future.wait(
          imageUrlsToDelete.map((url) => _deleteImageByUrl(url)),
        );
        logger.i('Cloudinary images deleted.');
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
        return deleteAllPaymentMethods();
      }

      logger.i('All payment methods have been deleted successfully.');
      return Right(
        SuccessResponse(
          data: null,
          message: 'All payment methods deleted successfully.',
        ),
      );
    } catch (e) {
      logger.e('Failed to delete all payment methods: ${e.toString()}');
      return Left(
        ErrorResponse(
          message: 'Failed to delete all payment methods: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>>
  seedPaymentMethods() async {
    try {
      logger.i('Seeding process started. First, deleting all existing data...');
      final deleteResult = await deleteAllPaymentMethods();
      if (deleteResult.isLeft()) {
        logger.e('Failed to clear existing data before seeding.');
        return Left(
          ErrorResponse(
            message: 'Failed to clear existing data before seeding.',
          ),
        );
      }
      logger.i('Existing data cleared successfully.');

      final seedData = paymentMethodSeeder;

      if (seedData.isEmpty) {
        logger.w("Seed data is empty. No new payment methods will be added.");
        return Right(
          SuccessResponse(data: null, message: 'Seed data was empty.'),
        );
      }

      logger.i('Starting to seed ${seedData.length} new payment methods...');
      final batch = _firebaseFirestore.batch();
      final collectionRef = _firebaseFirestore.collection(_collectionPath);

      for (final jsonData in seedData) {
        final docRef = collectionRef.doc();
        jsonData['id'] = docRef.id; // Firestore-generated ID
        batch.set(docRef, jsonData);
      }

      await batch.commit();

      logger.i('Successfully seeded ${seedData.length} payment methods.');
      return Right(
        SuccessResponse(
          data: null,
          message: 'Successfully seeded ${seedData.length} payment methods.',
        ),
      );
    } catch (e) {
      logger.e('Failed to seed payment methods: ${e.toString()}');
      return Left(
        ErrorResponse(
          message: 'Failed to seed payment methods: ${e.toString()}',
        ),
      );
    }
  }
}
