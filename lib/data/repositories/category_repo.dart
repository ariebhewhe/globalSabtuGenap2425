import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/cloudinary_service.dart';

final categoryRepoProvider = Provider.autoDispose<CategoryRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cloudinary = ref.watch(cloudinaryProvider);

  return CategoryRepo(firestore, cloudinary);
});

class CategoryRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CloudinaryService _cloudinaryService;

  final String _collectionPath = 'categories';
  final String _cloudinaryFolder = 'categories';
  final AppLogger logger = AppLogger();

  CategoryRepo(this._firebaseFirestore, this._cloudinaryService);

  Future<Either<ErrorResponse, SuccessResponse<CategoryModel>>> addCategory(
    CategoryModel newCategory, {
    File? imageFile,
  }) async {
    try {
      final categoriesCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = categoriesCollection.doc();

      String? picture = newCategory.picture;

      if (imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: _cloudinaryFolder,
          );

          picture = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final categoryWithId = newCategory.copyWith(
        id: docRef.id,
        picture: picture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(categoryWithId.toMap());

      return Right(
        SuccessResponse(data: categoryWithId, message: 'New categorie added'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new menu ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<CategoryModel>>>>
  getAllCategory() async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).get();

      final categories =
          querySnapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: categories));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get all categories ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<CategoryModel>>>>
  getPaginatedCategories({
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
      final categories =
          querySnapshot.docs
              .map(
                (doc) =>
                    CategoryModel.fromMap(doc.data() as Map<String, dynamic>),
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
            items: categories,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'categories retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated categories: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<CategoryModel>>> getCategoryById(
    String id,
  ) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "Category not found"));
      }

      final category = CategoryModel.fromMap(querySnapshot.data()!);

      return Right(SuccessResponse(data: category));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get categorie"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<CategoryModel>>> updateCategory(
    String id,
    CategoryModel updatedCategory, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    try {
      final categoryResult = await getCategoryById(id);
      if (categoryResult.isLeft()) {
        return Left(ErrorResponse(message: 'Category not found'));
      }

      final existingCategory = categoryResult.getRight().toNullable()!.data;
      String? picture = updatedCategory.picture ?? existingCategory.picture;

      // * Hapus gambar yang ada di Cloudinary jika diminta
      if (deleteExistingImage && existingCategory.picture != null) {
        try {
          // * Ekstrak public ID dari URL gambar yang ada
          final existingImageUrl = existingCategory.picture!;
          final uri = Uri.parse(existingImageUrl);
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
            picture = null;
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

          picture = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final categoryWithUpdatedTimestamp = updatedCategory.copyWith(
        picture: picture,
        updatedAt: DateTime.now(),
      );

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(categoryWithUpdatedTimestamp.toMap());

      return Right(
        SuccessResponse(
          data: categoryWithUpdatedTimestamp,
          message: "Category updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update menu ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteCategory(
    String id, {
    bool deleteImage = true,
  }) async {
    try {
      final categoryResult = await getCategoryById(id);
      if (categoryResult.isLeft()) {
        return Left(ErrorResponse(message: 'Category not found'));
      }

      final category = categoryResult.getRight().toNullable()!.data;

      // * Hapus gambar dari Cloudinary jika ada dan diminta
      if (deleteImage && category.picture != null) {
        try {
          // * Ekstrak public ID dari URL gambar
          final picture = category.picture!;
          final uri = Uri.parse(picture);
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

      return Right(SuccessResponse(data: id, message: "Category deleted"));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete menu ${e.toString()}'),
      );
    }
  }
}
