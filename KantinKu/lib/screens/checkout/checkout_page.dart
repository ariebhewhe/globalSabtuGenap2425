import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/tripay_service.dart';  // Menggunakan TripayService
import '../../data/notification_service.dart'; // Import service notifikasi

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final int totalAmount;

  const CheckoutPage({
    Key? key, 
    required this.cartItems, 
    required this.totalAmount
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;
  String _selectedPaymentMethod = 'QRIS';
  List<Map<String, dynamic>> _paymentChannels = [];
  bool _loadingPaymentChannels = true;
  Map<String, dynamic>? _selectedPaymentDetails;

  @override
  void initState() {
    super.initState();
    _loadPaymentChannels();
  }

  // Memuat metode pembayaran yang tersedia
  Future<void> _loadPaymentChannels() async {
    try {
      final channels = await TripayService.getPaymentChannels();
      
      // Filter untuk payment channels yang aktif saja
      final activeChannels = channels.where((channel) => 
        channel['active'] == true).toList();
      
      setState(() {
        _paymentChannels = activeChannels;
        _loadingPaymentChannels = false;
        
        // Set metode pembayaran default ke QRIS jika tersedia, otherwise gunakan yang pertama
        final qrisMethod = activeChannels.firstWhere(
          (channel) => channel['code'] == 'QRIS',
          orElse: () => activeChannels.isNotEmpty ? activeChannels.first : {},
        );
        
        if (qrisMethod.isNotEmpty) {
          _selectedPaymentMethod = qrisMethod['code'];
          _selectedPaymentDetails = qrisMethod;
        } else if (activeChannels.isNotEmpty) {
          _selectedPaymentMethod = activeChannels.first['code'];
          _selectedPaymentDetails = activeChannels.first;
        }
      });
      
      print('Loaded ${activeChannels.length} payment channels');
      print('Default payment method: $_selectedPaymentMethod');
    } catch (e) {
      print('Error loading payment channels: $e');
      setState(() {
        _loadingPaymentChannels = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat metode pembayaran: $e')),
      );
    }
  }

  // Update selected payment details when method changes
  void _updateSelectedPaymentDetails(String code) {
    final selectedChannel = _paymentChannels.firstWhere(
      (channel) => channel['code'] == code,
      orElse: () => {},
    );
    
    setState(() {
      _selectedPaymentDetails = selectedChannel;
    });
    
    print('Selected payment method: $code');
    print('Payment details: ${selectedChannel['name']}');
  }

  // Proses pembayaran
  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Validasi metode pembayaran
      if (_selectedPaymentMethod.isEmpty) {
        throw Exception('Pilih metode pembayaran terlebih dahulu');
      }
      
      // Validasi jumlah pembayaran (min & max amount)
      if (_selectedPaymentDetails != null) {
        final minAmount = _selectedPaymentDetails!['minimum_amount'] ?? 0;
        final maxAmount = _selectedPaymentDetails!['maximum_amount'] ?? double.infinity;
        
        if (widget.totalAmount < minAmount) {
          throw Exception('Minimal pembayaran untuk metode ini adalah IDR ${NumberFormat('#,###').format(minAmount)}');
        }
        
        if (widget.totalAmount > maxAmount) {
          throw Exception('Maksimal pembayaran untuk metode ini adalah IDR ${NumberFormat('#,###').format(maxAmount)}');
        }
      }
      
      // Dapatkan user saat ini
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Format item pesanan untuk Tripay
      List<Map<String, dynamic>> formattedItems = widget.cartItems.map((item) {
        return {
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
        };
      }).toList();
      
      String orderItems = json.encode(formattedItems);
      String merchantRef = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      
      // Buat transaksi dengan metode pembayaran yang dipilih
      Map<String, dynamic> transaction = await TripayService.createTransaction(
        customerName: user.displayName ?? 'Customer',
        customerEmail: user.email ?? 'customer@example.com',
        orderItems: orderItems,
        amount: widget.totalAmount,
        merchantRef: merchantRef,
        paymentMethod: _selectedPaymentMethod,
        context: context,
      );
      
      if (transaction.isNotEmpty) {
        // Simpan pesanan ke Firebase
        await _saveOrder(merchantRef, transaction);
        
        // Tampilkan notifikasi pesanan baru
        await _showNewOrderNotification(merchantRef);
        
        // Buka halaman pembayaran dengan passing merchantRef dan reference
        await TripayService.openPaymentPage(
          transaction['checkout_url'],
          merchantRef: merchantRef,
          reference: transaction['reference'],
        );
        
        // Tampilkan dialog sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran berhasil! Status pemesanan telah diperbarui')),
          );
        }
        
        // Kembali ke layar sebelumnya
        if (mounted) {
          Navigator.pop(context, true); // Return true untuk menandakan checkout berhasil
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Replace the existing _saveOrder method with this improved version
Future<void> _saveOrder(String merchantRef, Map<String, dynamic> transaction) async {
  final user = FirebaseAuth.instance.currentUser;
  
  try {
    // Create the order data
    final orderData = {
      'userId': user?.uid,
      'orderDate': DateTime.now().toIso8601String(),
      'items': widget.cartItems,
      'totalAmount': widget.totalAmount,
      'status': 'pending',
      'paymentMethod': transaction['payment_method'],
      'paymentName': transaction['payment_name'],
      'checkoutUrl': transaction['checkout_url'],
      'merchantRef': merchantRef,
      'tripayReference': transaction['reference'],
    };
    
    // Save to Firebase
    await FirebaseDatabase.instance.ref().child('orders').child(merchantRef).set(orderData);
    
    // Setup listener for this specific order to track status changes
    NotificationService.setupOrderListener(merchantRef);
    
    // Show initial notification about successful order creation
    await _showNewOrderNotification(merchantRef);
    
    print('Order saved successfully: $merchantRef');
  } catch (e) {
    print('Error saving order: $e');
    throw e; // Re-throw for handling in the caller
  }
}

// Replace the existing _showNewOrderNotification method with this improved version
Future<void> _showNewOrderNotification(String merchantRef) async {
  try {
    // Generate a consistent notification ID from the merchant reference
    int notificationId = merchantRef.hashCode.abs();
    
    // Create a summary of items in the cart
    String itemsSummary = ''; 
    if (widget.cartItems.length > 2) {
      itemsSummary = '${widget.cartItems[0]['name']}, ${widget.cartItems[1]['name']} dan ${widget.cartItems.length - 2} item lainnya';
    } else if (widget.cartItems.length == 2) {
      itemsSummary = '${widget.cartItems[0]['name']} dan ${widget.cartItems[1]['name']}';
    } else if (widget.cartItems.length == 1) {
      itemsSummary = widget.cartItems[0]['name'];
    }
    
    // Format a reference ID that users can remember easily (shorter version)
    String shortRef = merchantRef.substring(4, min(10, merchantRef.length));
    
    await NotificationService.showOrderNotification(
      id: notificationId,
      title: 'Pesanan Baru: #$shortRef',
      body: 'Pesanan $itemsSummary telah dibuat dan sedang menunggu pembayaran. Total: IDR ${NumberFormat('#,###').format(widget.totalAmount)}',
      status: 'pending',
      payload: merchantRef, // Add the merchantRef as payload for navigation when tapped
    );
    
    print('Notification sent for new order: $merchantRef with ID: $notificationId');
  } catch (e) {
    print('Error showing notification: $e');
    // Continue execution, don't crash if notification fails
  }
}

// Helper function to get minimum value
int min(int a, int b) {
  return a < b ? a : b;
}

  /// Perubahan pada _showNewOrderNotification di CheckoutPage.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Daftar item di keranjang
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['image'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${item['quantity']}x IDR ${NumberFormat('#,###').format(item['price'])}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'IDR ${NumberFormat('#,###').format(item['price'] * item['quantity'])}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Section metode pembayaran
          if (_loadingPaymentChannels)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_paymentChannels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPaymentMethod,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedPaymentMethod = newValue;
                              _updateSelectedPaymentDetails(newValue);
                            });
                          }
                        },
                        items: _paymentChannels.map<DropdownMenuItem<String>>((channel) {
                          return DropdownMenuItem<String>(
                            value: channel['code'],
                            child: Text('${channel['name']}'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  // Payment method info
                  if (_selectedPaymentDetails != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Info Pembayaran: ${_selectedPaymentDetails!['name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Group: ${_selectedPaymentDetails!['group']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            'Minimal: IDR ${NumberFormat('#,###').format(_selectedPaymentDetails!['minimum_amount'] ?? 0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          Text(
                            'Maksimal: IDR ${NumberFormat('#,###').format(_selectedPaymentDetails!['maximum_amount'] ?? 0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          if (_selectedPaymentDetails!['total_fee']['flat'] > 0 || 
                              double.parse(_selectedPaymentDetails!['total_fee']['percent'].toString()) > 0)
                            Text(
                              'Biaya: IDR ${NumberFormat('#,###').format(_selectedPaymentDetails!['total_fee']['flat'])} + ${_selectedPaymentDetails!['total_fee']['percent']}%',
                              style: const TextStyle(fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Section total dan tombol bayar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pesanan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'IDR ${NumberFormat('#,###').format(widget.totalAmount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC793B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Bayar Sekarang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}