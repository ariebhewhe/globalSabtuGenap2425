import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perpusglo/features/notification/model/notification_model.dart';
import 'package:perpusglo/features/notification/providers/notification_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../model/borrow_model.dart';

class BorrowRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;
  final Ref _ref; // Tambahkan variabel ref

  // Ubah constructor untuk menerima ref
  BorrowRepository(this._ref);
  // Collection references
  CollectionReference get _borrowsRef => _firestore.collection('borrows');
  CollectionReference get _booksRef => _firestore.collection('books');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get user's borrow history
  Stream<List<BorrowModel>> getUserBorrowHistory() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _borrowsRef
        .where('userId', isEqualTo: userId)
        .orderBy('requestDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<BorrowModel> borrows = [];
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Check if book is overdue but status hasn't been updated yet
        if (data['status'] == 'active' && data['returnDate'] == null) {
          final dueDate = (data['dueDate'] as Timestamp).toDate();
          if (now.isAfter(dueDate)) {
            // Normalisasi tanggal untuk perhitungan hari yang lebih akurat
            final DateTime normalizedDueDate =
                DateTime(dueDate.year, dueDate.month, dueDate.day);
            final DateTime normalizedNow =
                DateTime(now.year, now.month, now.day);

            // Hitung hari terlambat
            final daysLate = normalizedNow.difference(normalizedDueDate).inDays;

            // Pastikan minimal 1 hari jika sudah lewat tenggat
            final effectiveDaysLate = daysLate > 0 ? daysLate : 1;

            // Denda per hari = Rp 2.000
            final fine = effectiveDaysLate * 2000.0;

            print(
                'Detected overdue book in history: ${doc.id}, Days late: $effectiveDaysLate, Fine: $fine');

            // Update document
            await _borrowsRef.doc(doc.id).update({
              'status': 'overdue',
              'fine': fine,
              'isPaid': false,
            });

            // Update user's total fine
            final userDoc = await _usersRef.doc(userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final currentFine = _toDouble(userData['fineAmount']);
              await _usersRef.doc(userId).update({
                'fineAmount': currentFine + fine,
              });

              print(
                  'Updated user $userId fine: $currentFine + $fine = ${currentFine + fine}');
            }

            // Update data lokal untuk UI
            data['status'] = 'overdue';
            data['fine'] = fine;
            data['isPaid'] = false;
          }
        }
        // TAMBAHAN: Jika buku sudah returned tapi status tidak konsisten, perbaiki
        else if ((data['status'] == 'overdue' ||
                data['status'] == 'pendingReturn') &&
            data['returnDate'] != null &&
            data['confirmReturnDate'] != null) {
          // Buku sudah dikembalikan dan dikonfirmasi, tapi status tidak returned
          print(
              'Fixing inconsistent status for ${doc.id}: marking as returned');
          await _borrowsRef.doc(doc.id).update({
            'status': 'returned',
            'isReturned': true,
            'isReturnLocked': true,
          });

          // Update lokal data
          data['status'] = 'returned';
          data['isReturned'] = true;
          data['isReturnLocked'] = true;
        }
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final borrowModel = BorrowModel.fromJson({
          'id': doc.id,
          ...data,
        });

        // Fetch book information for UI
        try {
          final bookDoc = await _booksRef.doc(borrowModel.bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final bookWithInfo = borrowModel.copyWith(
              bookTitle: bookData['title'] as String,
              bookCover: bookData['coverUrl'] as String,
            );
            borrows.add(bookWithInfo);
          } else {
            borrows.add(borrowModel);
          }
        } catch (e) {
          // If book fetch fails, still add the borrow record
          borrows.add(borrowModel);
        }
      }

      return borrows;
    });
  }

  Stream<List<BorrowModel>> getUserActiveBorrows(String userId) {
    print('Getting active borrows for user: $userId'); // Debug log

    return _borrowsRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      print('Found ${snapshot.docs.length} active borrows'); // Debug log

      final List<BorrowModel> borrows = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final borrowModel = BorrowModel.fromJson({
          'id': doc.id,
          ...data,
        });

        // Tambahkan info buku
        try {
          final bookDoc = await _booksRef.doc(borrowModel.bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final bookWithInfo = borrowModel.copyWith(
              bookTitle: bookData['title'] as String?,
              bookCover: bookData['coverUrl'] as String?,
              // booksAuthor: bookData['author'] as String?,
            );
            borrows.add(bookWithInfo);
          } else {
            borrows.add(borrowModel);
          }
        } catch (e) {
          print('Error fetching book info: $e');
          borrows.add(borrowModel);
        }
      }

      return borrows;
    });
  }

  Stream<List<BorrowModel>> getAllBorrows() {
    // Admin should see all borrows
    print('Getting all borrows...');

    return _borrowsRef
        .orderBy('requestDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      print('Fetched ${snapshot.docs.length} borrows');

      final List<BorrowModel> borrows = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('Document ID: ${doc.id}, Status: ${data['status']}');

        // Buat model
        final borrowModel = BorrowModel.fromJson({
          'id': doc.id,
          ...data,
        });

        // Tambahkan info buku dan user
        try {
          final bookDoc = await _booksRef.doc(borrowModel.bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final borrowWithBookInfo = borrowModel.copyWith(
              bookTitle: bookData['title'] as String?,
              bookCover: bookData['coverUrl'] as String?,
              // booksAuthor: bookData['author'] as String?,
            );

            // Fetch user info
            final userDoc = await _usersRef.doc(borrowModel.userId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              borrows.add(borrowWithBookInfo.copyWith(
                userName: userData['name'] as String?,
              ));
            } else {
              borrows.add(borrowWithBookInfo);
            }
          } else {
            borrows.add(borrowModel);
          }
        } catch (e) {
          print('Error fetching details: $e');
          borrows.add(borrowModel);
        }
      }

      return borrows;
    });
  }

  // getActiveBorrows
  Stream<List<BorrowModel>> getActiveBorrows() {
    return _borrowsRef
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: BorrowStatus.active)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                BorrowModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get borrow by ID
  Future<BorrowModel?> getBorrowById(String borrowId) async {
    try {
      final borrowDoc = await _borrowsRef.doc(borrowId).get();

      if (!borrowDoc.exists) return null;

      final borrowData = borrowDoc.data() as Map<String, dynamic>;

      // Get book details
      String? bookTitle, booksAuthor, bookCover;
      if (borrowData['bookId'] != null) {
        final bookDoc =
            await _booksRef.doc(borrowData['bookId'] as String).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data() as Map<String, dynamic>;
          bookTitle = bookData['title'] as String?;
          booksAuthor = bookData['author'] as String?;
          bookCover = bookData['coverUrl'] as String?;
        }
      }

      // Get user details
      String? userName, userEmail;
      if (borrowData['userId'] != null) {
        final userDoc =
            await _usersRef.doc(borrowData['userId'] as String).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['name'] as String?;
          userEmail = userData['email'] as String?; // Tambahkan ini
        }
      }

      return BorrowModel.fromJson({
        'id': borrowDoc.id,
        ...borrowData,
        'bookTitle': bookTitle,
        'booksAuthor': booksAuthor,
        'bookCover': bookCover,
        'userName': userName,
        'userEmail': userEmail, // Tambahkan ini
      });
    } catch (e) {
      print('Error getting borrow: $e');
      return null;
    }
  }

  // Borrow a book (request borrowing)
  Future<String> borrowBook(String bookId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    // Generate borrowId di luar transaction
    String borrowId = _borrowsRef.doc().id;

    try {
      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        // 1. Get book document
        final bookDoc = await transaction.get(_booksRef.doc(bookId));
        if (!bookDoc.exists) {
          throw Exception('Buku tidak ditemukan');
        }

        final bookData = bookDoc.data() as Map<String, dynamic>;
        final availableStock = bookData['availableStock'] as int;

        // 2. Check stock (tetap cek walaupun belum mengurangi stok)
        if (availableStock <= 0) {
          throw Exception('Stok buku tidak tersedia');
        }

        // 3. Get user document
        final userDoc = await transaction.get(_usersRef.doc(userId));
        if (!userDoc.exists) {
          throw Exception('User tidak ditemukan');
        }

        // 4. Get current pending and borrowed books
        final userData = userDoc.data() as Map<String, dynamic>;
        final pendingBooks = List<String>.from(userData['pendingBooks'] ?? []);
        final borrowedBooks =
            List<String>.from(userData['borrowedBooks'] ?? []);

        // 5. Check if user already requested or borrowed this book
        if (pendingBooks.contains(bookId)) {
          throw Exception(
              'Permintaan peminjaman untuk buku ini sudah diajukan');
        }
        if (borrowedBooks.contains(bookId)) {
          throw Exception('Buku sudah dipinjam');
        }

        // 6. Create borrow record with consistent timestamps
        final now = DateTime.now();
        final dueDate =
            now.add(const Duration(days: 7)); // 7 weeks borrowing period

        final borrowData = {
          'userId': userId,
          'bookId': bookId,
          'borrowDate': now, // Set borrow date to now
          'dueDate': dueDate,
          'status': 'pending', // Status pending, menunggu konfirmasi
          'isPaid': false, // Denda belum dibayar jika ada
          'fine': 0.0, // Denda awal 0 jika belum ada keterlambatan
          'requestDate': now, // Tambahkan tanggal pengajuan
        };

        // 7. Add book to user's pendingBooks
        pendingBooks.add(bookId);
        transaction
            .update(_usersRef.doc(userId), {'pendingBooks': pendingBooks});

        // 8. Create borrow document
        transaction.set(_borrowsRef.doc(borrowId), borrowData);
      });

      print("Berhasil membuat record peminjaman dengan ID: $borrowId");

      // TAMBAHKAN: Notifikasi untuk user setelah peminjaman berhasil dibuat
      try {
        // Ambil data buku untuk notifikasi
        final bookDoc = await _booksRef.doc(bookId).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data() as Map<String, dynamic>;
          final bookTitle = bookData['title'] as String;

          // Kirim notifikasi ke user
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.createNotificationForUser(
            userId: userId,
            title: 'Permintaan Peminjaman',
            body:
                'Permintaan peminjaman untuk buku "$bookTitle" telah dikirim. Menunggu konfirmasi pustakawan.',
            type: NotificationType.borrowRequest,
            data: {
              'borrowId': borrowId,
              'bookId': bookId,
            },
          );

          // Kirim notifikasi ke admin/pustakawan
          await notificationService.createNotificationForAdmins(
            title: 'Permintaan Peminjaman Baru',
            body: 'Ada permintaan peminjaman baru untuk buku "$bookTitle"',
            type: NotificationType.borrowRequestAdmin,
            data: {
              'borrowId': borrowId,
              'bookId': bookId,
              'userId': userId,
            },
          );
        }
      } catch (e) {
        print('Error sending borrow notification: $e');
        // Tetap lanjutkan meskipun notifikasi gagal
      }

      return borrowId;
    } catch (e) {
      print("Error saat meminjam buku: $e");
      throw Exception('Gagal meminjam buku: ${e.toString()}');
    }
  }

