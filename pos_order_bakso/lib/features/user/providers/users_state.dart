import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jamal/data/models/user_model.dart';

class UsersState {
  final List<UserModel> users;
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.errorMessage,
    this.isLoadingMore = false,
    this.lastDocument,
  });

  UsersState copyWith({
    List<UserModel>? users,
    bool? isLoading,
    bool? hasMore,
    String? errorMessage,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}
