import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../model/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Collection references
  CollectionReference get _categoriesRef => _firestore.collection('categories');

  // Get all categories
  Stream<List<CategoryModel>> getAllCategories() {
    return _categoriesRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  // Get category by ID
  Stream<CategoryModel?> getCategoryById(String categoryId) {
    return _categoriesRef.doc(categoryId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return CategoryModel.fromJson({
        'id': snapshot.id,
        ...snapshot.data() as Map<String, dynamic>,
      });
    });
  }

  // Get categories with book count
  Stream<List<CategoryModel>> getCategoriesWithBookCount() {
    return _categoriesRef
        .orderBy('bookCount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  // Get total categories count
  Future<int> getCategoriesCount() async {
    final snapshot = await _categoriesRef.get();
    return snapshot.docs.length;
  }

  // Add a new category
  Future<CategoryModel> addCategory(CategoryModel category) async {
    final docRef = await _categoriesRef.add(category.toJson());

    return category.copyWith(id: docRef.id);
  }

  // Update a category
  Future<void> updateCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).update(category.toJson());
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  // Increment book count for a category
  Future<void> incrementBookCount(String categoryId) async {
    await _categoriesRef.doc(categoryId).update({
      'bookCount': FieldValue.increment(1),
    });
  }

  // Decrement book count for a category
  Future<void> decrementBookCount(String categoryId) async {
    await _categoriesRef.doc(categoryId).update({
      'bookCount': FieldValue.increment(-1),
    });
  }

  // Initialize default categories if none exist
  Future<void> initializeDefaultCategoriesIfNeeded() async {
    final categories = await _categoriesRef.limit(1).get();

    if (categories.docs.isEmpty) {
      final batch = _firestore.batch();

      final defaultCategories = [
        CategoryModel(
          id: '',
          name: 'Fiksi',
          description: 'Buku-buku fiksi dan novel',
          iconName: 'auto_stories',
        ),
        CategoryModel(
          id: '',
          name: 'Non-Fiksi',
          description: 'Buku-buku non-fiksi dan edukasi',
          iconName: 'menu_book',
        ),
        CategoryModel(
          id: '',
          name: 'Teknologi',
          description: 'Buku-buku tentang teknologi dan komputer',
          iconName: 'computer',
        ),
        CategoryModel(
          id: '',
          name: 'Bisnis & Ekonomi',
          description: 'Buku-buku tentang bisnis dan ekonomi',
          iconName: 'business',
        ),
        CategoryModel(
          id: '',
          name: 'Seni & Desain',
          description: 'Buku-buku tentang seni dan desain',
          iconName: 'palette',
        ),
        CategoryModel(
          id: '',
          name: 'Sejarah',
          description: 'Buku-buku sejarah',
          iconName: 'history_edu',
        ),
        CategoryModel(
          id: '',
          name: 'Sains',
          description: 'Buku-buku sains dan ilmu pengetahuan',
          iconName: 'science',
        ),
      ];

      for (var category in defaultCategories) {
        final docRef = _categoriesRef.doc();
        batch.set(docRef, category.toJson());
      }

      await batch.commit();
    }
  }
}

// Provider for CategoryRepository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});