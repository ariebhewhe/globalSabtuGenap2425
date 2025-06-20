import 'package:cloud_firestore/cloud_firestore.dart';

class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  PaginatedResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
  });
}