// Di BorrowRepository, tambahkan metode baru
  // Di borrow_repository.dart, perbaiki metode checkOverdueBooks
  Future<void> checkOverdueBooks() async {
    try {
      final now = DateTime.now();
      print('Running checkOverdueBooks at ${now.toString()}');

      // Ambil semua peminjaman dengan status 'active' dan dueDate < now
      final overdueQuery = await _borrowsRef
          .where('status', isEqualTo: 'active')
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .where('isPaid', isEqualTo: false)
          .where('returnDate', isNull: true)
          .where('confirmReturnDate',
              isNull:
                  true) // TAMBAHAN: Pastikan buku belum dikonfirmasi kembali
          .where('isReturned',
              isNotEqualTo:
                  true) // TAMBAHAN: Pastikan tidak ditandai sebagai dikembalikan
          .get();

      print('Found ${overdueQuery.docs.length} overdue books');

      // Jika tidak ada yang terlambat, selesai
      if (overdueQuery.docs.isEmpty) return;

      // Gunakan batch untuk update banyak dokumen sekaligus
      final batch = _firestore.batch();
      final userFinesToUpdate = <String, double>{};

      for (final doc in overdueQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final userId = data['userId'] as String;

        // Normalisasi tanggal untuk perhitungan hari yang lebih akurat
        final DateTime normalizedDueDate =
            DateTime(dueDate.year, dueDate.month, dueDate.day);
        final DateTime normalizedNow = DateTime(now.year, now.month, now.day);

        // Hitung hari terlambat
        final daysLate = normalizedNow.difference(normalizedDueDate).inDays;

        // Pastikan minimal 1 hari jika sudah lewat tenggat
        final effectiveDaysLate = daysLate > 0 ? daysLate : 1;

        // Denda per hari = Rp 2.000
        final fine = effectiveDaysLate * 2000.0;

        print(
            'Book overdue: ${doc.id}, Days late: $effectiveDaysLate, Fine: $fine');

        // Update status menjadi overdue dan tambahkan denda
        batch.update(doc.reference, {
          'status': 'overdue',
          'fine': fine,
          'isPaid': false,
        });

        // Tambahkan denda ke total denda user
        userFinesToUpdate[userId] = (userFinesToUpdate[userId] ?? 0) + fine;
      }

      // Update denda untuk setiap user yang terlambat
      for (final entry in userFinesToUpdate.entries) {
        final userId = entry.key;
        final additionalFine = entry.value;

        // Ambil data user untuk mendapatkan fineAmount saat ini
        final userDoc = await _usersRef.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentFine = _toDouble(userData['fineAmount']);

          // Update total denda user
          batch.update(_usersRef.doc(userId), {
            'fineAmount': currentFine + additionalFine,
          });

          print(
              'Updating user $userId fine: $currentFine + $additionalFine = ${currentFine + additionalFine}');
        }
      }

      // Commit semua perubahan
      await batch.commit();
      print(
          'Successfully updated ${overdueQuery.docs.length} overdue books and user fines');

      // Kirim notifikasi ke pengguna yang bukunya terlambat
      for (final doc in overdueQuery.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'] as String;
          final bookId = data['bookId'] as String;
          final fine = data['fine'] ?? 0.0;

          // Ambil data buku untuk notifikasi
          final bookDoc = await _booksRef.doc(bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final bookTitle = bookData['title'] as String;

            // Kirim notifikasi
            final notificationService = _ref.read(notificationServiceProvider);
            await notificationService.createNotificationForUser(
              userId: userId,
              title: 'Buku Terlambat',
              body:
                  'Buku "$bookTitle" telah melewati tenggat waktu pengembalian. Denda: Rp ${fine.toStringAsFixed(0)}',
              type: NotificationType.overdue,
              data: {
                'borrowId': doc.id,
                'bookId': bookId,
                'fine': fine.toString(),
              },
            );

            print(
                'Sent overdue notification to user $userId for book $bookTitle');
          }
        } catch (notifError) {
          print('Error sending overdue notification: $notifError');
        }
      }
    } catch (e) {
      print('Error checking overdue books: $e');
    }
  }

