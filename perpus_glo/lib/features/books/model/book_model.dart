import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String? id; // Ubah menjadi nullable (opsional)
  final String title;
  final String author;
  final String coverUrl;
  final String description;
  final String category;
  final int availableStock;
  final int totalStock;
  final DateTime publishedDate;

  BookModel({
    this.id, // Buat id menjadi opsional
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.description,
    required this.category,
    required this.availableStock,
    required this.totalStock,
    required this.publishedDate,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] as String?, // Tambahkan id jika ada
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['coverUrl'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      availableStock: json['availableStock'] as int,
      totalStock: json['totalStock'] as int,
      publishedDate: (json['publishedDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'description': description,
      'category': category,
      'availableStock': availableStock,
      'totalStock': totalStock,
      'publishedDate': publishedDate,
    };
    
    // Hanya tambahkan id ke map jika tidak null
    if (id != null) map['id'] = id!;
    
    return map;
  }

  // Method untuk membuat salinan objek dengan nilai yang diubah
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? description,
    String? category,
    int? availableStock,
    int? totalStock,
    DateTime? publishedDate,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      category: category ?? this.category,
      availableStock: availableStock ?? this.availableStock,
      totalStock: totalStock ?? this.totalStock,
      publishedDate: publishedDate ?? this.publishedDate,
    );
  }

  bool get isAvailable => availableStock > 0;
}