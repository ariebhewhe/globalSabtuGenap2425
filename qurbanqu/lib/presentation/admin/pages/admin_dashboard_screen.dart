import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/core/config/styles.dart';
import 'package:qurbanqu/presentation/admin/pages/admin_kelola_screen.dart';
import 'package:qurbanqu/presentation/admin/pages/admin_order_screen.dart';
import 'package:qurbanqu/presentation/auth/pages/login_screen.dart';
import 'package:qurbanqu/service/order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final OrderService _orderService = OrderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _hasError = false;

  final Map<String, dynamic> _dashboardData = {
    'totalPesanan': 0,
    'totalPendapatan': 0,
    'pesananBaru': 0,
    'pesananDiproses': 0,
    'pesananSelesai': 0,
    'recentOrders': [],
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final orders = await _orderService.getAllOrders();

      int totalPesanan = orders.length;
      double totalPendapatan = 0;
      int pesananBaru = 0;
      int pesananDiproses = 0;
      int pesananSelesai = 0;
      List<Map<String, dynamic>> recentOrders = [];

      for (var orderData in orders) {
        totalPendapatan += orderData.order.totalHarga;

        switch (orderData.order.status.toLowerCase()) {
          case 'menunggu pembayaran':
          case 'pending':
            pesananBaru++;
            break;
          case 'diproses':
          case 'sedang diproses':
            pesananDiproses++;
            break;
          case 'selesai':
          case 'success':
            pesananSelesai++;
            break;
        }

        if (recentOrders.length < 5) {
          recentOrders.add({
            'id': orderData.order.id,
            'customer': orderData.user?.nama ?? 'Pengguna',
            'hewan': orderData.product?.nama ?? 'Produk tidak tersedia',
            'tanggal': orderData.order.tanggalPesanan,
            'total': orderData.order.totalHarga,
            'status': orderData.order.status,
          });
        }
      }

      recentOrders.sort(
        (a, b) =>
            (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime),
      );

      if (mounted) {
        setState(() {
          _dashboardData['totalPesanan'] = totalPesanan;
          _dashboardData['totalPendapatan'] = totalPendapatan;
          _dashboardData['pesananBaru'] = pesananBaru;
          _dashboardData['pesananDiproses'] = pesananDiproses;
          _dashboardData['pesananSelesai'] = pesananSelesai;
          _dashboardData['recentOrders'] = recentOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error mengambil data dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (result == true) {
      try {
        await _auth.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
      }
    }
  }

  Future<void> _processOrder(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);
      await _loadDashboardData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pesanan berhasil diperbarui')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    }
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('pending')) {
      return Colors.orange;
    } else if (status.contains('gagal') || status == 'failed') {
      return Colors.red;
    } else if (status.contains('selesai') || status == 'success') {
      return Colors.green;
    } else if (status.contains('proses')) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final formatDate = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Gagal memuat data'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDashboardData,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selamat Datang, Admin!', style: AppStyles.heading1),
                      Text(
                        'Berikut adalah ringkasan data QurbanQu',
                        style: AppStyles.bodyTextSmall,
                      ),
                      const SizedBox(height: 24),

                      // Statistik Utama
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Pesanan',
                              value: _dashboardData['totalPesanan'].toString(),
                              icon: Icons.shopping_cart,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Pendapatan',
                              value: formatCurrency.format(
                                _dashboardData['totalPendapatan'],
                              ),
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Pesanan Baru',
                              value: _dashboardData['pesananBaru'].toString(),
                              icon: Icons.new_releases,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Dalam Proses',
                              value:
                                  _dashboardData['pesananDiproses'].toString(),
                              icon: Icons.pending_actions,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Selesai',
                              value:
                                  _dashboardData['pesananSelesai'].toString(),
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pesanan Terbaru
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pesanan Terbaru',
                            style: AppStyles.heading2,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminOrdersScreen(),
                                ),
                              );
                            },
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if ((_dashboardData['recentOrders'] as List).isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              'Belum ada pesanan',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ...(_dashboardData['recentOrders'] as List).map((
                          order,
                        ) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Order #${order['id'].substring(0, 6)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            order['status'],
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          order['status'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(
                                              order['status'],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Customer',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(order['customer']),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Hewan',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(order['hewan']),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Tanggal',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              formatDate.format(
                                                order['tanggal'],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              formatCurrency.format(
                                                order['total'],
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed:
                                            () => _showOrderDetails(
                                              context,
                                              order,
                                            ),
                                        child: const Text('Detail'),
                                      ),
                                      const SizedBox(width: 8),
                                      if (order['status'].toLowerCase() ==
                                              'menunggu pembayaran' ||
                                          order['status'].toLowerCase() ==
                                              'pending')
                                        ElevatedButton(
                                          onPressed:
                                              () => _processOrder(
                                                order['id'],
                                                'diproses',
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text(
                                            'Konfirmasi Pembayaran',
                                          ),
                                        )
                                      else if (order['status'].toLowerCase() ==
                                          'diproses')
                                        ElevatedButton(
                                          onPressed:
                                              () => _processOrder(
                                                order['id'],
                                                'selesai',
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Selesaikan'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminKelolaScreen()),
          );
        },
        icon: const Icon(Icons.pets),
        label: const Text('Kelola Hewan'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Detail Pesanan #${order['id'].substring(0, 6)}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID Pesanan', order['id']),
                _buildDetailRow('Customer', order['customer']),
                _buildDetailRow('Produk', order['hewan']),
                _buildDetailRow(
                  'Tanggal',
                  DateFormat('dd/MM/yyyy HH:mm').format(order['tanggal']),
                ),
                _buildDetailRow(
                  'Total',
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp',
                    decimalDigits: 0,
                  ).format(order['total']),
                ),
                _buildDetailRow('Status', order['status']),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
