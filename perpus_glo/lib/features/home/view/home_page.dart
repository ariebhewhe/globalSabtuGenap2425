import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../../books/model/book_model.dart';
import '../../books/providers/book_provider.dart';
import '../../borrow/model/borrow_model.dart';
import '../../borrow/providers/borrow_provider.dart';
import '../../categories/model/category_model.dart';
import '../../categories/providers/category_provider.dart';
import '../../profile/providers/profile_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final userName = profileAsync.maybeWhen(
      data: (profile) => profile?.name ?? 'Pengguna',
      orElse: () => 'Pengguna',
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Refresh data
            ref.refresh(popularBooksProvider);
            ref.refresh(latestBooksProvider);
            ref.refresh(activeBorrowsProvider);
            ref.refresh(categoriesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                pinned: false,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // jarak antara app bar dan search bar
                toolbarHeight: 5,

                // Search bar
                // bottom: PreferredSize(
                //   preferredSize: const Size.fromHeight(60),
                //   child: Container(
                //     height: 50,
                //     margin:
                //         const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(25),
                //       boxShadow: [
                //         BoxShadow(
                //           color: Colors.black.withOpacity(0.1),
                //           blurRadius: 8,
                //           offset: const Offset(0, 2),
                //         ),
                //       ],
                //     ),
                //     child: GestureDetector(
                //       onTap: () => context.push('/search'),
                //       child: AbsorbPointer(
                //         child: TextField(
                //           decoration: InputDecoration(
                //             hintText: 'Cari buku...',
                //             prefixIcon: const Icon(Icons.search),
                //             border: InputBorder.none,
                //             contentPadding: const EdgeInsets.symmetric(
                //                 horizontal: 16, vertical: 14),
                //             filled: true,
                //             fillColor: Colors.white,
                //             enabledBorder: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(25),
                //               borderSide: BorderSide.none,
                //             ),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
              ),

              // Main content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active borrows
                      const SizedBox(height: 24),
                      _buildActiveBorrowsSection(context, ref),

                      // Popular books section
                      const SizedBox(height: 24),
                      _buildPopularBooksSection(context, ref),

                      // Categories section
                      const SizedBox(height: 24),
                      _buildCategoriesSection(context, ref),

                      // Latest books section
                      const SizedBox(height: 24),
                      _buildLatestBooksSection(context, ref),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBorrowsSection(BuildContext context, WidgetRef ref) {
    final borrowsAsync = ref.watch(activeBorrowsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pinjaman Aktif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/borrows'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: borrowsAsync.when(
            data: (borrows) {
              if (borrows.isEmpty) {
                return _buildEmptyBorrows();
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: borrows.length,
                itemBuilder: (context, index) {
                  return _buildActiveBorrowCard(context, borrows[index]);
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
  }

  Widget _buildEmptyBorrows() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada pinjaman aktif',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBorrowCard(BuildContext context, BorrowModel borrow) {
    final dueDate = borrow.dueDate.difference(DateTime.now()).inDays;
    final isAlmostDue = dueDate <= 3;

    return GestureDetector(
      onTap: () => context.push('/borrow/${borrow.id}'),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAlmostDue ? Colors.red : Colors.grey[300]!,
            width: isAlmostDue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Book cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: borrow.bookCover != null
                  ? Image.network(
                      borrow.bookCover!,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 100,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 100,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.book),
                    ),
            ),
            const SizedBox(width: 12),

            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    borrow.bookTitle ?? 'Judul tidak tersedia',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    borrow.booksAuthor ?? 'Penulis tidak tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isAlmostDue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dueDate <= 0
                              ? 'Jatuh tempo hari ini!'
                              : 'Jatuh tempo dalam $dueDate hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAlmostDue ? Colors.red : Colors.grey[600],
                            fontWeight: isAlmostDue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBooksSection(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(popularBooksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Buku Populer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/books'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: booksAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return const Center(child: Text('Tidak ada buku'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return _buildBookCard(context, books[index]);
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
  }

  Widget _buildCategoriesSection(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/categories'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('Tidak ada kategori'));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(context, categories[index]);
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
  }

  Widget _buildLatestBooksSection(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(latestBooksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Buku Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/books'),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        booksAsync.when(
          data: (books) {
            if (books.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Tidak ada buku')),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: books.length > 5 ? 5 : books.length,
              itemBuilder: (context, index) {
                return _buildHorizontalBookCard(context, books[index]);
              },
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: LoadingIndicator()),
          ),
          error: (error, _) => SizedBox(
            height: 200,
            child: Center(child: Text('Error: ${error.toString()}')),
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(BuildContext context, BookModel book) {
    return GestureDetector(
      onTap: () => context.push('/books/${book.id}'),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      width: 120,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        height: 160,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 120,
                      height: 160,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.book),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalBookCard(BuildContext context, BookModel book) {
    return GestureDetector(
      onTap: () => context.push('/books/${book.id}'),
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Book cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: book.coverUrl != null
                  ? Image.network(
                      book.coverUrl!,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 100,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 100,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.book),
                    ),
            ),
            // Book details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Availability indicator
            Container(
              width: 12,
              decoration: BoxDecoration(
                color: book.isAvailable ? Colors.green : Colors.red,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryModel category) {
    return GestureDetector(
      onTap: () => context.push('/categories/${category.id}'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _getCategoryColor(category.name),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Add overlay pattern or icon if desired
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                _getCategoryIcon(category.name),
                size: 60,
                color: Colors.white.withOpacity(0.2),
              ),
            ),

            // Category name
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
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