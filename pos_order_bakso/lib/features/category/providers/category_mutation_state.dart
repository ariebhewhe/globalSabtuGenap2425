import 'package:jamal/data/models/category_model.dart';

class CategoryMutationState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;
  final CategoryModel? categoryModel;

  CategoryMutationState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
    this.categoryModel,
  });

  CategoryMutationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    CategoryModel? categoryModel,
  }) {
    return CategoryMutationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      categoryModel: categoryModel,
    );
  }
}
