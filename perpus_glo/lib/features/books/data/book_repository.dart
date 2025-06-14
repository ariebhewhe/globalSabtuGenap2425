import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../model/book_model.dart';

// BookRepository digunakan untuk mengambil data buku dari Firestore
class BookRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;

  // Collection references
  CollectionReference get _booksRef => _firestore.collection('books');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get all books
  Stream<List<BookModel>> getBooks() {
    return _booksRef.orderBy('title').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookModel.fromJson(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>});
      }).toList();
    });
  }

  // Get books by category
  Stream<List<BookModel>> getBooksByCategory(String categoryId) {
    return _booksRef
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    });
  }

  // Search books
  Stream<List<BookModel>> searchBooks(String query) {
    // Firebase tidak mendukung search text secara native
    // Solusi sederhana: ambil semua buku dan filter di client side
    return _booksRef.snapshots().map((snapshot) {
      final allBooks = snapshot.docs.map((doc) {
        return BookModel.fromJson(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>});
      }).toList();

      return allBooks.where((book) {
        final titleLower = book.title.toLowerCase();
        final authorLower = book.author.toLowerCase();
        final queryLower = query.toLowerCase();

        return titleLower.contains(queryLower) ||
            authorLower.contains(queryLower);
      }).toList();
    });
  }

  // Get book by id
  Future<BookModel?> getBookById(String bookId) async {
    final doc = await _booksRef.doc(bookId).get();

    if (doc.exists) {
      return BookModel.fromJson(
          {'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }

    return null;
  }

  // Borrow book
  Future<void> borrowBook(String bookId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    // Transaction untuk memastikan data konsisten
    return _firestore.runTransaction((transaction) async {
      // 1. Get book document
      final bookDoc = await transaction.get(_booksRef.doc(bookId));
      if (!bookDoc.exists) {
        throw Exception('Buku tidak ditemukan');
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;
      final availableStock = bookData['availableStock'] as int;

      // 2. Check stock
      if (availableStock <= 0) {
        throw Exception('Stok buku tidak tersedia');
      }

      // 3. Get user document
      final userDoc = await transaction.get(_usersRef.doc(userId));
      if (!userDoc.exists) {
        throw Exception('User tidak ditemukan');
      }

      // 4. Get current borrowed books
      final userData = userDoc.data() as Map<String, dynamic>;
      final borrowedBooks = List<String>.from(userData['borrowedBooks'] ?? []);

      // 5. Check if user already borrowed this book
      if (borrowedBooks.contains(bookId)) {
        throw Exception('Buku sudah dipinjam');
      }

      // 6. Update book stock
      transaction.update(
          _booksRef.doc(bookId), {'availableStock': availableStock - 1});

      // 7. Add book to user's borrowedBooks
      borrowedBooks.add(bookId);
      transaction
          .update(_usersRef.doc(userId), {'borrowedBooks': borrowedBooks});
    });
  }

  // Return book
  Future<void> returnBook(String bookId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    return _firestore.runTransaction((transaction) async {
      // 1. Get book document
      final bookDoc = await transaction.get(_booksRef.doc(bookId));
      if (!bookDoc.exists) {
        throw Exception('Buku tidak ditemukan');
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;
      final availableStock = bookData['availableStock'] as int;
      final totalStock = bookData['totalStock'] as int;

      // 2. Check if stock would exceed total
      if (availableStock >= totalStock) {
        throw Exception('Semua buku sudah kembali');
      }

      // 3. Get user document
      final userDoc = await transaction.get(_usersRef.doc(userId));
      if (!userDoc.exists) {
        throw Exception('User tidak ditemukan');
      }

      // 4. Get current borrowed books
      final userData = userDoc.data() as Map<String, dynamic>;
      final borrowedBooks = List<String>.from(userData['borrowedBooks'] ?? []);

      // 5. Check if user has borrowed this book
      if (!borrowedBooks.contains(bookId)) {
        throw Exception('Buku tidak sedang dipinjam');
      }

      // 6. Update book stock
      transaction.update(
          _booksRef.doc(bookId), {'availableStock': availableStock + 1});

      // 7. Remove book from user's borrowedBooks
      borrowedBooks.remove(bookId);
      transaction
          .update(_usersRef.doc(userId), {'borrowedBooks': borrowedBooks});
    });
  }

  // Di book_repository.dart
  Stream<List<BookModel>> getPopularBooks({int limit = 10}) {
    print('Getting popular books without borrowCount field'); // Debug log

    // Metode dengan menghitung dari koleksi borrows
    return _firestore
        .collection('borrows')
        // Ambil semua peminjaman yang dikonfirmasi (status active, returned, overdue, pendingReturn)
        .where('status',
            whereIn: ['active', 'returned', 'overdue', 'pendingReturn'])
        .get()
        .asStream()
        .asyncMap((snapshot) async {
          print(
              'Found ${snapshot.docs.length} total borrow records'); // Debug log

          // Hitung frekuensi bookId
          final Map<String, int> bookFrequency = {};
          for (final doc in snapshot.docs) {
            final bookId = doc.data()['bookId'] as String?;
            if (bookId != null) {
              bookFrequency[bookId] = (bookFrequency[bookId] ?? 0) + 1;
            }
          }

          print(
              'Book frequency map created with ${bookFrequency.length} entries'); // Debug log

          // Daftar dari ids yang paling populer
          final popularBookIds = bookFrequency.entries
              .sorted((a, b) => b.value.compareTo(a.value))
              .take(limit)
              .map((e) => e.key)
              .toList();

          print('Popular book IDs: $popularBookIds'); // Debug log

          // Jika tidak ada buku populer, kembalikan list kosong
          if (popularBookIds.isEmpty) {
            print('No popular books found'); // Debug log
            return <BookModel>[];
          }

          // Ambil detail buku dari popularBookIds
          final booksSnapshot = await _booksRef
              .where(FieldPath.documentId, whereIn: popularBookIds)
              .get();

          print(
              'Retrieved ${booksSnapshot.docs.length} popular books'); // Debug log

          // Konversi ke BookModel
          final books = booksSnapshot.docs
              .map((doc) => BookModel.fromJson({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList();

          // Urutkan sesuai dengan popularitas
          books.sort((a, b) {
            final indexA = popularBookIds.indexOf(a.id!);
            final indexB = popularBookIds.indexOf(b.id!);
            return indexA.compareTo(indexB);
          });

          return books;
        });
  }

  Stream<List<BookModel>> getLatestBooks({required int limit}) {
    return _booksRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BookModel.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    });
  }

  // Get list of categories
  Future<List<String>> getCategories() async {
    final snapshot = await _firestore.collection('categories').get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  // getBooksCount
  Future<int> getBooksCount() async {
    final snapshot = await _booksRef.get();
    return snapshot.docs.length;
  }

  // Add book for admin
  Future<void> addBook(BookModel book) async {
    await _booksRef.add(book.toJson());
  }

  // Update book for admin
  Future<void> updateBook(BookModel book) async {
    if (book.id == null) {
      throw Exception('Book ID is required for update');
    }
    await _booksRef.doc(book.id).update(book.toJson());
  }

  // Delete book for admin
  Future<bool> deleteBook(String bookId) async {
    try {
      // Pertama, periksa apakah buku masih dipinjam
      final borrowsRef = _firestore.collection('borrows');
      final activeBorrows = await borrowsRef
          .where('bookId', isEqualTo: bookId)
          .where('status', whereIn: ['active', 'overdue'])
          .get();
      
      // Jika buku masih dipinjam, berikan error
      if (activeBorrows.docs.isNotEmpty) {
        throw Exception('Buku ini masih dipinjam oleh pengguna dan tidak dapat dihapus');
      }

      // Log aktivitas penghapusan buku
      await _firestore.collection('history').add({
        'userId': _auth.currentUser?.uid,
        'activityType': 'deleteBook',
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Menghapus buku dari sistem',
        'metadata': {
          'bookId': bookId,
          // Simpan data buku sebelum dihapus untuk history
          'bookInfo': await _booksRef.doc(bookId).get().then((doc) => doc.data()),
        },
      });

      // Hapus buku
      await _booksRef.doc(bookId).delete();
      return true;
    } catch (e) {
      print('Error deleting book: $e');
      rethrow; // Lempar kembali error untuk ditangani di controller
    }
  }
}

// Di extensions.dart atau file utility lainnya
extension IterableExtension<T> on Iterable<T> {
  List<T> sorted(Comparator<T> compare) {
    final List<T> list = toList();
    list.sort(compare);
    return list;
  }
}

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository();
});