// Di borrow_repository.dart
  Stream<List<BorrowModel>> getPendingReturnBorrows() {
    // Debug untuk melihat jika fungsi dipanggil
    print('Getting pending return borrows...');

    return _borrowsRef
        .where('status',
            isEqualTo: 'pendingReturn') // Pastikan string persis sama
        .orderBy('returnRequestDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Debug untuk melihat jumlah dokumen
      print('Fetched ${snapshot.docs.length} pending return borrows');

      final List<BorrowModel> borrows = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Debug status yang diterima dari database
        print('Borrow ID: ${doc.id}, Status: ${data['status']}');

        // Buat model dengan ID dokumen sebagai bagian dari data
        final borrowJson = {
          'id': doc.id,
          ...data,
        };

        // Buat model dasar
        BorrowModel borrowModel = BorrowModel.fromJson(borrowJson);

        // Tambahkan informasi buku
        try {
          final bookDoc = await _booksRef.doc(borrowModel.bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            borrowModel = borrowModel.copyWith(
              bookTitle: bookData['title'] as String?,
              bookCover: bookData['coverUrl'] as String?,
              // booksAuthor: bookData['author'] as String?,
            );
          }
        } catch (e) {
          print('Error fetching book details: $e');
        }

        // Tambahkan informasi user
        try {
          final userDoc = await _usersRef.doc(borrowModel.userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            borrowModel = borrowModel.copyWith(
              userName: userData['name'] as String?,
            );
          }
        } catch (e) {
          print('Error fetching user details: $e');
        }

        borrows.add(borrowModel);
      }

      return borrows;
    });
  }

