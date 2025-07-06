import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/service/order_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'semua';

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    setState(() => _isLoading = true);

    try {
      final orders = await _orderService.getAllOrders();

      final formattedOrders =
          orders
              .map(
                (orderData) => {
                  'id': orderData.order.id,
                  'customer': orderData.user?.nama ?? 'Pengguna',
                  'hewan': orderData.product?.nama ?? 'Produk tidak tersedia',
                  'tanggal': orderData.order.tanggalPesanan,
                  'total': orderData.order.totalHarga,
                  'status': orderData.order.status,
                },
              )
              .toList();

      formattedOrders.sort(
        (a, b) =>
            (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime),
      );

      if (mounted) {
        setState(() {
          _allOrders = formattedOrders;
          _isLoading = false;
        });
        // Terapkan filter setelah data dimuat
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat pesanan: $e')));
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders =
          _allOrders.where((order) {
            final matchesStatus =
                _filterStatus == 'semua' ||
                order['status'].toLowerCase().contains(_filterStatus);
            final matchesSearch =
                _searchController.text.isEmpty ||
                order['customer'].toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                order['hewan'].toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                order['id'].toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
            return matchesStatus && matchesSearch;
          }).toList();
    });
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('pending')) return Colors.orange;
    if (status.contains('gagal') || status == 'failed') return Colors.red;
    if (status.contains('selesai') || status == 'success') return Colors.green;
    if (status.contains('proses')) return Colors.blue;
    return Colors.grey;
  }

  Future<void> _processOrder(String orderId, String newStatus) async {
    try {
      await _orderService.updateOrderStatus(orderId, newStatus);

      // Tampilkan loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 8),
                Text('Memperbarui status...'),
              ],
            ),
          ),
        );
      }

      // Muat ulang data
      await _loadAllOrders();

      // Terapkan filter kembali
      if (mounted) {
        _applyFilters();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status pesanan berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    }
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
        title: const Text('Semua Pesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllOrders,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari pesanan...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (value) => _applyFilters(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterStatus,
                          items:
                              [
                                'semua',
                                'pending',
                                'diproses',
                                'selesai',
                                'dibatalkan',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value[0].toUpperCase() + value.substring(1),
                                  ),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _filterStatus = newValue!;
                              _applyFilters();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadAllOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
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
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
