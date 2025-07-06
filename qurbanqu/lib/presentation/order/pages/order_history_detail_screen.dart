import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/model/order_model.dart';

class OrderHistoryDetail extends StatelessWidget {
  final PopulatedOrderModel populatedOrder;

  const OrderHistoryDetail({super.key, required this.populatedOrder});

  @override
  Widget build(BuildContext context) {
    final order = populatedOrder.order;
    final product = populatedOrder.product;

    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final formatDate = DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body:
          product == null
              ? const Center(
                child: Text(
                  'Detail produk tidak ditemukan.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gambar Produk
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        product.gambar,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              height: 220,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kartu Detail Produk
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nama,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _buildDetailRow('Jenis', product.jenis),
                            _buildDetailRow('Jumlah', '${order.jumlah} ekor'),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(
                                  Icons.monitor_weight_outlined,
                                  color: Colors.brown,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Berat per Ekor: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '${product.berat} kg',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Row(
                            //   children: [
                            //     const Icon(
                            //       Icons.verified_outlined,
                            //       color: Colors.green,
                            //     ),
                            //     const SizedBox(width: 8),
                            //     Text(
                            //       'Kualitas: ',
                            //       style: const TextStyle(
                            //         fontWeight: FontWeight.w600,
                            //         color: Colors.black87,
                            //       ),
                            //     ),
                            //     Container(
                            //       padding: const EdgeInsets.symmetric(
                            //         horizontal: 10,
                            //         vertical: 4,
                            //       ),
                            //       decoration: BoxDecoration(
                            //         color: Colors.amber.withOpacity(0.2),
                            //         borderRadius: BorderRadius.circular(8),
                            //       ),
                            //       // child: Text(
                            //       //   product.kualitas,
                            //       //   style: const TextStyle(
                            //       //     fontWeight: FontWeight.bold,
                            //       //     color: Colors.amber,
                            //       //   ),
                            //       // ),
                            //     ),
                            //   ],
                            // ),
                            // const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),

                            _buildDetailRow(
                              'Total Harga',
                              formatCurrency.format(order.totalHarga),
                            ),
                            _buildDetailRow(
                              'Tanggal Pesan',
                              formatDate.format(order.tanggalPesanan),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${_capitalize(order.status)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
