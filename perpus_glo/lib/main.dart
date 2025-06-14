import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'features/notification/service/notification_service.dart';
import 'features/categories/providers/category_provider.dart'; // Tambahkan import ini
import 'features/notification/controller/notification_controller.dart';
import 'features/notification/providers/notification_provider.dart';
import 'features/borrow/providers/borrow_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseService.initialize();

  // Initialize Notification Service
  await NotificationService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  void _setupPeriodicChecks(WidgetRef ref) {
    // Check overdue books when app starts
    ref.read(checkOverdueBooksProvider);

    // Schedule periodic checks (setiap 6 jam)
    Timer.periodic(const Duration(hours: 6), (timer) {
      print('Running scheduled overdue check');
      ref.refresh(checkOverdueBooksProvider);

      // Juga jalankan pengingat pengembalian
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.scheduleReturnReminders();
    });
  }

  void _checkOverdueBooks(WidgetRef ref) {
    ref.read(checkOverdueBooksProvider);

    // Schedule return reminders
    final notificationService = ref.read(notificationServiceProvider);
    notificationService.scheduleReturnReminders();
  }

  void _setupNotificationHandlers(WidgetRef ref) {
    ref
        .read(notificationServiceProvider)
        .actionStream
        .listen((ReceivedAction receivedAction) {
      // Handle notification tap
      final payload = receivedAction.payload!;
      if (receivedAction.payload != null) {
        // Example: Navigate based on payload
        if (payload.containsKey('borrowId')) {
          router.push('/borrow/${payload['borrowId']}');
        } else if (payload.containsKey('bookId')) {
          router.push('/books/${payload['bookId']}');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationHandlers(ref);
      _checkOverdueBooks(ref);
      _setupPeriodicChecks(ref); // Tambahkan ini
    });

    return MaterialApp.router(
      title: 'Perpus GLO',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}