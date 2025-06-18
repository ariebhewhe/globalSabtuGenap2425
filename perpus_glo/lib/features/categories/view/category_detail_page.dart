import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../../books/model/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../providers/category_provider.dart';

class CategoryDetailPage extends ConsumerWidget {
  final String categoryId;

  const CategoryDetailPage({
    super.key, 
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryProvider(categoryId));
    final booksByCategoryAsync = ref.watch(booksByCategoryProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: categoryAsync.when(
          data: (category) => Text(category?.name ?? 'Kategori'),
          loading: () => const Text('Memuat...'),
          error: (_, __) => const Text('Kategori'),
        ),
      ),
      body: categoryAsync.when(
        data: (category) {
          if (category == null) {
            return const Center(
              child: Text('Kategori tidak ditemukan'),
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                padding: const EdgeInsets.all(16),
                color: _getCategoryColor(category.name).withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category.name),
                          size: 32,
                          color: _getCategoryColor(category.name),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (category.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          category.description!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        '${category.bookCount} buku',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: _getCategoryColor(category.name),
                    ),
                  ],
                ),
              ),
              
              // Books in this category
              Expanded(
                child: booksByCategoryAsync.when(
                  data: (books) {
                    if (books.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada buku dalam kategori ini'),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _buildBookCard(context, book);
                      },
                    );
                  },
                  loading: () => const Center(child: LoadingIndicator()),
                  error: (error, _) => Center(
                    child: Text('Error: ${error.toString()}'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, BookModel book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/books/${book.id}'),
        child: Row(
          children: [
            // Book cover
            SizedBox(
              width: 80,
              height: 120,
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book),
                    ),
            ),
            
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          book.isAvailable ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: book.isAvailable ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.isAvailable ? 'Tersedia' : 'Tidak tersedia',
                          style: TextStyle(
                            color: book.isAvailable ? Colors.green : Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('science') || name.contains('sains')) {
      return Colors.blue;
    } else if (name.contains('fiction') || name.contains('fiksi')) {
      return Colors.purple;
    } else if (name.contains('history') || name.contains('sejarah')) {
      return Colors.brown;
    } else if (name.contains('business') || name.contains('bisnis')) {
      return Colors.orange;
    } else if (name.contains('technology') || name.contains('teknologi')) {
      return Colors.indigo;
    } else if (name.contains('art') || name.contains('seni')) {
      return Colors.pink;
    } else if (name.contains('cooking') || name.contains('masak')) {
      return Colors.red;
    } else if (name.contains('health') || name.contains('kesehatan')) {
      return Colors.green;
    } else if (name.contains('travel') || name.contains('wisata')) {
      return Colors.teal;
    } else if (name.contains('religion') || name.contains('agama')) {
      return Colors.deepPurple;
    } else if (name.contains('children') || name.contains('anak')) {
      return Colors.cyan;
    } else {
      // Random color based on the first character
      final charCode = name.isEmpty ? 0 : name.codeUnitAt(0);
      final colors = [
        Colors.blue,
        Colors.red,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
        Colors.amber,
        Colors.cyan,
      ];
      
      return colors[charCode % colors.length];
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('science') || name.contains('sains')) {
      return Icons.science;
    } else if (name.contains('fiction') || name.contains('fiksi')) {
      return Icons.auto_stories;
    } else if (name.contains('history') || name.contains('sejarah')) {
      return Icons.history_edu;
    } else if (name.contains('business') || name.contains('bisnis')) {
      return Icons.business;
    } else if (name.contains('technology') || name.contains('teknologi')) {
      return Icons.computer;
    } else if (name.contains('art') || name.contains('seni')) {
      return Icons.palette;
    } else if (name.contains('cooking') || name.contains('masak')) {
      return Icons.restaurant;
    } else if (name.contains('health') || name.contains('kesehatan')) {
      return Icons.favorite;
    } else if (name.contains('travel') || name.contains('wisata')) {
      return Icons.travel_explore;
    } else if (name.contains('religion') || name.contains('agama')) {
      return Icons.church;
    } else if (name.contains('children') || name.contains('anak')) {
      return Icons.child_care;
    } else {
      return Icons.category;
    }
  }
}