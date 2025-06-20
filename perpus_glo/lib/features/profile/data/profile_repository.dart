import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../model/user_profile_model.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;
  // final FirebaseStorage _storage = FirebaseService.storage;

  // Collection references
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get current user profile
  Stream<UserProfileModel?> getCurrentUserProfile() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(null);
    }

    return _usersRef.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfileModel.fromJson({
        'id': snapshot.id,
        ...snapshot.data() as Map<String, dynamic>,
      });
    });
  }

// Metode untuk mendapatkan pengguna berdasarkan ID
  Stream<UserProfileModel> getUserProfileById(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('User tidak ditemukan');
      }
      final data = snapshot.data()!;
      return UserProfileModel.fromJson({
        'id': snapshot.id,
        ...data,
      });
    });
  }

// Metode untuk mencari pengguna
  Future<List<UserProfileModel>> searchUsers(String query) async {
    // Cari berdasarkan nama (case insensitive)
    final nameResults = await _firestore
        .collection('users')
        .where('nameLower', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('nameLower', isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
        .get();

    // Cari berdasarkan email (case insensitive)
    final emailResults = await _firestore
        .collection('users')
        .where('emailLower', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('emailLower',
            isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
        .get();

    // Gabungkan hasil dan hilangkan duplikat
    final allDocs = {...nameResults.docs, ...emailResults.docs};

    return allDocs.map((doc) {
      final data = doc.data();
      return UserProfileModel.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList();
  }

  // Create or update user profile
  Future<void> saveUserProfile(UserProfileModel profile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    //   // Ensure the profile ID matches the current user ID
    final updatedProfile = profile.copyWith(id: userId);

    await _usersRef
        .doc(userId)
        .set(updatedProfile.toJson(), SetOptions(merge: true));
  }

  // Update profile picture
  // Future<String> updateProfilePicture(File imageFile, dynamic uploadTask) async {
  //   final userId = currentUserId;
  //   if (userId == null) {
  //     throw Exception('User tidak ditemukan');
  //   }

  //   // Create a reference to the location you want to upload to in firebase storage
  //   // final storageRef = _storage.ref().child('profile_images/$userId.jpg');

  //   // Upload the file to firebase storage
  //   final uploadTask = await storageRef.putFile(
  //     imageFile,
  //     SettableMetadata(contentType: 'image/jpeg'),
  //   );

  //   // Get download URL
  //   final downloadUrl = await uploadTask.ref.getDownloadURL();

  //   // Update the profile document with the new image URL
  //   await _usersRef.doc(userId).update({'photoUrl': downloadUrl});

  //   return downloadUrl;
  // }

  // Update user display name in Firebase Auth
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    await user.updateDisplayName(name);
  }

  // Update user email in Firebase Auth
  Future<void> updateEmail(String newEmail, String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    // Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    // Update the email
    await user.updateEmail(newEmail);

    // Update the email in Firestore
    await _usersRef.doc(user.uid).update({'email': newEmail});
  }

  // Update user password in Firebase Auth
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    // Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update the password
    await user.updatePassword(newPassword);
  }

// Metode untuk menghapus pengguna (untuk admin)
  Future<void> deleteUser(String userId) async {
    // Verifikasi bahwa yang melakukan penghapusan adalah admin
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Admin tidak terautentikasi');
    }

    // Verifikasi role admin
    final adminDoc = await _usersRef.doc(currentUserId).get();
    final adminData = adminDoc.data() as Map<String, dynamic>?;
    if (adminData == null) {
      throw Exception('Data admin tidak ditemukan');
    }

    final adminRole = _roleFromString(adminData['role'] ?? 'user');
    if (adminRole != UserRole.admin && adminRole != UserRole.librarian) {
      throw Exception(
          'Hanya admin atau pustakawan yang dapat menghapus pengguna');
    }

    // Pastikan user yang akan dihapus bukan admin
    final userDoc = await _usersRef.doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('Pengguna tidak ditemukan');
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final userRole = _roleFromString(userData['role'] ?? 'user');

    // Hanya admin yang dapat menghapus admin/pustakawan lain
    if ((userRole == UserRole.admin || userRole == UserRole.librarian) &&
        adminRole != UserRole.admin) {
      throw Exception(
          'Hanya admin yang dapat menghapus admin atau pustakawan lain');
    }

    // Mulai proses penghapusan
    final batch = _firestore.batch();

    try {
      // 1. Hapus peminjaman terkait user
      final borrowsRef = _firestore.collection('borrows');
      final borrowDocs =
          await borrowsRef.where('userId', isEqualTo: userId).get();

      for (var doc in borrowDocs.docs) {
        batch.delete(doc.reference);
      }

      // 2. Hapus history/aktivitas terkait user
      final historyRef = _firestore.collection('history');
      final historyDocs =
          await historyRef.where('userId', isEqualTo: userId).get();

      for (var doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }

      // 3. Hapus data profil user
      batch.delete(_usersRef.doc(userId));

      // 4. Commit batch operation
      await batch.commit();

      // 5. Simpan log admin
      await logAdminAction('deleteUser', userId,
          'Admin ${adminData['name']} menghapus pengguna ${userData['name']} (${userData['email']})');

      // 6. Tambahkan log ke history
      await _firestore.collection('history').add({
        'userId': currentUserId,
        'activityType': 'deleteUser',
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Menghapus pengguna dari sistem',
        'metadata': {
          'deletedUserId': userId,
          'deletedUserEmail': userData['email'],
          'deletedUserName': userData['name'],
          'deletedUserRole': userData['role'],
        },
      });

      // Hapus user dari Firebase Auth (jika diperlukan)
      // Catatan: Ini memerlukan Firebase Admin SDK dan tidak bisa dilakukan langsung dari client
      // Biasanya dilakukan melalui Cloud Functions

      return;
    } catch (e) {
      throw Exception('Gagal menghapus pengguna: ${e.toString()}');
    }
  }

  // Delete user account
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User tidak ditemukan');
    }

    // Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    // Delete user data from Firestore
    await _usersRef.doc(user.uid).delete();

    // Delete profile image if exists
    try {
      // await _storage.ref().child('profile_images/${user.uid}.jpg').delete();
    } catch (e) {
      // Image might not exist, ignore
    }

    // Delete the user account
    await user.delete();
  }

  // Get all users (for admin)

  Stream<List<UserProfileModel>> getAllUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _usersRef.snapshots().asyncMap((snapshot) async {
      final currentUserDoc = await _usersRef.doc(currentUser.uid).get();
      final currentUserData = currentUserDoc.data() as Map<String, dynamic>?;

      if (currentUserData == null) {
        return [];
      }

      // Parse role dari currentUserData
      final currentUserRole =
          _roleFromString(currentUserData['role'] ?? 'user');

      // Cek apakah user adalah admin atau pustakawan
      if (currentUserRole != UserRole.admin &&
          currentUserRole != UserRole.librarian) {
        return [];
      }

      // Jika user adalah admin atau pustakawan, kembalikan semua user
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserProfileModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }

// Fungsi helper untuk mengkonversi string role ke enum UserRole
  UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'librarian':
        return UserRole.librarian;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  // Get user count (for admin)
  Future<int> getUserCount() async {
    final snapshot = await _usersRef.get();
    return snapshot.docs.length;
  }

  // Get user by ID (for admin)
  Stream<UserProfileModel?> getUserById(String userId) {
    return _usersRef.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfileModel.fromJson({
        'id': snapshot.id,
        ...snapshot.data() as Map<String, dynamic>,
      });
    });
  }

  // Update user role (for admin)
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _usersRef
        .doc(userId)
        .update({'role': role.toString().split('.').last});
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfileModel profile) async {
    await _usersRef.doc(profile.id).update(profile.toJson());

    // Tambahkan log ke history
    await _firestore.collection('history').add({
      'userId': currentUserId,
      'activityType': 'updateUser',
      'timestamp': FieldValue.serverTimestamp(),
      'description': 'Memperbarui profil pengguna',
      'metadata': {
        'updatedUserId': profile.id,
        'updatedUserEmail': profile.email,
        'updatedUserName': profile.name,
        'updatedUserRole': profile.role,
      },
    });

    
  }

  // Deactivate user account (for admin)
  Future<void> deactivateUser(String userId) async {
    await _usersRef.doc(userId).update({'isActive': false});
  }

  // Activate user account (for admin)
  Future<void> activateUser(String userId) async {
    await _usersRef.doc(userId).update({'isActive': true});
  }

  Future<void> logAdminAction(
      String action, String targetId, String? details) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _firestore.collection('adminLogs').add({
      'adminId': userId,
      'action': action,
      'targetId': targetId,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

// Provider for ProfileRepository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});