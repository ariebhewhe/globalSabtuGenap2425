import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';
import '../model/category_model.dart';

// Provider for all categories
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

// Provider for popular categories (with most books)
final popularCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoriesWithBookCount();
});

// Provider for a specific category
final categoryProvider =
    StreamProvider.family<CategoryModel?, String>((ref, categoryId) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});

// Provider for categories count
final categoriesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoriesCount();
});

// Controller for category actions
class CategoryController extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;

  CategoryController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> addCategory(String name, String description) async {
    state = const AsyncValue.loading();
    try {
      final newCategory = CategoryModel(
        id: '', // ID akan diisi oleh Firestore
        name: name,
        description: description.isNotEmpty ? description : null,
        createdAt: DateTime.now(),
        bookCount: 0,
      );

      await _repository.addCategory(newCategory);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateCategory(
      String categoryId, String name, String description) async {
    state = const AsyncValue.loading();
    try {
      // Get current category first to preserve fields we're not changing
      final currentCategory =
          await _repository.getCategoryById(categoryId).first;
      if (currentCategory == null) {
        state = AsyncValue.error('Category not found', StackTrace.current);
        return false;
      }

      final updatedCategory = currentCategory.copyWith(
        name: name,
        description: description.isNotEmpty ? description : null,
      );

      await _repository.updateCategory(updatedCategory);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(categoryId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> initializeDefaultCategories() async {
    state = const AsyncValue.loading();
    try {
      await _repository.initializeDefaultCategoriesIfNeeded();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Provider for CategoryController
final categoryControllerProvider =
    StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryController(repository);
});

// Provider untuk semua kategori (untuk halaman admin)
final allCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAllCategories();
});

// Provider untuk kategori berdasarkan ID
final categoryByIdProvider =
    StreamProvider.family<CategoryModel?, String>((ref, categoryId) {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(categoryId);
});