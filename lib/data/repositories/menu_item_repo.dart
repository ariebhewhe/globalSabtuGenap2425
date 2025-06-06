// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

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
    CreateMenuItemDto dto,
  ) async {
    try {
      final menuItemsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = menuItemsCollection.doc();

      String? imageUrl;

      if (dto.imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.imageFile!,
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

      final menuItemData = dto.toMap();

      menuItemData['id'] = docRef.id;
      if (imageUrl != null) {
        menuItemData['imageUrl'] = imageUrl;
      }
      menuItemData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      menuItemData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await docRef.set(menuItemData);

      final menuItem = MenuItemModel.fromMap(menuItemData);

      return Right(
        SuccessResponse(data: menuItem, message: 'New menu item added'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new menu ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<Null>>> batchAddMenuItems(
    List<CreateMenuItemDto> dtos,
  ) async {
    if (dtos.isEmpty) {
      return Right(
        SuccessResponse(data: null, message: 'No menu items to add.'),
      );
    }

    try {
      final batch = _firebaseFirestore.batch();
      final menuItemsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final dto in dtos) {
        final docRef = menuItemsCollection.doc();
        final Map<String, dynamic> menuItemData = dto.toMap();

        menuItemData['id'] = docRef.id;
        menuItemData['createdAt'] = now;
        menuItemData['updatedAt'] = now;

        batch.set(docRef, menuItemData);
      }

      await batch.commit();
      logger.i('${dtos.length} menu items successfully added in batch.');
      return Right(
        SuccessResponse(
          data: null,
          message: '${dtos.length} menu items added successfully in batch.',
        ),
      );
    } catch (e) {
      logger.e('Failed to batch add menu items: ${e.toString()}');
      return Left(
        ErrorResponse(
          message: 'Failed to batch add menu items: ${e.toString()}',
        ),
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

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final menuItems =
          querySnapshot.docs
              .map(
                (doc) =>
                    MenuItemModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      final hasMore = querySnapshot.docs.length >= limit;

      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

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

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<MenuItemModel>>>>
  searchMenuItems({
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

      final menuItems =
          querySnapshot.docs
              .map(
                (doc) =>
                    MenuItemModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();

        menuItems.retainWhere((menuItem) {
          switch (searchBy) {
            case 'name':
              return menuItem.name.toLowerCase().contains(lowercaseQuery);
            case 'description':
              return menuItem.description.toLowerCase().contains(
                lowercaseQuery,
              );
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
            items: menuItems,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'MenuItems retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to search menuItems: ${e.toString()}'),
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
    UpdateMenuItemDto dto, {
    bool deleteExistingImage = false,
  }) async {
    try {
      final menuItemResult = await getMenuItemById(id);
      if (menuItemResult.isLeft()) {
        return Left(ErrorResponse(message: 'Menu item not found'));
      }

      final existingMenuItem = menuItemResult.getRight().toNullable()!.data;
      final updateData = dto.toMap();
      String? finalImageUrl = existingMenuItem.imageUrl;

      if (deleteExistingImage && existingMenuItem.imageUrl != null) {
        try {
          final existingImageUrl = existingMenuItem.imageUrl!;
          final uri = Uri.parse(existingImageUrl);
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
            finalImageUrl = null;
          }
        } catch (e) {
          logger.e('Failed to delete existing image: ${e.toString()}');
        }
      }

      if (dto.imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.imageFile!,
            folder: _cloudinaryFolder,
          );

          finalImageUrl = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload new image: ${e.toString()}');
          return Left(
            ErrorResponse(
              message: 'Failed to upload new image: ${e.toString()}',
            ),
          );
        }
      }

      if (finalImageUrl != null) {
        updateData['imageUrl'] = finalImageUrl;
      } else if (deleteExistingImage || dto.imageFile != null) {
        updateData['imageUrl'] = null;
      }

      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(updateData);

      final updatedDocSnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();
      final updatedMenuItem = MenuItemModel.fromMap(updatedDocSnapshot.data()!);

      return Right(
        SuccessResponse(data: updatedMenuItem, message: "Menu item updated"),
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

      if (deleteImage && menuItem.imageUrl != null) {
        try {
          final imageUrl = menuItem.imageUrl!;
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

  // * Aggregate
  Future<Either<ErrorResponse, SuccessResponse<MenuItemsCountAggregate>>>
  getMenuItemsCount() async {
    try {
      final menuItemsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );

      final allMenuItems = await menuItemsCollection.count().get();
      final allMenuItemCount = allMenuItems.count;

      final activeMenuItemSnapshot =
          await menuItemsCollection
              .where('isActive', isEqualTo: true)
              .count()
              .get();
      final activeMenuItemCount = activeMenuItemSnapshot.count;

      final nonActiveMenuItemSnapshot =
          await menuItemsCollection
              .where('isActive', isEqualTo: true)
              .count()
              .get();
      final nonActiveMenuItemCount = nonActiveMenuItemSnapshot.count;

      final menuItemAggregate = MenuItemsCountAggregate(
        allMenuItemCount: allMenuItemCount ?? 0,
        activeMenuItemCount: activeMenuItemCount ?? 0,
        nonActiveMenuItemCount: nonActiveMenuItemCount ?? 0,
      );

      return Right(
        SuccessResponse(
          data: menuItemAggregate,
          message: "MenuItem counts retrieved successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get menuItem counts: ${e.toString()}',
        ),
      );
    }
  }
}

class MenuItemsCountAggregate {
  final int allMenuItemCount;
  final int activeMenuItemCount;
  final int nonActiveMenuItemCount;

  MenuItemsCountAggregate({
    required this.allMenuItemCount,
    required this.activeMenuItemCount,
    required this.nonActiveMenuItemCount,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'allMenuItemCount': allMenuItemCount,
      'activeMenuItemCount': activeMenuItemCount,
      'nonActiveMenuItemCount': nonActiveMenuItemCount,
    };
  }

  factory MenuItemsCountAggregate.fromMap(Map<String, dynamic> map) {
    return MenuItemsCountAggregate(
      allMenuItemCount: map['allMenuItemCount'] as int,
      activeMenuItemCount: map['activeMenuItemCount'] as int,
      nonActiveMenuItemCount: map['nonActiveMenuItemCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory MenuItemsCountAggregate.fromJson(String source) =>
      MenuItemsCountAggregate.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
