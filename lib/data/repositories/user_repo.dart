// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/models/paginated_result.dart';
import 'package:jamal/shared/services/cloudinary_service.dart';
import 'package:jamal/shared/services/current_user_storage_service.dart';

final userRepoProvider = Provider.autoDispose<UserRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cloudinary = ref.watch(cloudinaryProvider);
  final currentUserService = ref.watch(currentUserStorageServiceProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return UserRepo(firestore, cloudinary, currentUserService, firebaseAuth);
});

class UserRepo {
  final FirebaseFirestore _firebaseFirestore;
  final CloudinaryService _cloudinaryService;
  final CurrentUserStorageService _currentUserStorageService;
  final FirebaseAuth _firebaseAuth;

  final String _collectionPath = 'users';
  final String _cloudinaryFolder = 'users';
  final AppLogger logger = AppLogger();

  UserRepo(
    this._firebaseFirestore,
    this._cloudinaryService,
    this._currentUserStorageService,
    this._firebaseAuth,
  );

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>> addUser(
    UserModel newUser, {
    File? imageFile,
  }) async {
    try {
      final usersCollection = _firebaseFirestore.collection(_collectionPath);
      final docRef = usersCollection.doc();

      String? profilePicture = newUser.profilePicture;

      if (imageFile != null) {
        try {
          final uploadResponse = await _cloudinaryService.uploadImage(
            imageFile: imageFile,
            folder: _cloudinaryFolder,
          );

          profilePicture = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final userWithId = newUser.copyWith(
        id: docRef.id,
        profilePicture: profilePicture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(userWithId.toMap());

      return Right(
        SuccessResponse(data: userWithId, message: 'New user item added'),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to add new user ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<List<UserModel>>>>
  getAllUser() async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).get();

      final users =
          querySnapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList();

      return Right(SuccessResponse(data: users));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get all user items ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<PaginatedResult<UserModel>>>>
  getPaginatedUsers({
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

      final users =
          querySnapshot.docs
              .map(
                (doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

      final hasMore = querySnapshot.docs.length >= limit;

      final lastDocument =
          querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return Right(
        SuccessResponse(
          data: PaginatedResult(
            items: users,
            hasMore: hasMore,
            lastDocument: lastDocument,
          ),
          message: 'Users retrieved successfully',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to get paginated user items: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>> getUserById(
    String id,
  ) async {
    try {
      final querySnapshot =
          await _firebaseFirestore.collection(_collectionPath).doc(id).get();

      if (!querySnapshot.exists) {
        return Left(ErrorResponse(message: "User not found"));
      }

      final user = UserModel.fromMap(querySnapshot.data()!);

      return Right(SuccessResponse(data: user));
    } catch (e) {
      logger.e(e.toString());
      return Left(ErrorResponse(message: "Failed to get user item"));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>> updateUser(
    String id,
    UserModel updatedUser, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    try {
      final userResult = await getUserById(id);
      if (userResult.isLeft()) {
        return Left(ErrorResponse(message: 'User not found'));
      }

      final existingUser = userResult.getRight().toNullable()!.data;
      String? profilePicture =
          updatedUser.profilePicture ?? existingUser.profilePicture;

      if (deleteExistingImage && existingUser.profilePicture != null) {
        try {
          final existingImageUrl = existingUser.profilePicture!;
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
            profilePicture = null;
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

          profilePicture = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final userWithUpdatedTimestamp = updatedUser.copyWith(
        profilePicture: profilePicture,
        updatedAt: DateTime.now(),
      );

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(id)
          .update(userWithUpdatedTimestamp.toMap());

      return Right(
        SuccessResponse(
          data: userWithUpdatedTimestamp,
          message: "User updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update user ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>> updateCurrentUser(
    UserModel updatedUser, {
    File? imageFile,
    bool deleteExistingImage = false,
  }) async {
    try {
      final String? currentUserId = _firebaseAuth.currentUser?.uid;

      if (currentUserId == null) {
        return Left(ErrorResponse(message: 'User not authenticated.'));
      }

      final userResult = await getUserById(currentUserId);
      if (userResult.isLeft()) {
        return Left(
          ErrorResponse(message: 'Current user data not found in Firestore.'),
        );
      }

      final existingUser = userResult.getRight().toNullable()!.data;
      String? profilePicture =
          updatedUser.profilePicture ?? existingUser.profilePicture;

      if (deleteExistingImage && existingUser.profilePicture != null) {
        try {
          final existingImageUrl = existingUser.profilePicture!;
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
            profilePicture = null;
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

          profilePicture = uploadResponse.secureUrl;
        } catch (e) {
          logger.e('Failed to upload image: ${e.toString()}');
          return Left(
            ErrorResponse(message: 'Failed to upload image: ${e.toString()}'),
          );
        }
      }

      final userWithUpdatedTimestamp = updatedUser.copyWith(
        profilePicture: profilePicture,
        updatedAt: DateTime.now(),
      );

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(currentUserId)
          .update(userWithUpdatedTimestamp.toMap());

      await _currentUserStorageService.saveCurrentUser(
        userWithUpdatedTimestamp,
      );
      return Right(
        SuccessResponse(
          data: userWithUpdatedTimestamp,
          message: "Current user profile updated",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(
          message: 'Failed to update current user profile: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> updateUserPassword(
    String newPassword,
  ) async {
    try {
      final User? user = _firebaseAuth.currentUser;

      if (user == null) {
        return Left(ErrorResponse(message: 'No authenticated user found.'));
      }

      final bool isPasswordProvider = user.providerData.any(
        (info) => info.providerId == EmailAuthProvider.PROVIDER_ID,
      );

      if (!isPasswordProvider) {
        return Left(
          ErrorResponse(
            message:
                'User is not authenticated with an email/password provider. Password update is not applicable.',
          ),
        );
      }

      await user.updatePassword(newPassword);

      return Right(
        SuccessResponse(
          data: user.uid,
          message: 'User password updated successfully.',
        ),
      );
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Exception: ${e.code} - ${e.message}');
      return Left(
        ErrorResponse(
          message: 'Failed to update password: ${e.message ?? 'Unknown error'}',
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to update password: ${e.toString()}'),
      );
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> deleteUser(
    String id, {
    bool deleteImage = true,
  }) async {
    try {
      final userResult = await getUserById(id);
      if (userResult.isLeft()) {
        return Left(ErrorResponse(message: 'User not found'));
      }

      final user = userResult.getRight().toNullable()!.data;

      if (deleteImage && user.profilePicture != null) {
        try {
          final profilePicture = user.profilePicture!;
          final uri = Uri.parse(profilePicture);
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

      return Right(SuccessResponse(data: id, message: "User deleted"));
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to delete user ${e.toString()}'),
      );
    }
  }

  // * Aggregate
  Future<Either<ErrorResponse, SuccessResponse<UsersCountAggregate>>>
  getUsersCount() async {
    try {
      final usersCollection = _firebaseFirestore.collection(_collectionPath);

      final allUserSnapshot = await usersCollection.count().get();
      final allUserCount = allUserSnapshot.count;

      final adminSnapshot =
          await usersCollection.where('role', isEqualTo: 'admin').count().get();
      final adminCount = adminSnapshot.count;

      final userSnapshot =
          await usersCollection.where('role', isEqualTo: 'user').count().get();
      final userCount = userSnapshot.count;

      final userAggregate = UsersCountAggregate(
        allUserCount: allUserCount ?? 0,
        adminCount: adminCount ?? 0,
        userCount: userCount ?? 0,
      );

      return Right(
        SuccessResponse(
          data: userAggregate,
          message: "User counts retrieved successfully",
        ),
      );
    } catch (e) {
      logger.e(e.toString());
      return Left(
        ErrorResponse(message: 'Failed to get user counts: ${e.toString()}'),
      );
    }
  }
}

class UsersCountAggregate {
  final int allUserCount;
  final int adminCount;
  final int userCount;

  UsersCountAggregate({
    required this.allUserCount,
    required this.adminCount,
    required this.userCount,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'allUserCount': allUserCount,
      'adminCount': adminCount,
      'userCount': userCount,
    };
  }

  factory UsersCountAggregate.fromMap(Map<String, dynamic> map) {
    return UsersCountAggregate(
      allUserCount: map['allUserCount'] as int,
      adminCount: map['adminCount'] as int,
      userCount: map['userCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory UsersCountAggregate.fromJson(String source) =>
      UsersCountAggregate.fromMap(json.decode(source) as Map<String, dynamic>);
}
