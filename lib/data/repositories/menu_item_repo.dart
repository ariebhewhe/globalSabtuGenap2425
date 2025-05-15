import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/cloudinary_service.dart';

final menuItemRepoProvider = Provider.autoDispose<MenuItemRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cloudinary = ref.watch(cloudinaryProvider);

  return MenuItemRepo(firestore, cloudinary);
});

class MenuItemRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CloudinaryService _cloudinaryService;

  final String _collectionPath = 'menuItems';
  final String _cloudinaryFolder = 'menu_items';
  final AppLogger logger = AppLogger();

  MenuItemRepo(this._firebaseFirestore, this._cloudinaryService);

  Future<Either<ErrorResponse, SuccessResponse<MenuItemModel>>> addMenuItem(
    MenuItemModel newMenuItem, {
    File? imageFile,
  }) async {
    try {
      final menuItemsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = menuItemsCollection.doc();

      String? imageUrl = newMenuItem.imageUrl;

      if (imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: _cloudinaryFolder,
          );

          imageUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final menuItemWithId = newMenuItem.copyWith(
        id: docRef.id,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(menuItemWithId.toMap());

      return Right(
        SuccessResponse(data: menuItemWithId, message: 'New menu item added'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new menu ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<MenuItemModel>>>>
  getAllMenuItem() async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).get();

      final menuItems =
          querySnapshot.docs
              .map((doc) => MenuItemModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: menuItems));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get all menu items ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<MenuItemModel>>>>
  getPaginatedMenuItems({
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
      final menuItems =
          querySnapshot.docs
              .map(
                (doc) =>
                    MenuItemModel.fromMap(doc.data() as Map<String, dynamic>),
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
            items: menuItems,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Menu items retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated menu items: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<MenuItemModel>>> getMenuItemById(
    String id,
  ) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "Menu item not found"));
      }

      final menuItem = MenuItemModel.fromMap(querySnapshot.data()!);

      return Right(SuccessResponse(data: menuItem));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get menu item"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<MenuItemModel>>> updateMenuItem(
    String id,
    MenuItemModel updatedMenuItem, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    try {
      final menuItemResult = await getMenuItemById(id);
      if (menuItemResult.isLeft()) {
        return Left(ErrorResponse(message: 'Menu item not found'));
      }

      final existingMenuItem = menuItemResult.getRight().toNullable()!.data;
      String? imageUrl = updatedMenuItem.imageUrl ?? existingMenuItem.imageUrl;

      // * Hapus gambar yang ada di Cloudinary jika diminta
      if (deleteExistingImage && existingMenuItem.imageUrl != null) {
        try {
          // * Ekstrak public ID dari URL gambar yang ada
          final existingImageUrl = existingMenuItem.imageUrl!;
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
            imageUrl = null;
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

          imageUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final menuItemWithUpdatedTimestamp = updatedMenuItem.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(menuItemWithUpdatedTimestamp.toMap());

      return Right(
        SuccessResponse(
          data: menuItemWithUpdatedTimestamp,
          message: "Menu item updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update menu ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteMenuItem(
    String id, {
    bool deleteImage = true,
  }) async {
    try {
      final menuItemResult = await getMenuItemById(id);
      if (menuItemResult.isLeft()) {
        return Left(ErrorResponse(message: 'Menu item not found'));
      }

      final menuItem = menuItemResult.getRight().toNullable()!.data;

      // * Hapus gambar dari Cloudinary jika ada dan diminta
      if (deleteImage && menuItem.imageUrl != null) {
        try {
          // * Ekstrak public ID dari URL gambar
          final imageUrl = menuItem.imageUrl!;
          final uri = Uri.parse(imageUrl);
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

      return Right(SuccessResponse(data: id, message: "Menu item deleted"));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete menu ${e.toString()}'),
      );
    }
  }
}