// Helper method untuk konversi nilai ke double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      print('Error converting value to double: $e');
      return 0.0;
    }
  }


Future<void> rejectReturn(String borrowId, String reason) async {
  final adminId = _auth.currentUser?.uid;
  if (adminId == null) {
    throw Exception('Admin tidak terautentikasi');
  }

  try {
    // Get borrow document
    final borrowDoc = await _borrowsRef.doc(borrowId).get();
    if (!borrowDoc.exists) {
      throw Exception('Data peminjaman tidak ditemukan');
    }

    final borrowData = borrowDoc.data() as Map<String, dynamic>;
    final userId = borrowData['userId'] as String;
    final bookId = borrowData['bookId'] as String;
    final status = borrowData['status'] as String;

    // Verify status is pendingReturn
    if (status.toLowerCase() != 'pendingreturn') {
      throw Exception('Status peminjaman bukan pengembalian tertunda');
    }

    // Update borrow document: kembali ke status active atau overdue
    final now = DateTime.now();
    final dueDate = (borrowData['dueDate'] as Timestamp).toDate();
    final isLate = now.isAfter(dueDate);
    final newStatus = isLate ? 'overdue' : 'active';

    await _borrowsRef.doc(borrowId).update({
      'status': newStatus,
      'returnRejectDate': Timestamp.fromDate(now),
      'returnRejectedBy': adminId,
      'returnRejectReason': reason,
      'returnRequestDate': null, // Reset permintaan pengembalian
    });

    // Kirim notifikasi ke user jika ada implementasi notifikasi
    if (_ref?.read(notificationServiceProvider) != null) {
      try {
        // Ambil data buku untuk notifikasi
        final bookDoc = await _booksRef.doc(bookId).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data() as Map<String, dynamic>;
          final bookTitle = bookData['title'] as String;

          // Kirim notifikasi ke user
          final notificationService = _ref!.read(notificationServiceProvider);
          await notificationService.createNotificationForUser(
            userId: userId,
            title: 'Permintaan Pengembalian Ditolak',
            body: 'Permintaan pengembalian untuk buku "$bookTitle" ditolak dengan alasan: $reason',
            type: NotificationType.returnRejected,
            data: {
              'borrowId': borrowId,
              'bookId': bookId,
              'reason': reason,
            },
          );
        }
      } catch (e) {
        print('Error sending notification: $e');
        // Continue even if notification fails
      }
    }
  } catch (e) {
    print("Error rejecting return: $e");
    throw Exception('Gagal menolak pengembalian: ${e.toString()}');
  }
}
  Future<void> confirmReturn(String borrowId) async {
    final adminId = currentUserId;
    if (adminId == null) {
      throw Exception('Admin tidak ditemukan');
    }

    try {
      // Get all necessary documents first
      final borrowDocSnapshot = await _borrowsRef.doc(borrowId).get();
      if (!borrowDocSnapshot.exists) {
        throw Exception('Data peminjaman tidak ditemukan');
      }

      final borrowData = borrowDocSnapshot.data() as Map<String, dynamic>;
      final bookId = borrowData['bookId'] as String;
      final userId = borrowData['userId'] as String;
      final dueDate = (borrowData['dueDate'] as Timestamp).toDate();

      // Get user document
      final userDocSnapshot = await _usersRef.doc(userId).get();
      if (!userDocSnapshot.exists) {
        throw Exception('User tidak ditemukan');
      }

      // Get book document
      final bookDocSnapshot = await _booksRef.doc(bookId).get();
      if (!bookDocSnapshot.exists) {
        throw Exception('Buku tidak ditemukan');
      }

      // Calculate fine if returned late
      double fine = 0.0;
      final now = DateTime.now();
      final bool isLate = now.isAfter(dueDate);

      if (isLate) {
        // Normalisasi untuk perhitungan hari yang lebih akurat
        final DateTime normalizedDueDate =
            DateTime(dueDate.year, dueDate.month, dueDate.day);
        final DateTime normalizedNow = DateTime(now.year, now.month, now.day);

        // Calculate days late
        final daysLate = normalizedNow.difference(normalizedDueDate).inDays;
        final int effectiveDaysLate = daysLate > 0 ? daysLate : 1;

        // Fine per day (e.g., Rp 2.000 per day)
        fine = effectiveDaysLate * 2000.0;
      }

      // Now start transaction with all data already fetched
      await _firestore.runTransaction((transaction) async {
        // Update borrow document
        transaction.update(_borrowsRef.doc(borrowId), {
          'returnDate': now,
          // PERBAIKAN: Selalu tandai sebagai returned jika sudah dikonfirmasi admin
          'status': 'returned', // Selalu returned setelah dikonfirmasi
          'fine': fine,
          'isPaid':
              fine <= 0 || borrowData['isPaid'] == true, // Respek flag isPaid
          'confirmedReturnBy': adminId,
          'confirmReturnDate': now,
          'isReturned': true,
          'isReturnLocked': true,
          // TAMBAHAN: Pastikan tidak dianggap overdue lagi
          'preventOverdueCheck': true,
        });

        // Update borrowed books list
        final userData = userDocSnapshot.data() as Map<String, dynamic>;
        final borrowedBooks =
            List<String>.from(userData['borrowedBooks'] ?? []);
        borrowedBooks.remove(bookId);
        transaction
            .update(_usersRef.doc(userId), {'borrowedBooks': borrowedBooks});

        // Update user fine amount if there's a fine
        if (fine > 0) {
          // PERBAIKAN: Pastikan tipe data konsisten dengan menggunakan toDouble()
          final userFineAmount = userData['fineAmount'];
          double currentFine = 0.0;

          // Handle berbagai tipe data yang mungkin muncul
          if (userFineAmount is int) {
            currentFine = userFineAmount.toDouble();
          } else if (userFineAmount is double) {
            currentFine = userFineAmount;
          } else if (userFineAmount != null) {
            // Jika bukan null dan bukan int/double, coba konversi ke double
            try {
              currentFine = double.parse(userFineAmount.toString());
            } catch (e) {
              print('Error converting fineAmount to double: $e');
              currentFine = 0.0;
            }
          }

          transaction.update(
              _usersRef.doc(userId), {'fineAmount': currentFine + fine});
        }

        // Update book available count
        final bookData = bookDocSnapshot.data() as Map<String, dynamic>;
        final availableStock = (bookData['availableStock'] ?? 0) as int;
        transaction.update(
            _booksRef.doc(bookId), {'availableStock': availableStock + 1});
      });

      // Send notification to user after transaction succeeds
      try {
        final notificationService = _ref.read(notificationServiceProvider);
        final bookData = bookDocSnapshot.data() as Map<String, dynamic>;
        final bookTitle = bookData['title'] as String;

        await notificationService.createNotificationForUser(
          userId: userId,
          title: 'Buku Berhasil Dikembalikan',
          body: 'Buku "$bookTitle" telah berhasil dikembalikan.',
          type: isLate
              ? NotificationType.bookReturnedLate
              : NotificationType.bookReturned,
          data: {
            'borrowId': borrowId,
            'bookId': bookId,
            'fine': fine.toString(),
          },
        );
      } catch (notifError) {
        print('Error sending return notification: $notifError');
      }
    } catch (e) {
      print("Error confirming return: $e");
      throw Exception('Gagal mengonfirmasi pengembalian buku: ${e.toString()}');
    }
  }

  // Confirm borrow by librarian/admin
  Future<void> confirmBorrow(String borrowId) async {
    final adminId = currentUserId;
    if (adminId == null) {
      throw Exception('Admin tidak ditemukan');
    }
    String bookTitle = "";
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Get borrow document
        final borrowDoc = await transaction.get(_borrowsRef.doc(borrowId));
        if (!borrowDoc.exists) {
          throw Exception('Data peminjaman tidak ditemukan');
        }

        final borrowData = borrowDoc.data() as Map<String, dynamic>;
        final userId = borrowData['userId'] as String;
        final bookId = borrowData['bookId'] as String;
        final status = borrowData['status'] as String;

        // 2. Verify status is pending
        if (status != 'pending') {
          throw Exception('Peminjaman sudah dikonfirmasi atau ditolak');
        }

        // 3. Get book document
        final bookDoc = await transaction.get(_booksRef.doc(bookId));
        if (!bookDoc.exists) {
          throw Exception('Buku tidak ditemukan');
        }

        final bookData = bookDoc.data() as Map<String, dynamic>;
        final availableStock = bookData['availableStock'] as int;

        // 4. Check stock
        if (availableStock <= 0) {
          throw Exception('Stok buku tidak tersedia');
        }

        // 5. Get user document
        final userDoc = await transaction.get(_usersRef.doc(userId));
        if (!userDoc.exists) {
          throw Exception('User tidak ditemukan');
        }

        // 6. Get user's pending and borrowed books
        final userData = userDoc.data() as Map<String, dynamic>;
        final pendingBooks = List<String>.from(userData['pendingBooks'] ?? []);
        final borrowedBooks =
            List<String>.from(userData['borrowedBooks'] ?? []);

        // 7. Move book from pendingBooks to borrowedBooks
        if (!pendingBooks.contains(bookId)) {
          throw Exception('Buku tidak dalam daftar permintaan user');
        }
        pendingBooks.remove(bookId);
        borrowedBooks.add(bookId);

        // 8. Update borrow document
        transaction.update(_borrowsRef.doc(borrowId), {
          'status': 'active',
          'confirmDate': DateTime.now(),
          'confirmedBy': adminId,
          'borrowDate': DateTime.now(), // Set borrow date to now
          'dueDate': DateTime.now().add(const Duration(days: 7)), // 7 days due
        });

        // 9. Update book stock
        transaction.update(
            _booksRef.doc(bookId), {'availableStock': availableStock - 1});

        // 10. Update user's book lists
        transaction.update(_usersRef.doc(userId), {
          'pendingBooks': pendingBooks,
          'borrowedBooks': borrowedBooks,
        });
        // TAMBAHKAN: Notifikasi setelah konfirmasi peminjaman
        try {
          // Ambil data buku untuk notifikasi
          final bookDoc = await _booksRef.doc(bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            bookTitle = bookData['title'] as String;

            // Ambil jatuh tempo
            final borrowDoc = await _borrowsRef.doc(borrowId).get();
            final borrowData = borrowDoc.data() as Map<String, dynamic>;
            final dueDate = (borrowData['dueDate'] as Timestamp).toDate();

            // Kirim notifikasi ke peminjam
            final notificationService = _ref.read(notificationServiceProvider);
            await notificationService.createNotificationForUser(
              userId: userId,
              title: 'Peminjaman Disetujui',
              body:
                  'Peminjaman buku "$bookTitle" telah disetujui. Silakan ambil buku di perpustakaan. Jatuh tempo: ${_formatDate(dueDate)}',
              type: NotificationType.borrowConfirmed,
              data: {
                'borrowId': borrowId,
                'bookId': bookId,
                'dueDate': dueDate.millisecondsSinceEpoch,
              },
            );

            // Jadwalkan pengingat pengembalian satu hari sebelum jatuh tempo
            final reminderDate = dueDate.subtract(const Duration(days: 1));
            if (reminderDate.isAfter(DateTime.now())) {
              await notificationService.scheduleReturnReminder(
                  borrowId: borrowId, bookTitle: bookTitle, dueDate: dueDate);
            }
          }
        } catch (e) {
          print('Error sending confirmation notification: $e');
          // Tetap lanjutkan meskipun notifikasi gagal
        }
      });
    } catch (e) {
      print("Error confirming borrow: $e");
      throw Exception('Gagal mengonfirmasi peminjaman: ${e.toString()}');
    }
  }

  // Helper untuk format tanggal
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

