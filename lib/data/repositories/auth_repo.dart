import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jamal/core/helpers/error_response.dart';
import 'package:jamal/core/helpers/success_response.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/providers.dart';
import 'package:jamal/shared/services/current_user_storage.dart';

final authRepoProvider = Provider<AuthRepo>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final currentUserStorageService = ref.watch(
    currentUserStorageServiceProvider,
  );

  return AuthRepo(firestore, auth, currentUserStorageService);
});

class AuthRepo {
  final FirebaseFirestore _firebaseFirestore;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final CurrentUserStorageService _currentUserStorageService;

  final String _collectionPath = 'users';
  final AppLogger logger = AppLogger();

  AuthRepo(
    this._firebaseFirestore,
    this._firebaseAuth,
    this._currentUserStorageService,
  );

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>> register(
    UserModel newUser,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: newUser.email,
            password: password,
          );

      final User? user = userCredential.user;

      if (user == null) {
        return Left(ErrorResponse(message: 'Failed to create user'));
      }

      await user.updateDisplayName(newUser.username);

      final userWithFirebaseCred = newUser.copyWith(
        id: user.uid,
        profilePicture: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseFirestore
          .collection(_collectionPath)
          .doc(user.uid)
          .set(userWithFirebaseCred.toMap());

      return Right(
        SuccessResponse(data: newUser, message: 'User registered successfully'),
      );
    } catch (e) {
      logger.e('Registration error: $e');
      return Left(ErrorResponse(message: _getAuthErrorMessage(e)));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user == null) {
        return Left(ErrorResponse(message: 'Failed to login'));
      }

      final docSnapshot =
          await _firebaseFirestore
              .collection(_collectionPath)
              .doc(user.uid)
              .get();

      if (!docSnapshot.exists) {
        return Left(ErrorResponse(message: 'User data not found'));
      }

      // * Konversi data Firestore ke UserModel
      final userData = docSnapshot.data();
      final userModel = UserModel.fromMap(userData!);

      await _currentUserStorageService.saveCurrentUser(userModel);

      return Right(
        SuccessResponse(data: userModel, message: 'Login successful'),
      );
    } catch (e) {
      logger.e('Email login error: $e');
      return Left(ErrorResponse(message: _getAuthErrorMessage(e)));
    }
  }

  Future<Either<ErrorResponse, SuccessResponse<UserModel>>>
  loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return Left(ErrorResponse(message: 'Google sign-in was canceled'));
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        return Left(ErrorResponse(message: 'Failed to login with Google'));
      }

      final docSnapshot =
          await _firebaseFirestore
              .collection(_collectionPath)
              .doc(user.uid)
              .get();

      late UserModel userModel;

      if (!docSnapshot.exists) {
        userModel = UserModel(
          id: user.uid,
          username: user.displayName ?? user.email!.split('@')[0],
          email: user.email!,
          profilePicture: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firebaseFirestore
            .collection(_collectionPath)
            .doc(user.uid)
            .set(userModel.toMap());

        await _currentUserStorageService.saveCurrentUser(userModel);
      }

      return Right(
        SuccessResponse(data: userModel, message: 'Google login successful'),
      );
    } catch (e) {
      logger.e('Google login error: $e');
      return Left(ErrorResponse(message: _getAuthErrorMessage(e)));
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final currentUser = await _currentUserStorageService.getCurrentUser();

    return currentUser;
  }

  bool isLoggedIn() {
    return _firebaseAuth.currentUser != null;
  }

  Future<Either<ErrorResponse, SuccessResponse<String>>> logout() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      return Right(
        SuccessResponse(data: 'No data nyan~', message: 'Logout successful'),
      );
    } catch (e) {
      logger.e('Logout error: $e');
      return Left(ErrorResponse(message: 'Failed to logout: ${e.toString()}'));
    }
  }

  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'The email address is already in use.';
        case 'weak-password':
          return 'The password is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'account-exists-with-different-credential':
          return 'An account already exists with the same email address but different sign-in credentials.';
        case 'invalid-credential':
          return 'The credential is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return error.toString();
  }
}
