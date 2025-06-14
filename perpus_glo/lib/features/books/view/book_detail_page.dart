import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perpusglo/features/borrow/providers/borrow_provider.dart' as borrow;
import '../../../common/widgets/loading_indicator.dart';
import '../model/book_model.dart';
import '../providers/book_provider.dart';
import '../../auth/providers/auth_provider.dart';

// Ubah dari ConsumerWidget menjadi ConsumerStatefulWidget
class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

// Tambahkan class State
class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(bookByIdProvider(widget.bookId));
    final borrowState = ref.watch(borrow.borrowControllerProvider);
    final userAsync = ref.watch(currentUserProvider);

    final isBookPendingAsync = ref.watch(borrow.isBookPendingProvider(widget.bookId));
    final isBookBorrowedAsync =
        ref.watch(borrow.isBookBorrowedProvider(widget.bookId));

// Debugging pendingBooks
    userAsync.whenData((user) {
      if (user != null) {
        print("Current user pendingBooks: ${user.pendingBooks}");
        print("Current user borrowedBooks: ${user.borrowedBooks}");
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Buku'),
      ),
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return const Center(
              child: Text('Buku tidak ditemukan'),
            );
          }

          return _buildBookDetail(context, book);
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      // Tombol untuk meminjam atau mengembalikan buku
      bottomNavigationBar: bookAsync.when(
        data: (book) {
          if (book == null) return const SizedBox.shrink();

          return userAsync.when(
            data: (user) {
              // Tambahkan pengecekan untuk pendingBooks
              final bool isBookBorrowed =
                  user?.borrowedBooks.contains(widget.bookId) ?? false;
              final bool isBookPending =
                  user?.pendingBooks.contains(widget.bookId) ?? false;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: borrowState.isLoading ||
                          (!book.isAvailable &&
                              !isBookBorrowed &&
                              !isBookPending) ||
                          isBookPending // Disable button jika sudah pending
                      ? null
                      : () async {
                          if (isBookBorrowed) {
                            // Konfirmasi pengembalian buku
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Kembalikan Buku'),
                                content: const Text(
                                    'Apakah Anda yakin ingin mengembalikan buku ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('BATAL'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('KEMBALIKAN'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await ref
                                  .read(borrow.borrowControllerProvider.notifier)
                                  .returnBook(widget.bookId);
                            }
                          } else {
                            await ref
                                .read(borrow.borrowControllerProvider.notifier)
                                .borrowBook(widget.bookId);

                            // Show success dialog for pending request
                            if (mounted && !borrowState.hasError) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Permintaan Berhasil'),
                                  content: const Text(
                                    'Permintaan peminjaman buku berhasil dikirim. '
                                    'Silakan tunggu konfirmasi dari pustakawan.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBookPending
                        ? Colors.amber
                        : (isBookBorrowed ? Colors.orange : Colors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: borrowState.isLoading
                      ? const LoadingIndicator(color: Colors.white)
                      : Text(
                          isBookPending
                              ? 'MENUNGGU KONFIRMASI'
                              : (isBookBorrowed
                                  ? 'KEMBALIKAN BUKU'
                                  : 'PINJAM BUKU'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              );
            },
            loading: () => const SizedBox(
                height: 80, child: Center(child: LoadingIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBookDetail(BuildContext context, BookModel book) {
    final dateFormat = DateFormat('dd MMMM yyyy');
    final borrowState = ref.watch(borrow.borrowControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover and Basic Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverUrl,
                  width: 120,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${book.author}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.category,
                      'Kategori',
                      book.category,
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Tanggal terbit',
                      dateFormat.format(book.publishedDate),
                    ),
                    _buildInfoRow(
                      Icons.book,
                      'Ketersediaan',
                      '${book.availableStock} / ${book.totalStock}',
                      iconColor: book.isAvailable ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description section
          const Text(
            'Deskripsi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Error message if any
          if (borrowState.hasError)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${borrowState.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}