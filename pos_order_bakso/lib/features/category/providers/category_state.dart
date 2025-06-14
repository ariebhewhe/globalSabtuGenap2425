import 'package:jamal/data/models/category_model.dart';

class CategoryState {
  final bool isLoading;
  final CategoryModel? category;
  final String? successMessage;
  final String? errorMessage;

  CategoryState({
    this.isLoading = false,
    this.category,
    this.successMessage,
    this.errorMessage,
  });

  CategoryState copyWith({
    bool? isLoading,
    CategoryModel? category,
    String? successMessage,
    String? errorMessage,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      category: category ?? this.category,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}
