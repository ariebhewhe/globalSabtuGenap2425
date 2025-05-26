import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

final cartItemRepoProvider = Provider.autoDispose<CartItemRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final currentUserService = ref.watch(currentUserStorageServiceProvider);

  return CartItemRepo(firestore, currentUserService);
});

class CartItemRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CurrentUserStorageService _currentUserStorageService;

  final String _collectionPath = 'cartItems';
  final AppLogger logger = AppLogger();

  CartItemRepo(this._firebaseFirestore, this._currentUserStorageService);

  Future<Either<ErrorResponse, SuccessResponse<CartItemModel>>> addCartItem(
    CreateCartItemDto dto,
  ) async {
    try {
      final userId = await _getCurrentUserId();
      final querySnapshot =
          await _firebaseFirestore
              .collection(_collectionPath)
              .where('menuItemId', isEqualTo: dto.menuItemId)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // * Kalo udah ada update quantity dan updatedAt aja
        final existingDoc = querySnapshot.docs.first;
        final existingCartItem = CartItemModel.fromMap(existingDoc.data());

        final newQuantity = existingCartItem.quantity + dto.quantity;
        final updateData = {
          'quantity': newQuantity,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'menuItem': dto.menuItem.toMap(),
        };

        await existingDoc.reference.update(updateData);

        final updatedCartItem = existingCartItem.copyWith(
          quantity: newQuantity,
          menuItem: DenormalizedMenuItemModel.fromMap(
            dto.menuItem.toMap(),
          ), // Pastikan tipe sesuai
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            updateData['updatedAt'] as int,
          ),
        );

        return Right(
          SuccessResponse(
            data: updatedCartItem,
            message: 'Cart item quantity updated',
          ),
        );
      }

      final cartItemsCollection = _firebaseFirestore.collection(
        _collectionPath,
      );
      final docRef = cartItemsCollection.doc();

      final cartItemData = dto.toMap();

      cartItemData['id'] = docRef.id;
      cartItemData['userId'] = userId;
      cartItemData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
      cartItemData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await docRef.set(cartItemData);

      final cartItem = CartItemModel.fromMap(cartItemData);

      return Right(
        SuccessResponse(data: cartItem, message: 'New cart item added'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new cart ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<CartItemModel>>>>
  getAllCartItem() async {
    try {
      final userId = await _getCurrentUserId();
      final querySnapshot =
          await _firebaseFirestore
              .collection(_collectionPath)
              .where('userId', isEqualTo: userId)
              .get();

      final cartItems =
          querySnapshot.docs
              .map((doc) => CartItemModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: cartItems));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get all cart items ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<CartItemModel>>>>
  getPaginatedCartItems({
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
      final cartItems =
          querySnapshot.docs
              .map(
                (doc) =>
                    CartItemModel.fromMap(doc.data() as Map<String, dynamic>),
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
            items: cartItems,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Cart items retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated cart items: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<CartItemModel>>> getCartItemById(
    String id,
  ) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "Cart item not found"));
      }

      final cartItem = CartItemModel.fromMap(querySnapshot.data()!);

      return Right(SuccessResponse(data: cartItem));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get cart item"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<CartItemModel>>> updateCartItem(
    String id,
    UpdateCartItemDto dto,
  ) async {
    try {
      final userId = await _getCurrentUserId();
      final cartItemResult = await getCartItemById(id);

      if (cartItemResult.isLeft()) {
        return Left(ErrorResponse(message: 'Cart item not found'));
      }

      final currentCartItem = cartItemResult.getRight().toNullable()!.data;

      if (currentCartItem.userId != userId) {
        return Left(
          ErrorResponse(message: 'Unauthorized to update this cart item'),
        );
      }

      final updateData = dto.toMap();

      updateData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(updateData);

      final updatedCartItem = currentCartItem.copyWith(
        quantity: dto.quantity ?? currentCartItem.quantity,
        updatedAt: DateTime.now(),
      );

      return Right(
        SuccessResponse(data: updatedCartItem, message: "Cart item updated"),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update cart ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteCartItem(
    String id,
  ) async {
    try {
      final userId = await _getCurrentUserId();

      final cartItemResult = await getCartItemById(id);

      if (cartItemResult.isLeft()) {
        return Left(ErrorResponse(message: 'Cart item not found'));
      }

      final cartItem = cartItemResult.getRight().toNullable()!.data;

      if (cartItem.userId != userId) {
        return Left(
          ErrorResponse(message: 'Unauthorized to delete this cart item'),
        );
      }

      await _firebaseFirestore.collection(_collectionPath).doc(id).delete();

      return Right(SuccessResponse(data: id, message: "Cart item deleted"));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete cart ${e.toString()}'),
      );
    }
  }

  // * Agregasi
  Future<Either<ErrorResponse, SuccessResponse<int>>>
  getTotalCartQuantity() async {
    try {
      final userId = await _getCurrentUserId();
      final query = _firebaseFirestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId);

      // * Menggunakan AggregateQuery untuk sum
      final aggregateQuery = query.aggregate(sum('quantity'));
      final aggregateSnapshot = await aggregateQuery.get();

      final totalQuantity =
          aggregateSnapshot.getSum('quantity')?.toInt() ??
          0; // * Ambil hasil sum

      return Right(
        SuccessResponse(
          data: totalQuantity,
          message: 'Total cart quantity retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get total cart quantity: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<int>>>
  getDistinctItemCountInCart() async {
    try {
      final userId = await _getCurrentUserId();
      final query = _firebaseFirestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId);

      // * Menggunakan AggregateQuery untuk count
      final aggregateQuery = query.count(); // * Langsung count() pada query
      final aggregateSnapshot = await aggregateQuery.get();

      final distinctItemCount =
          aggregateSnapshot.count ?? 0; // * Ambil hasil count

      return Right(
        SuccessResponse(
          data: distinctItemCount,
          message: 'Distinct item count retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get distinct item count: ${e.toString()}',
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
}
