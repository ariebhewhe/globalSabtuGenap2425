import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamal/data/models/category_model.dart';

class CategoriesState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  CategoriesState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