// Tambahkan method returnBook
//   Future<void> returnBook(String borrowId) async {
//     final userId = currentUserId;
//     if (userId == null) {
//       throw Exception('User tidak ditemukan');
//     }

//     try {
//       // Get borrow document first
//       final borrowDoc = await _borrowsRef.doc(borrowId).get();
//       if (!borrowDoc.exists) {
//         throw Exception('Data peminjaman tidak ditemukan');
//       }

//       final borrowData = borrowDoc.data() as Map<String, dynamic>;
//       final bookId = borrowData['bookId'] as String;
//       final dueDate = (borrowData['dueDate'] as Timestamp).toDate();

//       // Calculate fine if returned late
//       double fine = 0.0;
//       final now = DateTime.now();

// // Normalisasi untuk perhitungan hari yang lebih akurat
//       final DateTime normalizedDueDate =
//           DateTime(dueDate.year, dueDate.month, dueDate.day);
//       final DateTime normalizedNow = DateTime(now.year, now.month, now.day);
//       final bool isLate = normalizedNow.isAfter(normalizedDueDate);

//       if (isLate) {
//         // Calculate days late (minimal 1 hari jika terlambat)
//         final daysLate = normalizedNow.difference(normalizedDueDate).inDays;
//         final int effectiveDaysLate = daysLate > 0 ? daysLate : 1;

