import 'dart:convert';

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
  final String _menuItemsCollectionPath = 'menuItems'; // Added for aggregation
  final String _cloudinaryFolder = 'categories';
  final AppLogger logger = AppLogger();

  CategoryRepo(this._firebaseFirestore, this._cloudinaryService);

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

  Future<Either<ErrorResponse, SuccessResponse<CategoryModel>>> addCategory(
    CreateCategoryDto dto,
  ) async {
    try {
      final categoriesCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = categoriesCollection.doc();

      String? picture;
      if (dto.pictureFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.pictureFile!,
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

      final categoryData = dto.toMap();
      categoryData['id'] = docRef.id;
      categoryData['picture'] = picture; // Handles null or new URL
      categoryData['createdAt'] = DateTime.now().toUtc().toIso8601String();
      categoryData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      await docRef.set(categoryData);

      final category = CategoryModel.fromMap(categoryData);

      return Right(
        SuccessResponse(data: category, message: 'New category added'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new category: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<CategoryModel>>>>
  batchAddCategories(List<CreateCategoryDto> dtos) async {
    if (dtos.isEmpty) {
      return Right(SuccessResponse(data: [], message: 'No categories to add.'));
    }
    try {
      final batch = _firebaseFirestore.batch();
      final categoriesCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final now = DateTime.now().toUtc().toIso8601String();
      List<CategoryModel> createdCategories = [];

      for (final dto in dtos) {
        // Note: Batch add does not support image file uploads.
        final docRef = categoriesCollection.doc();
        final Map<String, dynamic> categoryData = dto.toMap();

        categoryData['id'] = docRef.id;
        categoryData['createdAt'] = now;
        categoryData['updatedAt'] = now;

        batch.set(docRef, categoryData);
        createdCategories.add(CategoryModel.fromMap(categoryData));
      }

      await batch.commit();
      logger.i(
        '${createdCategories.length} categories successfully added in batch.',
      );
      return Right(
        SuccessResponse(
          data: createdCategories,
          message: '${createdCategories.length} categories added successfully.',
        ),
      );
    } catch (e) {
      logger.e('Failed to batch add categories: ${e.toString()}');
      return Left(
        ErrorResponse(
          message: 'Failed to batch add categories: ${e.toString()}',
        ),
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

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final categories =
          querySnapshot.docs
              .map(
                (doc) =>
                    CategoryModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      final hasMore = querySnapshot.docs.length >= limit;
      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: categories,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Categories retrieved successfully',
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

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<CategoryModel>>>>
  searchCategories({
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

      final categories =
          querySnapshot.docs
              .map(
                (doc) =>
                    CategoryModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowercaseQuery = searchQuery.toLowerCase();
        categories.retainWhere((category) {
          switch (searchBy) {
            case 'name':
              return category.name.toLowerCase().contains(lowercaseQuery);
            case 'description':
              return category.description?.toLowerCase().contains(
                    lowercaseQuery,
                  ) ??
                  false;
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
            items: categories,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Categories retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to search categories: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<CategoryModel>>> getCategoryById(
    String id,
  ) async {
    try {
      final docSnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: "Category not found"));
      }

      final category = CategoryModel.fromMap(docSnapshot.data()!);

      return Right(SuccessResponse(data: category));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get category"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<CategoryModel>>> updateCategory(
    String id,
    UpdateCategoryDto dto, {
    bool deleteExistingImage = false,
  }) async {
    try {
      final categoryResult = await getCategoryById(id);
      if (categoryResult.isLeft()) {
        return Left(ErrorResponse(message: 'Category not found'));
      }

      final existingCategory = categoryResult.getRight().toNullable()!.data;
      final updateData = dto.toMap();
      String? finalImageUrl = existingCategory.picture;

      if (deleteExistingImage && existingCategory.picture != null) {
        await _deleteImageByUrl(existingCategory.picture);
        finalImageUrl = null;
      }

      if (dto.pictureFile != null) {
        if (finalImageUrl != null && !deleteExistingImage) {
          await _deleteImageByUrl(finalImageUrl);
        }

        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: dto.pictureFile!,
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

      updateData['picture'] = finalImageUrl;
      updateData['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      final docRef = _firebaseFirestore.collection(_collectionPath).doc(id);
      await docRef.update(updateData);

      final updatedDocSnapshot = await docRef.get();
      final updatedCategory = CategoryModel.fromMap(updatedDocSnapshot.data()!);

      return Right(
        SuccessResponse(data: updatedCategory, message: "Category updated"),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update category: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteCategory(
    String id, {
    bool deleteImage = true,
  }) async {
    try {
      final docRef = _firebaseFirestore.collection(_collectionPath).doc(id);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: 'Category not found'));
      }

      final batch = _firebaseFirestore.batch();

      final menuItemsQuery = _firebaseFirestore
          .collection(_menuItemsCollectionPath)
          .where('categoryId', isEqualTo: id);
      final menuItemsSnapshot = await menuItemsQuery.get();

      for (final doc in menuItemsSnapshot.docs) {
        batch.update(doc.reference, {'categoryId': null});
      }

      if (deleteImage) {
        final imageUrl = docSnapshot.data()?['picture'];
        await _deleteImageByUrl(imageUrl);
      }

      batch.delete(docRef);

      await batch.commit();

      final updatedCount = menuItemsSnapshot.docs.length;
      logger.i(
        'Category $id deleted and $updatedCount related menu item(s) updated.',
      );

      return Right(
        SuccessResponse(
          data: id,
          message:
              'Category deleted and $updatedCount related menu item(s) updated',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete category: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<void>>> batchDeleteCategories(
    List<String> ids, {
    bool deleteImages = true,
  }) async {
    if (ids.isEmpty) {
      return Right(SuccessResponse(data: null, message: 'No items to delete.'));
    }

    try {
      final batch = _firebaseFirestore.batch();
      final collectionRef = _firebaseFirestore.collection(_collectionPath);

      final categoriesSnapshot =
          await collectionRef.where(FieldPath.documentId, whereIn: ids).get();

      if (categoriesSnapshot.docs.isEmpty) {
        return Left(ErrorResponse(message: 'No matching categories found.'));
      }

      if (deleteImages) {
        final imageUrlsToDelete =
            categoriesSnapshot.docs
                .map((doc) => doc.data()['picture'] as String?)
                .where((url) => url != null && url.isNotEmpty)
                .toList();

        if (imageUrlsToDelete.isNotEmpty) {
          await Future.wait(
            imageUrlsToDelete.map((url) => _deleteImageByUrl(url!)),
          );
        }
      }

      final menuItemsQuery = _firebaseFirestore
          .collection(_menuItemsCollectionPath)
          .where('categoryId', whereIn: ids);
      final menuItemsSnapshot = await menuItemsQuery.get();

      for (final doc in menuItemsSnapshot.docs) {
        batch.update(doc.reference, {'categoryId': null});
      }

      for (final doc in categoriesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      final deletedCategoriesCount = categoriesSnapshot.docs.length;
      final updatedMenuItemsCount = menuItemsSnapshot.docs.length;
      logger.i(
        '$deletedCategoriesCount category(s) deleted and $updatedMenuItemsCount related menu item(s) updated.',
      );

      return Right(
        SuccessResponse(
          data: null,
          message:
              '$deletedCategoriesCount category(s) deleted and $updatedMenuItemsCount related menu item(s) updated.',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to batch delete categories: ${e.toString()}',
        ),
      );
    }
  }

  // * Aggregate
  Future<Either<ErrorResponse, SuccessResponse<List<CategoryAggregate>>>>
  getCategoriesAggregate() async {
    try {
      final categoriesSnapshot =
          await _firebaseFirestore.collection(_collectionPath).get();

      final List<CategoryModel> categories =
          categoriesSnapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.data()))
              .toList();

      if (categories.isEmpty) {
        return Right(
          SuccessResponse(
            data: [],
            message: "No categories found to aggregate.",
          ),
        );
      }

      final List<CategoryAggregate> aggregates = [];
      for (final category in categories) {
        final countSnapshot =
            await _firebaseFirestore
                .collection(_menuItemsCollectionPath)
                .where('categoryId', isEqualTo: category.id)
                .count()
                .get();

        aggregates.add(
          CategoryAggregate(
            category: category,
            menuItemCount: countSnapshot.count ?? 0,
          ),
        );
      }

      return Right(
        SuccessResponse(
          data: aggregates,
          message: "Category aggregates retrieved successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get category aggregates: ${e.toString()}',
        ),
      );
    }
  }
}

class CategoryAggregate {
  final CategoryModel category;
  final int menuItemCount;

  CategoryAggregate({required this.category, required this.menuItemCount});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'category': category.toMap(),
      'menuItemCount': menuItemCount,
    };
  }

  factory CategoryAggregate.fromMap(Map<String, dynamic> map) {
    return CategoryAggregate(
      category: CategoryModel.fromMap(map['category'] as Map<String, dynamic>),
      menuItemCount: map['menuItemCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory CategoryAggregate.fromJson(String source) =>
      CategoryAggregate.fromMap(json.decode(source) as Map<String, dynamic>);
}
