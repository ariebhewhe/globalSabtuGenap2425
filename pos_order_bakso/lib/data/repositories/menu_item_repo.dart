import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/category_model.dart';
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
  final String _categoriesCollectionPath = 'categories';
  final String _cartItemsCollectionPath = 'cartItems';
  final String _cloudinaryFolder = 'menu_items';
  final AppLogger logger = AppLogger();

  MenuItemRepo(this._firebaseFirestore, this._cloudinaryService);

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
        // Decide if you want to re-throw or just log the error
      }
    }
  }

  /// Populates the `category` field for a list of [MenuItemModel] efficiently.
  Future<List<MenuItemModel>> _populateCategories(
    List<MenuItemModel> menuItems,
  ) async {
    if (menuItems.isEmpty) return [];

    final categoryIds =
        menuItems
            .map((item) => item.categoryId)
            .where((id) => id != null)
            .toSet()
            .toList();

    if (categoryIds.isEmpty) return menuItems;

    try {
      final categoriesSnapshot =
          await _firebaseFirestore
              .collection(_categoriesCollectionPath)
              .where(FieldPath.documentId, whereIn: categoryIds)
              .get();

      final categoriesMap = {
        for (var doc in categoriesSnapshot.docs)
          doc.id: CategoryModel.fromMap(doc.data()),
      };

      return menuItems
          .map(
            (item) => item.copyWith(category: categoriesMap[item.categoryId]),
          )
          .toList();
    } catch (e) {
      logger.e('Failed to populate categories: ${e.toString()}');
      // Return original items if category fetching fails
      return menuItems;
    }
  }

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
      menuItemData['imageUrl'] = imageUrl;
      menuItemData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      menuItemData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await docRef.set(menuItemData);

      final menuItem = MenuItemModel.fromMap(menuItemData);

      // Fetch and attach category data for the newly created item
      final result = await getMenuItemById(menuItem.id);
      return result.fold(
        (l) => Right(
          SuccessResponse(
            data: menuItem,
            message: 'New menu item added (category not found)',
          ),
        ),
        (r) => Right(
          SuccessResponse(data: r.data, message: 'New menu item added'),
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new menu: ${e.toString()}'),
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
        // Note: Batch add does not support image uploads.
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

      List<MenuItemModel> menuItems =
          querySnapshot.docs
              .map(
                (doc) =>
                    MenuItemModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      menuItems = await _populateCategories(menuItems);

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

      List<MenuItemModel> menuItems =
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

      menuItems = await _populateCategories(menuItems);

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
        ErrorResponse(message: 'Failed to search menu items: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<MenuItemModel>>> getMenuItemById(
    String id,
  ) async {
    try {
      final docSnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: "Menu item not found"));
      }

      var menuItem = MenuItemModel.fromMap(docSnapshot.data()!);

      if (menuItem.categoryId != null) {
        final categoryDoc =
            await _firebaseFirestore
                .collection(_categoriesCollectionPath)
                .doc(menuItem.categoryId!)
                .get();
        if (categoryDoc.exists) {
          menuItem = menuItem.copyWith(
            category: CategoryModel.fromMap(categoryDoc.data()!),
          );
        }
      }

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
        await _deleteImageByUrl(existingMenuItem.imageUrl);
        finalImageUrl = null;
      }

      if (dto.imageFile != null) {
        // If there's an existing image and we're not explicitly told to keep it, delete it.
        if (finalImageUrl != null && !deleteExistingImage) {
          await _deleteImageByUrl(finalImageUrl);
        }

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

      updateData['imageUrl'] = finalImageUrl;
      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      final docRef = _firebaseFirestore.collection(_collectionPath).doc(id);
      await docRef.update(updateData);

      final updatedMenuItemResult = await getMenuItemById(id);
      return updatedMenuItemResult.fold(
        (l) => Left(l),
        (r) =>
            Right(SuccessResponse(data: r.data, message: "Menu item updated")),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update menu: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteMenuItem(
    String id, {
    bool deleteImage = true,
  }) async {
    try {
      final docRef = _firebaseFirestore.collection(_collectionPath).doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: 'Menu item not found'));
      }

      // Start a batch write
      final batch = _firebaseFirestore.batch();

      // 1. Query all cart items that reference this menu item
      final cartItemsQuery = _firebaseFirestore
          .collection(_cartItemsCollectionPath)
          .where('menuItemId', isEqualTo: id);
      final cartItemsSnapshot = await cartItemsQuery.get();

      // 2. Add deletion of each related cart item to the batch
      for (final doc in cartItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Handle image deletion from Cloudinary (outside the batch)
      if (deleteImage) {
        final imageUrl = docSnapshot.data()?['imageUrl'];
        await _deleteImageByUrl(imageUrl);
      }

      // 3. Add the main menu item deletion to the batch
      batch.delete(docRef);

      // 4. Commit all deletions atomically
      await batch.commit();

      final deletedCount = cartItemsSnapshot.docs.length;
      logger.i('Menu item $id and $deletedCount related cart item(s) deleted.');

      return Right(
        SuccessResponse(
          data: id,
          message: "Menu item and $deletedCount related cart item(s) deleted",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete menu: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>> batchDeleteMenuItems(
    List<String> ids, {
    bool deleteImages = true,
  }) async {
    if (ids.isEmpty) {
      return Right(SuccessResponse(data: null, message: 'No items to delete.'));
    }

    try {
      // Start a batch write
      final batch = _firebaseFirestore.batch();
      final collectionRef = _firebaseFirestore.collection(_collectionPath);

      // Get the menu items to be deleted (needed for image URLs)
      final menuItemsSnapshot =
          await collectionRef.where(FieldPath.documentId, whereIn: ids).get();

      if (menuItemsSnapshot.docs.isEmpty) {
        return Left(ErrorResponse(message: 'No matching menu items found.'));
      }

      // Handle image deletion from Cloudinary
      if (deleteImages) {
        final imageUrlsToDelete =
            menuItemsSnapshot.docs
                .map((doc) => doc.data()['imageUrl'] as String?)
                .where((url) => url != null)
                .toList();

        if (imageUrlsToDelete.isNotEmpty) {
          await Future.wait(
            imageUrlsToDelete.map((url) => _deleteImageByUrl(url!)),
          );
        }
      }

      // 1. Query all cart items that reference any of the menu items
      final cartItemsQuery = _firebaseFirestore
          .collection(_cartItemsCollectionPath)
          .where('menuItemId', whereIn: ids);
      final cartItemsSnapshot = await cartItemsQuery.get();

      // 2. Add deletion of each related cart item to the batch
      for (final doc in cartItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Add deletion of each menu item to the batch
      for (final doc in menuItemsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 4. Commit all deletions atomically
      await batch.commit();

      final deletedMenuItemsCount = menuItemsSnapshot.docs.length;
      final deletedCartItemsCount = cartItemsSnapshot.docs.length;
      logger.i(
        '$deletedMenuItemsCount menu item(s) and $deletedCartItemsCount related cart item(s) deleted.',
      );

      return Right(
        SuccessResponse(
          data: null,
          message:
              '$deletedMenuItemsCount menu item(s) and $deletedCartItemsCount related cart item(s) deleted.',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to batch delete menu items: ${e.toString()}',
        ),
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
      final activeMenuItemSnapshot =
          await menuItemsCollection
              .where('isAvailable', isEqualTo: true)
              .count()
              .get();
      final nonActiveMenuItemSnapshot =
          await menuItemsCollection
              .where('isAvailable', isEqualTo: false)
              .count()
              .get();

      final menuItemAggregate = MenuItemsCountAggregate(
        allMenuItemCount: allMenuItems.count ?? 0,
        activeMenuItemCount: activeMenuItemSnapshot.count ?? 0,
        nonActiveMenuItemCount: nonActiveMenuItemSnapshot.count ?? 0,
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