//         // Fine per day (e.g., Rp 2.000 per day)
//         fine = effectiveDaysLate * 2000;
//       }

//       // Use transaction for atomic update
//       await _firestore.runTransaction((transaction) async {
//         // 1. Update borrow document
//         transaction.update(_borrowsRef.doc(borrowId), {
//           'returnDate': now,
//           'status': isLate ? 'overdue' : 'returned',
//           'fine': fine,
//           'isPaid': fine <= 0, // Mark as paid if no fine
//         });

//         // 2. Get user document
//         final userDoc = await transaction.get(_usersRef.doc(userId));
//         if (!userDoc.exists) {
//           throw Exception('User tidak ditemukan');
//         }

//         // 3. Update borrowed books list
//         final userData = userDoc.data() as Map<String, dynamic>;
//         final borrowedBooks =
//             List<String>.from(userData['borrowedBooks'] ?? []);
//         borrowedBooks.remove(bookId);
//         transaction
//             .update(_usersRef.doc(userId), {'borrowedBooks': borrowedBooks});

//         // 4. Update user fine amount if there's a fine
//         if (fine > 0) {
//           final currentFine = (userData['fineAmount'] ?? 0.0) as double;
//           transaction.update(
//               _usersRef.doc(userId), {'fineAmount': currentFine + fine});
//         }

//         // 5. Update book available count
//         final bookDoc = await transaction.get(_booksRef.doc(bookId));
//         if (bookDoc.exists) {
//           final bookData = bookDoc.data() as Map<String, dynamic>;
//           final availableStock = (bookData['availableStock'] ?? 0) as int;
//           transaction.update(
//               _booksRef.doc(bookId), {'availableStock': availableStock + 1});
//         }
//       });
//     } catch (e) {
//       print("Error returning book: $e");
//       throw Exception('Gagal mengembalikan buku: ${e.toString()}');
//     }
//   }

