import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_service.dart';
import '../model/payment_model.dart';
import '../../borrow/data/borrow_repository.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseAuth _auth = FirebaseService.auth;
  final BorrowRepository _borrowRepository;

  PaymentRepository(this._borrowRepository);

  // Collection references
  CollectionReference get _paymentsRef => _firestore.collection('payments');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new payment
  Future<PaymentModel> createPayment(String borrowId, double amount) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User tidak ditemukan');
    }

    // Create payment document ID
    final paymentId = _paymentsRef.doc().id;

    // Create fake QR code URL (in real app would be generated from payment gateway)
    // For demo purposes, we'll use a static QR URL
    final paymentQrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=PAYMENT:$paymentId:$amount';

    final payment = PaymentModel(
      id: paymentId,
      userId: userId,
      borrowId: borrowId,
      amount: amount,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      paymentQrUrl: paymentQrUrl,
    );

    // Save to Firestore
    await _paymentsRef.doc(paymentId).set(payment.toJson());

    return payment;
  }

  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    final doc = await _paymentsRef.doc(paymentId).get();

    if (!doc.exists) return null;

    return PaymentModel.fromJson({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    });
  }

  // Get user's payment history
  Stream<List<PaymentModel>> getUserPayments() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _paymentsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<PaymentModel> payments = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final payment = PaymentModel.fromJson({
          'id': doc.id,
          ...data,
        });

        // Tambahkan info buku dari peminjaman
        try {
          final borrowDoc = await _firestore
              .collection('borrows')
              .doc(payment.borrowId)
              .get();
          if (borrowDoc.exists) {
            final borrowData = borrowDoc.data() as Map<String, dynamic>;
            final bookId = borrowData['bookId'] as String?;

            if (bookId != null) {
              final bookDoc =
                  await _firestore.collection('books').doc(bookId).get();
              if (bookDoc.exists) {
                final bookData = bookDoc.data() as Map<String, dynamic>;

                // Tambahkan info buku ke model payment
                final paymentWithBookInfo = payment.copyWith(
                  bookTitle: bookData['title'] as String?,
                  bookCover: bookData['coverUrl'] as String?,
                );

                payments.add(paymentWithBookInfo);
                continue; // Lanjut ke pembayaran berikutnya
              }
            }
          }
        } catch (e) {
          print('Error getting book info: $e');
        }

        // Jika gagal mendapatkan info buku, tambahkan payment tanpa info tambahan
        payments.add(payment);
      }

      return payments;
    });
  }

  // Update payment status
  Future<void> updatePaymentStatus(String paymentId, PaymentStatus status,
      {String? paymentMethod}) async {
    final data = <String, dynamic>{
      'status': status.toString().split('.').last,
    };

    if (status == PaymentStatus.completed) {
      data['completedAt'] = FieldValue.serverTimestamp();
    }

    if (paymentMethod != null) {
      data['paymentMethod'] = paymentMethod;
    }

    await _paymentsRef.doc(paymentId).update(data);
  }

  // Complete payment
  Future<void> completePayment(String paymentId, String paymentMethod) async {
    try {
      print('PaymentRepository: Starting payment completion');

      // Get payment details
      final payment = await getPaymentById(paymentId);
      print('PaymentRepository: Retrieved payment: ${payment?.id}');

      if (payment == null) {
        print('PaymentRepository: Payment not found');
        throw Exception('Data pembayaran tidak ditemukan');
      }

      print('PaymentRepository: Found borrow ID: ${payment.borrowId}');

      // Transaction to update payment status and handle fine
      print('PaymentRepository: Starting Firestore transaction');

      // PERBAIKAN: Pisahkan semua READ terlebih dahulu sebelum WRITE
      await _firestore.runTransaction((transaction) async {
        // 1. SEMUA READ OPERATIONS DI SINI TERLEBIH DAHULU
        print('PaymentRepository: Getting all documents first');

        // Get borrow document
        final borrowDocRef =
            _firestore.collection('borrows').doc(payment.borrowId);
        final borrowDoc = await transaction.get(borrowDocRef);

        if (!borrowDoc.exists) {
          print('PaymentRepository: Borrow document does not exist');
          throw Exception('Data peminjaman tidak ditemukan');
        }

        final borrowData = borrowDoc.data() as Map<String, dynamic>;
        final currentStatus = borrowData['status'] as String? ?? '';
        print('PaymentRepository: Current borrow status: $currentStatus');

        // Get user document
        final userDocRef = _usersRef.doc(payment.userId);
        final userDoc = await transaction.get(userDocRef);

        double currentFine = 0;
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          currentFine = (userData['fineAmount'] as num?)?.toDouble() ?? 0.0;
          print('PaymentRepository: Current user fine: $currentFine');
        } else {
          print('PaymentRepository: User document does not exist');
        }

        // 2. SEMUA WRITE OPERATIONS SETELAH SEMUA READ
        print('PaymentRepository: Now performing all writes');

        // Update payment document
        transaction.update(_paymentsRef.doc(paymentId), {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'paymentMethod': paymentMethod,
        });

        // Update borrow document if not already returned
        if (currentStatus != 'returned') {
          transaction.update(borrowDocRef, {
            'isPaid': true,
            'status': 'pendingReturn',
            'returnRequestDate': FieldValue.serverTimestamp(),
          });
        }

        // Update user's fine amount if user exists and has a fine
        if (userDoc.exists && currentFine > 0) {
          transaction.update(userDocRef, {
            'fineAmount': currentFine - payment.amount <= 0
                ? 0
                : currentFine - payment.amount,
          });
        }
      });

      print('PaymentRepository: Transaction completed successfully');
    } catch (e) {
      print('PaymentRepository: Error in completePayment: $e');
      throw Exception('Gagal menyelesaikan pembayaran: ${e.toString()}');
    }
  }

  // Cancel payment
  Future<void> cancelPayment(String paymentId) async {
    try {
      print(
          'PaymentRepository: Starting payment cancellation for ID $paymentId');
      await updatePaymentStatus(paymentId, PaymentStatus.cancelled);
      print('PaymentRepository: Payment cancelled successfully');
    } catch (e) {
      print('PaymentRepository: Error cancelling payment: $e');
      throw Exception('Gagal membatalkan pembayaran: ${e.toString()}');
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final borrowRepository = ref.watch(borrowRepositoryProvider);
  return PaymentRepository(borrowRepository);
});