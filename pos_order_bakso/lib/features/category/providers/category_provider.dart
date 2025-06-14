import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/repositories/category_repo.dart';
import 'package:jamal/features/category/providers/category_state.dart';

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepo _categoryRepo;
  final String _id;

  CategoryNotifier(this._categoryRepo, this._id) : super(CategoryState()) {
    if (_id.isNotEmpty) {
      getCategoryById(_id);
    }
  }

  Future<void> getCategoryById(String id) async {
    state = state.copyWith(isLoading: true);

    final result = await _categoryRepo.getCategoryById(id);

    result.fold(
      (error) =>
          state = state.copyWith(isLoading: false, errorMessage: error.message),
      (success) =>
          state = state.copyWith(isLoading: false, category: success.data),
    );
  }

  Future<void> refreshCategory() async {
    if (_id.isNotEmpty) {
      await getCategoryById(_id);
    }
  }
}

final categoryProvider =
    StateNotifierProvider.family<CategoryNotifier, CategoryState, String>((
      ref,
      id,
    ) {
      final CategoryRepo categoryRepo = ref.watch(categoryRepoProvider);
      return CategoryNotifier(categoryRepo, id);
    });

// * Provider untuk menyimpan ID menu item yang sedang aktif
final activeCategoryIdProvider = StateProvider<String?>((ref) => null);

// * Auto-refresh provider ketika ID berubah
final activeCategoryProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
      final CategoryRepo categoryRepo = ref.watch(categoryRepoProvider);
      final id = ref.watch(activeCategoryIdProvider);

      return CategoryNotifier(categoryRepo, id ?? '');
    });
