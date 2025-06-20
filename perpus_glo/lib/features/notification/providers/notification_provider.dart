import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/notification_service.dart';
import '../model/notification_model.dart';

// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Provider for user notifications stream
final userNotificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.getUserNotifications();
});

// Provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Add this provider
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUserNotifications().map(
        (notifications) =>
            notifications.where((notification) => !notification.isRead).length,
      );
});

// Provider untuk pengaturan notifikasi
final notificationSettingsProvider = StateProvider<Map<String, bool>>((ref) {
  return {
    'notifyBorrowRequests': true,
    'notifyReturnRequests': true,
    'notifyOverdueBooks': true,
    'notifyFinePayments': true,
  };
});

// Provider untuk notifikasi terbaru (untuk widget & dashboard)
final recentNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final allNotifications = ref.watch(userNotificationsProvider);

  return allNotifications.when(
    data: (notifications) {
      // Return 5 notifikasi terbaru
      final sorted = [...notifications]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted.take(5).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Controller for notification actions
class NotificationStateController extends StateNotifier<AsyncValue<void>> {
  final NotificationService _service;

  NotificationStateController(this._service)
      : super(const AsyncValue.data(null));

  // Kirim notifikasi ke user bahwa permintaan peminjaman sedang menunggu konfirmasi
  Future<void> sendBorrowRequestNotification({
    required String bookId,
    required String bookTitle,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createNotification(
        title: 'Permintaan Peminjaman',
        body:
            'Permintaan peminjaman untuk buku "$bookTitle" telah dikirim. Menunggu konfirmasi pustakawan.',
        type: NotificationType.borrowRequest,
        data: {
          'bookId': bookId,
        },
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

// Kirim notifikasi ke user bahwa permintaan peminjaman disetujui
  Future<void> sendBorrowConfirmationNotification({
    required String userId,
    required String borrowId,
    required String bookId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Kirim notifikasi firebase untuk disimpan di database
      await _service.createNotificationForUser(
        userId: userId,
        title: 'Peminjaman Disetujui',
        body:
            'Permintaan peminjaman untuk buku "$bookTitle" telah disetujui. Silakan ambil buku di perpustakaan.',
        type: NotificationType.borrowConfirmed,
        data: {
          'borrowId': borrowId,
          'bookId': bookId,
          'dueDate': dueDate.millisecondsSinceEpoch,
        },
      );

      // Jadwalkan pengingat pengembalian 1 hari sebelum jatuh tempo
      final reminderDate = dueDate.subtract(const Duration(days: 1));
      if (reminderDate.isAfter(DateTime.now())) {
        await scheduleReturnReminder(
          borrowId: borrowId,
          bookTitle: bookTitle,
          dueDate: dueDate,
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

// Kirim notifikasi ke user bahwa permintaan peminjaman ditolak
  Future<void> sendBorrowRejectionNotification({
    required String userId,
    required String borrowId,
    required String bookId,
    required String bookTitle,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createNotificationForUser(
        userId: userId,
        title: 'Peminjaman Ditolak',
        body:
            'Permintaan peminjaman untuk buku "$bookTitle" ditolak.\nAlasan: $reason',
        type: NotificationType.borrowRejected,
        data: {
          'borrowId': borrowId,
          'bookId': bookId,
          'reason': reason,
        },
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

// Kirim notifikasi ke admin/pustakawan bahwa ada permintaan peminjaman baru
  Future<void> sendNewBorrowRequestToAdminNotification({
    required String borrowId,
    required String userId,
    required String userName,
    required String bookId,
    required String bookTitle,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Kirim notifikasi ke semua admin/pustakawan
      await _service.createNotificationForAdmins(
        title: 'Permintaan Peminjaman Baru',
        body:
            'User "$userName" meminta peminjaman buku "$bookTitle". Harap konfirmasi segera.',
        type: NotificationType.borrowRequestAdmin,
        data: {
          'borrowId': borrowId,
          'userId': userId,
          'bookId': bookId,
        },
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _service.markAsRead(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      await _service.markAllAsRead();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteNotification(notificationId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> scheduleReturnReminder({
    required String borrowId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.scheduleReturnReminder(
        borrowId: borrowId,
        bookTitle: bookTitle,
        dueDate: dueDate,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendFineNotification({
    required String borrowId,
    required String bookTitle,
    required double amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createNotification(
        title: 'Denda Keterlambatan',
        body:
            'Anda dikenakan denda sebesar Rp ${amount.toStringAsFixed(0)} untuk buku "$bookTitle"',
        type: NotificationType.fine,
        data: {
          'borrowId': borrowId,
          'amount': amount,
        },
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationStateController, AsyncValue<void>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationStateController(service);
});