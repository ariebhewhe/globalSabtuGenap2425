import 'package:app_links/app_links.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../data/tripay_service.dart';

class PaymentHandler {
  static final PaymentHandler _instance = PaymentHandler._internal();
  factory PaymentHandler() => _instance;
  PaymentHandler._internal();

  final AppLinks _appLinks = AppLinks();
  
  // Inisialisasi handler untuk app links
  void init(BuildContext context) {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      handleDeepLink(uri, context);
    });
  }

  // Pantau link yang dibuka
  Future<void> handleDeepLink(Uri? uri, BuildContext context) async {
    if (uri == null) return;
    
    print('Received deep link: $uri');
    
    // Cek kalau ini adalah callback pembayaran
    if (uri.scheme == 'kantinku' && uri.host == 'payment') {
      final pathSegments = uri.pathSegments;
      
      // Cek status pembayaran
      if (pathSegments.isNotEmpty && pathSegments.first == 'success') {
        // Dapatkan order_id dari query parameters jika ada
        final orderId = uri.queryParameters['order_id'];
        
        if (orderId != null) {
          // Periksa status pembayaran di Tripay
          await _checkAndUpdatePaymentStatus(orderId, context);
        }
      }
    }
  }

  // Cek dan update status pembayaran
  Future<void> _checkAndUpdatePaymentStatus(String merchantRef, BuildContext context) async {
    try {
      // Dapatkan reference dari Firebase
      final orderSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('orders')
          .child(merchantRef)
          .get();
      
      if (orderSnapshot.exists) {
        final orderData = orderSnapshot.value as Map<dynamic, dynamic>;
        final String? tripayReference = orderData['tripayReference'];
        
        if (tripayReference != null) {
          // Cek status pembayaran dari Tripay
          final paymentStatus = await TripayService.checkPaymentStatus(tripayReference);
          
          // Update status di Firebase
          if (paymentStatus['status'] != null) {
            await FirebaseDatabase.instance
                .ref()
                .child('orders')
                .child(merchantRef)
                .update({
              'status': paymentStatus['status'],
              'paidAt': paymentStatus['paid_at'],
            });
            
            // Tampilkan pesan sesuai status
            if (paymentStatus['status'] == 'PAID') {
              _showSuccessDialog(context);
            } else {
              _showPendingDialog(context);
            }
          }
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  // Dialog sukses
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Berhasil'),
        content: const Text('Pesanan Anda telah berhasil dibayar dan sedang diproses.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigasi ke halaman riwayat pesanan atau beranda
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Dialog pending
  void _showPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran Tertunda'),
        content: const Text('Pembayaran Anda sedang diproses. Kami akan memberitahu Anda ketika pembayaran dikonfirmasi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}