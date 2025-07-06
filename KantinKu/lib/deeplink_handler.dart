import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_database/firebase_database.dart';

class DeepLinkHandler {
  // Singleton pattern
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  // Instance of AppLinks
  final AppLinks _appLinks = AppLinks();

  // Stream controller untuk mengirim event deep link
  final StreamController<String> _deepLinkStreamController =
      StreamController<String>.broadcast();
  Stream<String> get deepLinkStream => _deepLinkStreamController.stream;

  // Untuk menyimpan context jika diperlukan
  static BuildContext? _context;

  // Method untuk inisialisasi dan mendengarkan deep links
  Future<void> initAppLinks(BuildContext context) async {
    _context = context;

    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error retrieving initial deep link: $e');
    }

    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (error) {
      debugPrint('Error handling incoming deep link: $error');
    });
  }

  // Clean up
  static void dispose() {
    _context = null;
  }

  // Handle deep link logic
  static void _handleDeepLink(Uri uri) {
    print('Handling deep link: $uri');

    if (uri.toString().contains('payment/success')) {
      String? orderId = _extractOrderId(uri);
      if (orderId != null) {
        _updateOrderStatus(orderId, 'paid');
        if (_context != null) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else if (uri.toString().contains('payment/failure')) {
      String? orderId = _extractOrderId(uri);
      if (orderId != null) {
        _updateOrderStatus(orderId, 'failed');
        if (_context != null) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran gagal atau dibatalkan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      print('Unhandled deep link type: $uri');
    }
  }

  // Extract order ID dari URI
  static String? _extractOrderId(Uri uri) {
    if (uri.queryParameters.containsKey('order_id')) {
      return uri.queryParameters['order_id'];
    }

    List<String> segments = uri.pathSegments;
    if (segments.length > 2 && segments[0] == 'payment') {
      return segments[2];
    }

    return null;
  }

  // Update status order di Firebase
  static Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('orders')
          .child(orderId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('Order status updated: $orderId -> $status');
    } catch (e) {
      print('Failed to update order status: $e');
    }
  }
}
