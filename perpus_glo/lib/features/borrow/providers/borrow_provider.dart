import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perpusglo/features/auth/providers/auth_provider.dart';
import '../data/borrow_repository.dart';
import '../model/borrow_model.dart';

// Provider untuk stream history peminjaman user
final userBorrowHistoryProvider = StreamProvider<List<BorrowModel>>((ref) {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.getUserBorrowHistory();
});

// Provider untuk detail peminjaman berdasarkan ID
final borrowByIdProvider =
    FutureProvider.family<BorrowModel?, String>((ref, borrowId) async {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.getBorrowById(borrowId);
});

// Provider untuk filter status peminjaman
final borrowFilterProvider = StateProvider<BorrowStatus?>((ref) => null);

// Provider untuk peminjaman terfilter
final filteredBorrowsProvider = Provider<List<BorrowModel>>((ref) {
  final borrowsAsync = ref.watch(userBorrowHistoryProvider);
  final filter = ref.watch(borrowFilterProvider);

  return borrowsAsync.when(
    data: (borrows) {
      if (filter == null) return borrows;
      return borrows.where((borrow) => borrow.status == filter).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider untuk mengecek apakah buku dalam status pending
final isBookPendingProvider =
    FutureProvider.family<bool, String>((ref, bookId) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return false;

  return currentUser.pendingBooks.contains(bookId);
});

// Provider untuk mengecek apakah buku dalam status borrowed
final isBookBorrowedProvider =
    FutureProvider.family<bool, String>((ref, bookId) async {
  final currentUser = await ref.watch(currentUserProvider.future);
  if (currentUser == null) return false;

  return currentUser.borrowedBooks.contains(bookId);
});

// Provider for active borrows all users
final activeBorrowsProvider = StreamProvider<List<BorrowModel>>((ref) {
  // Ambil currentUser dari provider yang tepat
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid;

  // Atau gunakan currentUserProvider jika sudah didefinisikan
  // final user = ref.watch(currentUserProvider).valueOrNull;
  // final userId = user?.id;

  if (userId == null) return Stream.value([]);

  final borrowRepository = ref.watch(borrowRepositoryProvider);
  return borrowRepository.getUserActiveBorrows(userId);
});

// Provider untuk jumlah peminjaman aktif
final activeLoansCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.getActiveLoansCount();
});

// Provider untuk menghitung jumlah peminjaman yang terlambat
final overdueBorrowsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.getOverdueBorrowsCount();
});

// Tambahkan provider untuk pending borrows
final pendingBorrowsProvider = StreamProvider<List<BorrowModel>>((ref) {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.getPendingBorrows();
});

// Count of pending borrow requests
final pendingBorrowsCountProvider = StreamProvider<int>((ref) {
  final pendingBorrowsStream = ref.watch(pendingBorrowsProvider.stream);
  return pendingBorrowsStream.map((event) => event.length);
});

// Controller untuk aksi peminjaman
class BorrowController extends StateNotifier<AsyncValue<void>> {
  final BorrowRepository _repository;
  final Ref ref;

  BorrowController(this._repository, this.ref)
      : super(const AsyncValue.data(null));

  Future<bool> borrowBook(String bookId) async {
    state = const AsyncValue.loading();
    try {
      print("Memulai proses peminjaman buku: $bookId");

      // Borrow the book - this should only create record with pending status
      final borrowId = await _repository.borrowBook(bookId);

      print("Peminjaman berhasil dengan ID: $borrowId");

      // Refresh related providers
      ref.invalidate(userBorrowHistoryProvider);
      ref.invalidate(currentUserProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      print("Error ketika meminjam buku: $e");
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Add confirm and reject methods
  Future<bool> confirmBorrow(String borrowId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.confirmBorrow(borrowId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> rejectBorrow(String borrowId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectBorrow(borrowId, reason);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Method untuk menolak pengembalian
  Future<bool> rejectReturn(String borrowId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectReturn(borrowId, reason);

      // Refresh data jika diperlukan
      ref.invalidate(pendingReturnBorrowsProvider);
      ref.invalidate(userBorrowHistoryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Add returnBook method
  Future<bool> returnBook(String borrowId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.returnBook(borrowId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Tambahkan method untuk pembayaran denda
  Future<bool> payFine(String borrowId, String paymentMethod) async {
    state = const AsyncValue.loading();
    try {
      // Implement payment logic
      await _repository.payFine(borrowId, paymentMethod);

      // Refresh data
      ref.invalidate(userBorrowHistoryProvider);
      ref.invalidate(currentUserProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  // Di BorrowController
  Future<bool> confirmReturn(String borrowId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.confirmReturn(borrowId);

      // Refresh data
      ref.invalidate(pendingReturnBorrowsProvider);
      ref.invalidate(userBorrowHistoryProvider);
      ref.invalidate(activeBorrowsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// Di borrow_provider.dart
final debugOverdueCheckProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.debugCheckOverdueBooks();
});

// Di borrow_provider.dart
final pendingReturnBorrowsProvider = StreamProvider<List<BorrowModel>>((ref) {
  final repository = ref.watch(borrowRepositoryProvider);
  return repository.getPendingReturnBorrows();
});

// Di borrow_provider.dart
final fixReturnedStatusProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(borrowRepositoryProvider);
  return await repository.fixInconsistentReturnedStatus();
});

// Overdue books check provider
final checkOverdueBooksProvider = FutureProvider<void>((ref) async {
  final repository = ref.watch(borrowRepositoryProvider);
  await repository.checkOverdueBooks();
});

// Di borrow_provider.dart
final allBorrowsProvider = StreamProvider<List<BorrowModel>>((ref) {
  final borrowRepository = ref.watch(borrowRepositoryProvider);
  return borrowRepository.getAllBorrows();
});

final borrowControllerProvider =
    StateNotifierProvider<BorrowController, AsyncValue<void>>((ref) {
  final repository = ref.watch(borrowRepositoryProvider);
  return BorrowController(repository, ref);
});