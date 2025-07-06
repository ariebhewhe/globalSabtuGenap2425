import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qurbanqu/model/user_model.dart';
import 'package:qurbanqu/model/order_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      DocumentSnapshot userData =
          await _firestore.collection('Users').doc(firebaseUser.uid).get();
      if (userData.exists) {
        return UserModel.fromMap(
          userData.data() as Map<String, dynamic>,
          firebaseUser.uid,
        );
      }
      return null;
    });
  }

  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String nama,
    required String telepon,
    required String alamat,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        UserModel newUser = UserModel(
          id: result.user!.uid,
          nama: nama,
          email: email,
          telepon: telepon,
          alamat: alamat,
          role: userRoleToString(UserRole.user),
        );

        await _firestore
            .collection('Users')
            .doc(result.user!.uid)
            .set(newUser.toMap());
      }

      return result;
    } on FirebaseAuthException catch (e) {
      print('Error registrasi Firebase: ${e.message}');
      throw e;
    } catch (e) {
      print('Error registrasi lainnya: $e');
      rethrow;
    }
  }

  // Tambahkan di class AuthService
  Future<void> updateUserProfile({
    required String userId,
    required String nama,
    required String telepon,
    required String alamat,
  }) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        'nama': nama,
        'telepon': telepon,
        'alamat': alamat,
      });
    } catch (e) {
      print('Error update profil: $e');
      throw e;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Error login Firebase: ${e.message}');
      throw e;
    } catch (e) {
      print('Error login lainnya: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> isUserAdmin(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('role')) {
          return data['role'] == userRoleToString(UserRole.admin);
        }
      }
      return false;
    } catch (e) {
      print('Error mengecek status admin: $e');
      return false;
    }
  }

  Future<UserModel?> getCurrentUserModel() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    DocumentSnapshot userData =
        await _firestore.collection('Users').doc(firebaseUser.uid).get();
    if (userData.exists) {
      return UserModel.fromMap(
        userData.data() as Map<String, dynamic>,
        firebaseUser.uid,
      );
    }
    return null;
  }

  authStateChanges() {
    return _auth.authStateChanges();
  }
}
