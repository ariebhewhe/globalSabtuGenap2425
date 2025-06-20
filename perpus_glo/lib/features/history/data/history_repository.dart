import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../model/history_model.dart';

class HistoryRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  // Collection references
  CollectionReference get _historyRef => _firestore.collection('history');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Add activity to history
  Future<void> addActivity({
    required ActivityType activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('Warning: Mencoba menambahkan history tanpa userId');
        return;
      }

      final historyId = _historyRef.doc().id;

      // Pastikan userId disertakan
      final history = HistoryModel(
        id: historyId,
        userId: userId, // Pastikan ini ada dan terisi benar
        activityType: activityType,
        timestamp: DateTime.now(),
        description: description,
        metadata: metadata,
      );

      await _historyRef.doc(historyId).set(history.toJson());
    } catch (e) {
      debugPrint('Error adding activity to history: $e');
    }
  }

  // Get user activity history
  Stream<List<HistoryModel>> getUserHistory() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _historyRef
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  // Get history by type
  Stream<List<HistoryModel>> getHistoryByType(ActivityType type) {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _historyRef
        .where('userId', isEqualTo: userId)
        .where('activityType', isEqualTo: type.toString().split('.').last)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  // Get history for date range
  Stream<List<HistoryModel>> getHistoryByDateRange(
      DateTime start, DateTime end) {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _historyRef
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  // Delete history item
  Future<void> deleteHistoryItem(String historyId) async {
    await _historyRef.doc(historyId).delete();
  }

  // Clear all history
  Future<void> clearHistory() async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    final batch = _firestore.batch();
    final userHistory =
        await _historyRef.where('userId', isEqualTo: userId).get();

    for (var doc in userHistory.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

// Provider for HistoryRepository
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});