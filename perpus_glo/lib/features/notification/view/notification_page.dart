import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../model/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final controller = ref.watch(notificationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: controller.isLoading
                ? null
                : () {
                    ref
                        .read(notificationControllerProvider.notifier)
                        .markAllAsRead();
                  },
            tooltip: 'Tandai semua sudah dibaca',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('Belum ada notifikasi'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, ref, notification);
            },
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, WidgetRef ref, NotificationModel notification) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref
            .read(notificationControllerProvider.notifier)
            .deleteNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: notification.isRead ? null : Colors.blue.shade50,
        child: InkWell(
          onTap: () {
            // Mark as read
            if (!notification.isRead) {
              ref
                  .read(notificationControllerProvider.notifier)
                  .markAsRead(notification.id);
            }

            // Navigate based on notification type and data
            _handleNotificationTap(context, notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with type icon and date
                Row(
                  children: [
                    _buildTypeIcon(notification.type),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Notification body
                Text(notification.body),

                // Unread indicator
                if (!notification.isRead)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = Colors.orange;
        break;
      case NotificationType.overdue:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case NotificationType.fine:
        icon = Icons.attach_money;
        color = Colors.red;
        break;
      case NotificationType.info:
        icon = Icons.info;
        color = Colors.blue;
        break;
      case NotificationType.borrowRequest:
        icon = Icons.book;
        color = Colors.amber;
        break;
      case NotificationType.general:
        icon = Icons.notifications;
        color = Colors.grey;
        break;
      case NotificationType.borrowConfirmed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case NotificationType.borrowRejected:
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case NotificationType.returnRejected:
        icon = Icons.block;
        color = Colors.redAccent;
        break;
      case NotificationType.borrowRequestAdmin:
        icon = Icons.pending_actions;
        color = Colors.purple;
        break;
      case NotificationType.returnReminder:
        icon = Icons.alarm;
        color = Colors.orange;
        break;
      case NotificationType.bookReturned:
        icon = Icons.assignment_turned_in;
        color = Colors.teal;
        break;
      case NotificationType.payment:
        icon = Icons.payment;
        color = Colors.green;
        break;
      case NotificationType.announcement:
        icon = Icons.campaign;
        color = Colors.indigo;
        break;
      case NotificationType.bookReturnedLate:
        icon = Icons.history;
        color = Colors.deepOrange;
        break;
      case NotificationType.bookReturnRequest:
        icon = Icons.request_page;
        color = Colors.blueAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    if (notification.data == null) return;

    switch (notification.type) {
      case NotificationType.reminder:
      case NotificationType.bookReturnedLate:
      case NotificationType.bookReturnRequest:
        final borrowId = notification.data?['borrowId'] as String?;
        if (borrowId != null) {
          context.push('/borrow/$borrowId');
        }
        break;
      case NotificationType.overdue:
      case NotificationType.returnReminder:
        final borrowId = notification.data?['borrowId'] as String?;
        if (borrowId != null) {
          context.push('/borrow/$borrowId');
        }
        break;

      case NotificationType.fine:
        final borrowId = notification.data?['borrowId'] as String?;
        final amount =
            (notification.data?['amount'] as num?)?.toDouble() ?? 0.0;
        if (borrowId != null) {
          context.push('/payment/$borrowId?amount=$amount');
        }
        break;

      case NotificationType.borrowRequest:
      case NotificationType.returnRejected:
      case NotificationType.borrowConfirmed:
      case NotificationType.borrowRejected:
        final bookId = notification.data?['bookId'] as String?;
        if (bookId != null) {
          context.push('/books/$bookId');
        }
        break;

      case NotificationType.borrowRequestAdmin:
        final borrowId = notification.data?['borrowId'] as String?;
        if (borrowId != null) {
          context.push('/admin/borrows/$borrowId');
        }
        break;

      case NotificationType.bookReturned:
        final borrowId = notification.data?['borrowId'] as String?;
        if (borrowId != null) {
          context.push('/borrow/$borrowId');
        }
        break;

      case NotificationType.payment:
        final paymentId = notification.data?['paymentId'] as String?;
        if (paymentId != null) {
          context.push('/payment/history/$paymentId');
        }
        break;

      case NotificationType.announcement:
        final announcementId = notification.data?['announcementId'] as String?;
        if (announcementId != null) {
          context.push('/announcements/$announcementId');
        } else {
          context.push('/announcements');
        }
        break;

      case NotificationType.info:
      case NotificationType.general:
        // Hanya tampilkan notifikasi, tanpa navigasi
        break;
    }
  }
}