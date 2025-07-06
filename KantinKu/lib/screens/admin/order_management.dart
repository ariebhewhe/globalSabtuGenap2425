import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../data/notification_service.dart';
import 'dart:math';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final DatabaseReference _orderDatabase = FirebaseDatabase.instance.ref().child('orders');
  final DatabaseReference _userDatabase = FirebaseDatabase.instance.ref().child('users');
  Map<String, dynamic> _users = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await _userDatabase.get();
      if (snapshot.value != null) {
        setState(() {
          _users = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getCustomerName(String? userId) {
    if (userId == null) return 'Pelanggan';
    return _users[userId]?['name'] ?? 'Pelanggan';
  }

  // Mendapatkan semua informasi pelanggan
  Map<String, dynamic>? _getCustomerInfo(String? userId) {
    if (userId == null || !_users.containsKey(userId)) {
      return null;
    }
    return _users[userId];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }

  Future<void> _showStatusChangeNotification(Map<dynamic, dynamic> order, String orderId, String newStatus) async {
    try {
      int notificationId = orderId.hashCode.abs();
      
      String title, body;
      
      switch (newStatus) {
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
        default:
          title = 'Status Pesanan: #${orderId.substring(0, min(8, orderId.length))}';
          body = 'Status pesanan Anda telah diperbarui menjadi: ${_getStatusText(newStatus)}';
      }
      
      await NotificationService.showOrderNotification(
        id: notificationId,
        title: title,
        body: body,
        status: newStatus,
      );
      
      debugPrint('Status notification sent: $newStatus for order: $orderId with ID: $notificationId');
    } catch (e) {
      debugPrint('Error showing status notification: $e');
    }
  }

  void _showCustomerDetailsDialog(String? userId, BuildContext context) {
    if (userId == null) return;
    
    final customerInfo = _getCustomerInfo(userId);
    if (customerInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi pelanggan tidak tersedia')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFFDC793B)),
            const SizedBox(width: 8),
            const Text('Detail Pelanggan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerDetailItem(Icons.person, 'Nama', customerInfo['name'] ?? 'Tidak tersedia'),
              const SizedBox(height: 12),
              _buildCustomerDetailItem(Icons.email, 'Email', customerInfo['email'] ?? 'Tidak tersedia'),
              const SizedBox(height: 12),
              _buildCustomerDetailItem(Icons.phone, 'Telepon', customerInfo['phone'] ?? 'Tidak tersedia'),
              if (customerInfo['profileImage'] != null && customerInfo['profileImage'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    customerInfo['profileImage'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFFDC793B))),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderStatusButton(String currentStatus, String orderId, Map<dynamic, dynamic> order) {
    return PopupMenuButton<String>(
      onSelected: (String status) async {
        // Update status pesanan di database
        await _orderDatabase.child(orderId).update({
          'status': status
        });
        
        // Tampilkan notifikasi perubahan status
        await _showStatusChangeNotification(order, orderId.toString(), status);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status diubah ke ${_getStatusText(status)}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'pending',
          child: Row(
            children: [
              Icon(Icons.timer, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text('Menunggu'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'processing',
          child: Row(
            children: [
              Icon(Icons.sync, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Diproses'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'completed',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text('Selesai'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cancelled',
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Dibatalkan'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(currentStatus),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor(currentStatus).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getStatusText(currentStatus),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC793B)));
    }
    
    return StreamBuilder(
      stream: _orderDatabase.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton(
                  onPressed: _loadUsers,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pesanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pesanan baru akan muncul di sini',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        Map<dynamic, dynamic> orders = Map<dynamic, dynamic>.from(
            snapshot.data!.snapshot.value as Map);

        List<MapEntry<dynamic, dynamic>> orderList = orders.entries.toList();
        orderList.sort((a, b) => DateTime.parse(b.value['orderDate'])
            .compareTo(DateTime.parse(a.value['orderDate'])));

        return RefreshIndicator(
          onRefresh: _loadUsers,
          color: const Color(0xFFDC793B),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orderList.length,
            itemBuilder: (context, index) {
              final order = orderList[index].value;
              final orderId = orderList[index].key.toString();
              final orderDate = DateTime.parse(order['orderDate']);
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(orderDate);
              final userId = order['userId'];
              final customerName = _getCustomerName(userId);

              // Calculate total from items
              double total = 0;
              List<dynamic> items = order['items'] as List<dynamic>;
              for (var item in items) {
                total += (item['price'] as num) * (item['quantity'] as num);
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: Colors.black.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Color(0xFFDC793B)),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          _buildOrderStatusButton(order['status'], orderId, order),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _showCustomerDetailsDialog(userId, context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFDC793B).withOpacity(0.2),
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Color(0xFFDC793B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.info_outline, size: 16, color: Color(0xFFDC793B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC793B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDC793B).withOpacity(0.2)),
                        ),
                        child: Text(
                          'Order #${orderId.substring(0, min(8, orderId.length))}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFDC793B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.restaurant, size: 16, color: Color(0xFFDC793B)),
                                SizedBox(width: 6),
                                Text(
                                  'Pesanan:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const Divider(height: 16),
                              itemBuilder: (context, idx) {
                                final item = items[idx];
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDC793B).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item['quantity']}x',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFDC793B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item['name'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(item['price'] * item['quantity']),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp',
                                  decimalDigits: 0,
                                ).format(total),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tampilkan catatan jika ada
                      if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Icon(Icons.note_alt, size: 16, color: Color(0xFFDC793B)),
                                SizedBox(width: 6),
                                Text(
                                  'Catatan:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                order['notes'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}