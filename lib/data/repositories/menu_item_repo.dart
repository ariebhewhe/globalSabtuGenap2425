import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class MenuItemRepo {
  final FirebaseFirestore _firebaseFirestore;
  final String _collectionPath = 'menuItems';
  final AppLogger logger = AppLogger();

  MenuItemRepo(this._firebaseFirestore);

  Future<Either<ErrorResponse, SuccessResponse<MenuItemModel>>> addMenuItem(
    MenuItemModel newMenuItem,
  ) async {
    try {
      final menuItemsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = menuItemsCollection.doc();

      final menuItemWithId = newMenuItem.copyWith(
        id: docRef.id,
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
          await querySnapshot.docs
              .map((doc) => MenuItemModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: menuItems));
    } catch (e) {
      return Left(
        ErrorResponse(message: 'Failed to get all menu items ${e.toString()}'),
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
      return Left(ErrorResponse(message: "Failed to get menu item"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<MenuItemModel>>> updateMenuItem(
    String id,
    MenuItemModel updatedMenuItem,
  ) async {
    try {
      final menuItemWithUpdatedTimestamp = updatedMenuItem.copyWith(
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
      return Left(
        ErrorResponse(message: 'Failed to update menu ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteMenuItem(
    String id,
  ) async {
    try {
      await _firebaseFirestore.collection(_collectionPath).doc(id).delete();

      return Right(SuccessResponse(data: id, message: "Menu item deleted"));
    } catch (e) {
      return Left(
        ErrorResponse(message: 'Failed to delete menu ${e.toString()}'),
      );
    }
  }
}