// Di BorrowRepository
  Future<void> returnBook(String borrowId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    try {
      // Read operations first
      final borrowDoc = await _borrowsRef.doc(borrowId).get();
      if (!borrowDoc.exists) {
        throw Exception('Data peminjaman tidak ditemukan');
      }

      final borrowData = borrowDoc.data() as Map<String, dynamic>;
      final bookId = borrowData['bookId'] as String;
      final status = borrowData['status'] as String;

      // Check if the status is active
      if (status != 'active' && status != 'overdue') {
        throw Exception('Buku tidak dalam status yang dapat dikembalikan');
      }

      // Update status to pending_return instead of directly returned
      await _borrowsRef.doc(borrowId).update({
        'returnRequestDate': DateTime.now(),
        'status': 'pendingReturn',
        'returnedBy': userId,
      });
// TAMBAHKAN: Notifikasi untuk user
      try {
        final borrowDoc = await _borrowsRef.doc(borrowId).get();
        if (borrowDoc.exists) {
          final borrowData = borrowDoc.data() as Map<String, dynamic>;
          final bookId = borrowData['bookId'] as String;

          final bookDoc = await _booksRef.doc(bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final bookTitle = bookData['title'] as String;

            // Kirim notifikasi ke user
            final notificationService = _ref.read(notificationServiceProvider);
            await notificationService.createNotificationForUser(
              userId: userId,
              title: 'Permintaan Pengembalian',
              body:
                  'Permintaan pengembalian buku "$bookTitle" telah dikirim. Menunggu konfirmasi pustakawan.',
              type: NotificationType.bookReturnRequest,
              data: {
                'borrowId': borrowId,
                'bookId': bookId,
              },
            );
          }
        }
      } catch (e) {
        print('Error sending return notification: $e');
      }
      // Notify admin/librarian through notification system
      try {
        final bookDoc = await _booksRef.doc(bookId).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data() as Map<String, dynamic>;
          final bookTitle = bookData['title'] as String;

          // Send notification to admins (if you have a notification system for admins)
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.createNotificationForAdmins(
            title: 'Permintaan Pengembalian Buku',
            body: 'Pengguna ingin mengembalikan buku: "$bookTitle"',
            type: NotificationType.bookReturnRequest,
            data: {
              'borrowId': borrowId,
              'bookId': bookId,
              'userId': userId,
            },
          );
        }
      } catch (notifError) {
        print('Error sending return request notification: $notifError');
        // Continue even if notification fails
      }
    } catch (e) {
      print("Error returning book: $e");
      throw Exception('Gagal meminta pengembalian buku: ${e.toString()}');
    }
  }

  // Reject borrow request by librarian/admin
  Future<void> rejectBorrow(String borrowId, String reason) async {
    final adminId = currentUserId;
    if (adminId == null) {
      throw Exception('Admin tidak ditemukan');
    }

    return _firestore.runTransaction((transaction) async {
      // 1. Get borrow document
      final borrowDoc = await transaction.get(_borrowsRef.doc(borrowId));
      if (!borrowDoc.exists) {
        throw Exception('Data peminjaman tidak ditemukan');
      }

      final borrowData = borrowDoc.data() as Map<String, dynamic>;
      final userId = borrowData['userId'] as String;
      final bookId = borrowData['bookId'] as String;
      final status = borrowData['status'] as String;

      // 2. Verify status is pending
      if (status != 'pending') {
        throw Exception('Peminjaman sudah dikonfirmasi atau ditolak');
      }

      // 3. Get user document
      final userDoc = await transaction.get(_usersRef.doc(userId));
      if (!userDoc.exists) {
        throw Exception('User tidak ditemukan');
      }

      // 4. Get user's pending books
      final userData = userDoc.data() as Map<String, dynamic>;
      final pendingBooks = List<String>.from(userData['pendingBooks'] ?? []);

      // 5. Remove book from pendingBooks
      pendingBooks.remove(bookId);

      // 6. Update borrow document
      transaction.update(_borrowsRef.doc(borrowId), {
        'status': 'rejected',
        'rejectDate': DateTime.now(),
        'rejectedBy': adminId,
        'rejectReason': reason,
      });

      // 7. Update user's pending books
      transaction.update(_usersRef.doc(userId), {'pendingBooks': pendingBooks});

      try {
        // Ambil info yang diperlukan
        final borrowDoc = await _borrowsRef.doc(borrowId).get();
        final borrowData = borrowDoc.data() as Map<String, dynamic>;
        final userId = borrowData['userId'] as String;
        final bookId = borrowData['bookId'] as String;

        // Ambil info buku
        final bookDoc = await _booksRef.doc(bookId).get();
        if (bookDoc.exists) {
          final bookData = bookDoc.data() as Map<String, dynamic>;
          final bookTitle = bookData['title'] as String;

          // Kirim notifikasi ke user
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.createNotificationForUser(
            userId: userId,
            title: 'Peminjaman Ditolak',
            body: 'Peminjaman buku "$bookTitle" ditolak dengan alasan: $reason',
            type: NotificationType.borrowRejected,
            data: {
              'borrowId': borrowId,
              'bookId': bookId,
              'reason': reason,
            },
          );
        }
      } catch (e) {
        print('Error sending reject notification: $e');
      }
    });
  }

  // Get all pending borrow requests (for admin/librarian)
  Stream<List<BorrowModel>> getPendingBorrows() {
    return _borrowsRef
        .where('status', isEqualTo: 'pending')
        .orderBy('requestDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final borrows = <BorrowModel>[];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final borrowModel = BorrowModel.fromJson({
          'id': doc.id,
          ...data,
        });

        try {
          // Get book information
          final bookDoc = await _booksRef.doc(borrowModel.bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;

            // Get user information
            final userDoc = await _usersRef.doc(borrowModel.userId).get();
            final userData =
                userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
            final userName =
                userData != null ? userData['name'] as String? : null;

            final bookWithInfo = borrowModel.copyWith(
              bookTitle: bookData['title'] as String,
              bookCover: bookData['coverUrl'] as String,
              userName: userName ?? 'Unknown User',
            );
            borrows.add(bookWithInfo);
          } else {
            borrows.add(borrowModel);
          }
        } catch (e) {
          borrows.add(borrowModel);
        }
      }

      return borrows;
    });
  }

  Future<void> payFine(String borrowId, String paymentMethod) async {
    try {
      // Get the borrow document
      final borrowDoc = await _borrowsRef.doc(borrowId).get();
      if (!borrowDoc.exists) {
        throw Exception('Peminjaman tidak ditemukan');
      }

      // Cast data ke Map<String, dynamic> terlebih dahulu
      final borrowData = borrowDoc.data() as Map<String, dynamic>;
      final userId = borrowData['userId'] as String?;
      final bookId = borrowData['bookId'] as String;
      final fine = _toDouble(borrowData['fine']);
      // Update the document
      await _borrowsRef.doc(borrowId).update({
        'isPaid': true,
        'paymentMethod': paymentMethod,
        'paymentDate': DateTime.now(),
      });
      // Update user's fine amount
      if (userId != null) {
        final userDoc = await _usersRef.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentFine = _toDouble(userData['fineAmount']);
          final borrowFine = _toDouble(borrowData['fine']);

          // Reduce user's total fine
          if (currentFine > 0 && borrowFine > 0) {
            double newFine = currentFine - borrowFine;
            if (newFine < 0) newFine = 0;
            await _usersRef.doc(userId).update({'fineAmount': newFine});
          }
        }
      }
      // TAMBAHKAN: Notifikasi pembayaran denda
      try {
        if (userId != null) {
          // Ambil info buku
          final bookDoc = await _booksRef.doc(bookId).get();
          if (bookDoc.exists) {
            final bookData = bookDoc.data() as Map<String, dynamic>;
            final bookTitle = bookData['title'] as String;

            // Kirim notifikasi ke user
            final notificationService = _ref.read(notificationServiceProvider);
            await notificationService.createNotificationForUser(
              userId: userId,
              title: 'Pembayaran Denda Berhasil',
              body:
                  'Pembayaran denda sebesar Rp ${fine.toStringAsFixed(0)} untuk buku "$bookTitle" telah berhasil diproses dengan metode $paymentMethod.',
              type: NotificationType.payment,
              data: {
                'borrowId': borrowId,
                'bookId': bookId,
                'fine': fine.toString(),
                'paymentMethod': paymentMethod,
              },
            );

            // Kirim notifikasi ke admin bahwa ada pembayaran denda
            await notificationService.createNotificationForAdmins(
              title: 'Pembayaran Denda',
              body:
                  'User telah membayar denda Rp ${fine.toStringAsFixed(0)} untuk buku "$bookTitle" dan siap dikembalikan.',
              type: NotificationType.payment,
              data: {
                'borrowId': borrowId,
                'bookId': bookId,
                'userId': userId,
              },
            );
          }
        }
      } catch (e) {
        print('Error sending payment notification: $e');
      }
    } catch (e) {
      print("Error paying fine: $e");
      throw Exception('Gagal memproses pembayaran: ${e.toString()}');
    }
  }

  // Get count of active loans for all users
  /// Menghitung jumlah peminjaman aktif untuk semua pengguna
  Future<int> getActiveLoansCount() async {
    final snapshot =
        await _borrowsRef.where('status', isEqualTo: 'active').get();

    return snapshot.docs.length;
  }

  // Get count of overdue borrows
  Future<int> getOverdueBorrowsCount() async {
    final now = DateTime.now();
    final snapshot = await _borrowsRef
        .where('dueDate', isLessThan: Timestamp.fromDate(now))
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs.length;
  }

  // Debug method untuk memeriksa buku terlambat
  Future<List<Map<String, dynamic>>> debugCheckOverdueBooks() async {
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    try {
      // 1. Cek peminjaman aktif yang sudah lewat tanggal jatuh tempo
      final overdueQuery = await _borrowsRef
          .where('status', isEqualTo: 'active')
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .get();

      print('=== OVERDUE CHECK RESULTS ===');
      print('Found ${overdueQuery.docs.length} overdue books');

      for (final doc in overdueQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final daysLate = now.difference(dueDate).inDays;
        final calculatedFine = daysLate > 0 ? daysLate * 2000.0 : 2000.0;

        final bookDoc = await _booksRef.doc(data['bookId'] as String).get();
        final bookTitle = bookDoc.exists
            ? (bookDoc.data() as Map<String, dynamic>)['title']
            : 'Unknown';

        final result = {
          'borrowId': doc.id,
          'bookId': data['bookId'],
          'bookTitle': bookTitle,
          'userId': data['userId'],
          'dueDate': dueDate,
          'daysLate': daysLate,
          'calculatedFine': calculatedFine,
          'currentStatus': data['status'],
          'currentFine': data['fine'] ?? 0.0,
        };

        results.add(result);
        print(
            'Borrow: ${doc.id}, Book: $bookTitle, Days Late: $daysLate, Fine: $calculatedFine');
      }

      print('=== END OF OVERDUE CHECK ===');
      return results;
    } catch (e) {
      print('Error in debug check: $e');
      return [];
    }
  }

  // Di file borrow_repository.dart
  Future<void> updateBorrowStatusToOverdue(String borrowId, double fine) async {
    try {
      await _borrowsRef.doc(borrowId).update({
        'status': 'overdue',
        'fine': fine,
        'isPaid': false,
      });
      print('Successfully updated borrow $borrowId to overdue with fine $fine');
    } catch (e) {
      print('Error updating borrow status: $e');
      throw Exception('Failed to update status: $e');
    }
  }

  // Tambahkan metode ini di BorrowRepository
  Future<int> fixInconsistentReturnedStatus() async {
    try {
      // Cari peminjaman dengan returnDate dan confirmReturnDate yang sudah ada tapi status bukan returned
      final snapshot = await _borrowsRef
          .where('returnDate', isNull: false)
          .where('confirmReturnDate', isNull: false)
          .get();

      int fixedCount = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;

        if (status != 'returned') {
          print(
              'Fixing inconsistent status for ${doc.id}: ${status} -> returned');
          batch.update(doc.reference, {
            'status': 'returned',
            'isReturned': true,
            'isReturnLocked': true,
            'preventOverdueCheck': true,
          });
          fixedCount++;
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        print('Fixed $fixedCount records');
      }

      return fixedCount;
    } catch (e) {
      print('Error fixing returned status: $e');
      return 0;
    }
  }
}

//  Digunakan untuk provider yang mengakses repository ini
final borrowRepositoryProvider = Provider<BorrowRepository>((ref) {
  return BorrowRepository(ref);
});