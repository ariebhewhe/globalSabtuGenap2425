import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripayService {
  // Base URL untuk sandbox Tripay
  static const String baseUrl = 'https://tripay.co.id/api-sandbox';
  
  // Kredensial API dari dashboard Tripay
  static const String merchantCode = 'T39945';
  static const String apiKey = 'DEV-NyXHofZgwb15NQ6eMwRByOR08YASe16RnyATLNCE';
  static const String privateKey = 'Eaykr-yV5PA-2ZxD2-oHKq6-3Z6IV';

  // Daftar metode pembayaran
  static Future<List<Map<String, dynamic>>> getPaymentChannels() async {
    try {
      final Uri url = Uri.parse('$baseUrl/merchant/payment-channel');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('Failed to get payment channels: ${data['message']}');
        }
      } else {
        throw Exception('Failed to get payment channels: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment channels: $e');
    }
  }

  // Membuat transaksi
  static Future<Map<String, dynamic>> createTransaction({
    required String customerName,
    required String customerEmail,
    required String orderItems,
    required int amount,
    required String merchantRef,
    required String paymentMethod,
    required BuildContext context,
  }) async {
    try {
      final Uri url = Uri.parse('$baseUrl/transaction/create');
      
      // Parse order items
      List<dynamic> items = json.decode(orderItems);
      
      // Format untuk Tripay API
      List<Map<String, dynamic>> formattedItems = items.map((item) => {
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
      }).toList();

      // Buat signature
      var signature = _generateSignature(merchantCode, merchantRef, amount);
      
      // Dapatkan data user dari Firebase
      Map<String, String> userData = await _getUserData();
      String customerRealName = userData['name'] ?? customerName; // Gunakan nama dari profil jika ada
      String customerPhone = userData['phone'] ?? '08123456789';

      // Buat request body
      final Map<String, dynamic> body = {
        'method': paymentMethod,
        'merchant_ref': merchantRef,
        'amount': amount,
        'customer_name': customerRealName, // Gunakan nama dari profil pengguna
        'customer_email': customerEmail,
        'customer_phone': customerPhone, // Menambahkan nomor telepon customer yang diminta Tripay
        'order_items': formattedItems,
        'callback_url': 'https://yourdomain.com/callback',
        'return_url': 'https://example.com/payment/success',
        'expired_time': DateTime.now()
        .add(Duration(hours: 24))
        .millisecondsSinceEpoch ~/ 1000,
        'signature': signature
      };

      // Debug log
      print('Payment request with method: $paymentMethod');
      print('Request body: ${json.encode(body)}');

      // Buat API request
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('Tripay Response Status: ${response.statusCode}');
      print('Tripay Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          return {
            'reference': responseData['data']['reference'],
            'merchant_ref': responseData['data']['merchant_ref'],
            'payment_method': responseData['data']['payment_method'],
            'payment_name': responseData['data']['payment_name'],
            'checkout_url': responseData['data']['checkout_url'],
            'status': responseData['data']['status'],
          };
        } else {
          throw Exception('Failed to create transaction: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to create transaction: ${response.body}');
      }
    } catch (e) {
      print('Tripay Service Error: $e'); // Untuk debugging
      throw Exception('Error creating transaction: $e');
    }
  }

  // Fungsi untuk mendapatkan data user (nama dan telepon)
  static Future<Map<String, String>> _getUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        final userRef = FirebaseDatabase.instance.ref().child('users').child(currentUser.uid);
        final snapshot = await userRef.once();
        
        if (snapshot.snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          // Return nama dan nomor telepon
          return {
            'name': userData['name']?.toString() ?? 'Customer',
            'phone': userData['phone']?.toString() ?? '08123456789',
          };
        }
      }
      
      // Jika tidak berhasil mendapatkan data, gunakan nilai default
      return {
        'name': 'Customer',
        'phone': '08123456789',
      };
    } catch (e) {
      print('Error getting user data: $e');
      // Return nilai default jika ada error
      return {
        'name': 'Customer',
        'phone': '08123456789',
      };
    }
  }

  // Generate signature untuk Tripay
  static String _generateSignature(String merchantCode, String merchantRef, int amount) {
    String signature = '$merchantCode$merchantRef$amount';
    var key = utf8.encode(privateKey);
    var digest = utf8.encode(signature);
    var hmacSha256 = Hmac(sha256, key);
    var hash = hmacSha256.convert(digest);
    return hash.toString();
  }

 // Buka halaman pembayaran (dimodifikasi untuk simulasi)
  static Future<bool> openPaymentPage(String url, {String? merchantRef, String? reference}) async {
    if (url.isEmpty) {
      throw Exception('URL pembayaran kosong');
    }

    print('Membuka URL pembayaran: $url'); // Untuk debugging
    
    // OPSI 1: Simulasi pembayaran otomatis (untuk test)
    // Uncomment kode di bawah dan comment kode untuk OPSI 2
    if (merchantRef != null && reference != null) {
      // Update status pembayaran di Firebase
      await FirebaseDatabase.instance
        .ref()
        .child('orders')
        .child(merchantRef)
        .update({
          'status': 'paid',
          'paymentDate': DateTime.now().toIso8601String(),
      });
      
      print('Status pembayaran diupdate menjadi PAID untuk $merchantRef');
      return true; // Return sukses tanpa membuka URL
    }
    
    // OPSI 2: Jalankan pembayaran normal
    // Comment kode di bawah jika ingin menggunakan OPSI 1
    /*
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return true;
    } else {
      throw Exception('Tidak dapat membuka URL pembayaran');
    }
    */
    
    return true; // Kembalikan true untuk menandakan sukses
  }

  
  // Cek status pembayaran
  static Future<Map<String, dynamic>> checkPaymentStatus(String reference) async {
    try {
      // Cara yang benar untuk menambahkan query parameter ke URL
      final Uri url = Uri.parse('$baseUrl/transaction/detail').replace(
        queryParameters: {'reference': reference}
      );
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('Failed to check payment status: ${data['message']}');
        }
      } else {
        throw Exception('Failed to check payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }
}