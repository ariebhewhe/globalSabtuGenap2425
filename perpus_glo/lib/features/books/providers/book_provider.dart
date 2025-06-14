import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/book_repository.dart';
import '../model/book_model.dart';

// Provider untuk stream daftar buku
final booksProvider = StreamProvider<List<BookModel>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBooks();
});

// Provider untuk buku berdasarkan kategori
final booksByCategoryProvider =
    StreamProvider.family<List<BookModel>, String>((ref, category) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBooksByCategory(category);
});

// Provider untuk pencarian buku
final bookSearchProvider =
    StreamProvider.family<List<BookModel>, String>((ref, query) {
  if (query.isEmpty) {
    return ref.watch(booksProvider.stream);
  }
  final repository = ref.watch(bookRepositoryProvider);
  return repository.searchBooks(query);
});

// Provider untuk buku berdasarkan ID
final bookByIdProvider =
    FutureProvider.family<BookModel?, String>((ref, id) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBookById(id);
});

// Provider untuk daftar kategori
final bookCategoriesProvider = FutureProvider<List<String>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getCategories();
});

final booksCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBooksCount();
});

class BookController extends StateNotifier<AsyncValue<void>> {
  final BookRepository _repository;

  BookController(this._repository) : super(const AsyncValue.data(null));

  // Add book for admin
  Future<bool> addBook(BookModel book) async {
    state = const AsyncValue.loading();
    try {
      // Saat menambahkan buku, id seharusnya tidak ada
      final bookWithoutId = book.copyWith(id: null);
      final newBookId = await _repository.addBook(bookWithoutId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateBook(String bookId, BookModel book) async {
    state = const AsyncValue.loading();
    try {
      // Saat update, pastikan id sesuai dengan parameter
      final bookWithId = book.copyWith(id: bookId);
      await _repository.updateBook(bookWithId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Delete book for admin
  Future<bool> deleteBook(String bookId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBook(bookId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      print('Error in deleteBook: $e');
      return false;
    }
  }
}

// Provider untuk aksi peminjaman & pengembalian buku
// class BorrowController extends StateNotifier<AsyncValue<void>> {
//   final BookRepository _repository;

//   BorrowController(this._repository) : super(const AsyncValue.data(null));

//   Future<bool> borrowBook(String bookId) async {
//     state = const AsyncValue.loading();
//     try {
//       await _repository.borrowBook(bookId);
//       state = const AsyncValue.data(null);
//       return true;
//     } catch (e, stack) {
//       state = AsyncValue.error(e, stack);
//       return false;
//     }
//   }

//   Future<bool> returnBook(String bookId) async {
//     state = const AsyncValue.loading();
//     try {
//       await _repository.returnBook(bookId);
//       state = const AsyncValue.data(null);
//       return true;
//     } catch (e, stack) {
//       state = AsyncValue.error(e, stack);
//       return false;
//     }
//   }
// }

final bookControllerProvider =
    StateNotifierProvider<BookController, AsyncValue<void>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return BookController(repository);
});

// final borrowControllerProvider =
//     StateNotifierProvider<BorrowController, AsyncValue<void>>((ref) {
//   final repository = ref.watch(bookRepositoryProvider);
//   return BorrowController(repository);
// });

// Tambahkan providers berikut

// Provider for popular books
final popularBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final bookRepository = ref.watch(bookRepositoryProvider);
  return bookRepository.getPopularBooks();
});

// Provider for latest books
final latestBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getLatestBooks(limit: 10);
});

// Provider untuk memeriksa apakah buku sedang dalam peminjaman aktif
final isBookActiveBorrowedProvider = FutureProvider.family<bool, String>((ref, bookId) async {
  final borrowsRef = FirebaseFirestore.instance.collection('borrows');
  final snapshot = await borrowsRef
      .where('bookId', isEqualTo: bookId)
      .where('status', whereIn: ['active', 'overdue'])
      .limit(1)
      .get();
      
  return snapshot.docs.isNotEmpty;
});