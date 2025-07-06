import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  // Stream controller to listen for real-time order status changes
  static StreamSubscription<DatabaseEvent>? _orderStatusSubscription;
  
  // Initialize notification plugin and set up Firebase listeners
  static Future<void> initialize() async {
    // Using @mipmap/ic_launcher instead of @drawable/app_icon
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap here - could navigate to order details
        print('Notification tapped: ${response.payload}');
      },
    );
    
    // Set up Firebase order status listener to automatically notify on changes
    _setupOrderStatusListener();
  }

  // Set up Firebase listener for order status changes
  static void _setupOrderStatusListener() {
    // Cancel any existing subscription
    _orderStatusSubscription?.cancel();
    
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Reference to orders for the current user
    final ordersRef = FirebaseDatabase.instance.ref().child('orders');
    
    // Query for orders belonging to this user
    final query = ordersRef.orderByChild('userId').equalTo(user.uid);
    
    // Listen for changes
    _orderStatusSubscription = query.onChildChanged.listen((event) {
      final orderData = event.snapshot.value as Map<dynamic, dynamic>?;
      final orderId = event.snapshot.key;
      
      if (orderData != null && orderId != null) {
        final status = orderData['status'] as String?;
        if (status != null) {
          // Automatically send notification for status change
          _notifyOrderStatusChange(orderData, orderId, status);
        }
      }
    });
    
    print('Order status listener set up successfully');
  }
  
  // Private method to handle status change notifications
  static void _notifyOrderStatusChange(Map<dynamic, dynamic> orderData, String orderId, String status) {
    // Create appropriate notification based on status
    String title, body;
    
    switch (status) {
      case 'pending':
        title = 'Pesanan Menunggu: #${orderId.substring(0, min(8, orderId.length))}';
        body = 'Pesanan Anda menunggu konfirmasi. Silahkan menyelesaikan pembayaran.';
        break;
      case 'processing':
        title = 'Pesanan Diproses: #${orderId.substring(0, min(8, orderId.length))}';
        body = 'Pesanan Anda sedang diproses oleh restoran. Mohon tunggu sebentar.';
        break;
      case 'completed':
        title = 'Pesanan Selesai: #${orderId.substring(0, min(8, orderId.length))}';
        body = 'Pesanan Anda telah selesai dan siap disajikan/diambil. Terima kasih!';
        break;
      case 'cancelled':
        title = 'Pesanan Dibatalkan: #${orderId.substring(0, min(8, orderId.length))}';
        body = 'Pesanan Anda telah dibatalkan. Silakan hubungi staf untuk informasi lebih lanjut.';
        break;
      case 'paid':
        title = 'Pembayaran Diterima: #${orderId.substring(0, min(8, orderId.length))}';
        body = 'Pembayaran Anda telah diterima. Pesanan Anda sedang diproses.';
        break;
      default:
        title = 'Status Pesanan: #${orderId.substring(0, min(8, orderId.length))}';
        body = 'Status pesanan Anda telah diperbarui menjadi: $status';
    }
    
    // Send the notification with the order ID as a unique notification ID
    showOrderNotification(
      id: orderId.hashCode.abs(),
      title: title,
      body: body,
      status: status,
      payload: orderId, // Use the order ID as payload for navigation when tapped
    );
  }

  // Public method to show notifications
  static Future<void> showOrderNotification({
    required int id,
    required String title,
    required String body,
    String? status,
    String? payload,
  }) async {
    try {
      // Set up Android notification details with sound, vibration and styling
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'order_channel_id',
        'Order Notifications',
        channelDescription: 'Notifikasi untuk pesanan dan status pesanan',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        // Make sure file exists at android/app/src/main/res/raw/notif.mp3
        sound: const RawResourceAndroidNotificationSound('notif'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
        ),
        color: _getStatusColor(status ?? ''),
        // Use default app icon
        // icon: null, // Leave unspecified to use the default app icon
        // Show timestamp
        showWhen: true,
        channelShowBadge: true,
      );
      
      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );
      
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
            
      print('Notification shown successfully with ID: $id, status: $status');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Set up listener for a specific order
  static void setupOrderListener(String orderId) {
    final orderRef = FirebaseDatabase.instance.ref().child('orders').child(orderId);
    
    // Listen for changes to this specific order
    orderRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final orderData = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        final status = orderData['status'] as String?;
        
        if (status != null) {
          _notifyOrderStatusChange(orderData, orderId, status);
        }
      }
    });
    
    print('Specific order listener set up for ID: $orderId');
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
  
  // Clean up resources
  static void dispose() {
    _orderStatusSubscription?.cancel();
  }

  // Helper to get color based on status
  static Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'processing':
        return const Color(0xFF2196F3); // Blue
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      case 'paid':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

// Helper function to get minimum value
int min(int a, int b) {
  return a < b ? a : b;
}