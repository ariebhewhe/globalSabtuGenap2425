import 'package:firebase_auth/firebase_auth.dart'; // DIPERLUKAN
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // TAMBAHKAN IMPORT INI
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/core/config/styles.dart';
import 'package:qurbanqu/model/order_model.dart'; // Sudah termasuk PopulatedOrderModel
import 'package:qurbanqu/presentation/order/pages/order_history_detail_screen.dart';
import 'package:qurbanqu/service/order_service.dart'; // DIPERLUKAN

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  // Ubah tipe list menjadi List<PopulatedOrderModel>
  List<PopulatedOrderModel> _populatedOrderList = [];

  // Inisialisasi service dan auth
  final OrderService _orderService = OrderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeLocaleData(); // TAMBAHKAN INISIALISASI LOCALE
  }

  // TAMBAHKAN METODE INI
  Future<void> _initializeLocaleData() async {
    await initializeDateFormatting('id_ID', null);
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return; // Pemeriksaan mounted di awal
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Harap login untuk melihat riwayat pesanan.'),
            ),
          );
          setState(() {
            _populatedOrderList = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Panggil metode baru dari OrderService
      List<PopulatedOrderModel> populatedOrders = await _orderService
          .getPopulatedOrdersByUserId(currentUser.uid);

      if (mounted) {
        setState(() {
          _populatedOrderList = populatedOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error memuat riwayat pesanan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat pesanan: ${e.toString()}'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Metode untuk pembatalan pesanan
  Future<void> _cancelOrder(PopulatedOrderModel populatedOrder) async {
    // Tampilkan dialog konfirmasi
    bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembatalan'),
          content: const Text(
            'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        );
      },
    );

    // Jika user memilih untuk membatalkan
    if (shouldCancel == true) {
      try {
        // Tampilkan loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Membatalkan pesanan...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Panggil service untuk membatalkan pesanan
        await _orderService.cancelOrder(populatedOrder.order.id);

        // Hapus dari list lokal
        if (mounted) {
          setState(() {
            _populatedOrderList.removeWhere(
              (item) => item.order.id == populatedOrder.order.id,
            );
          });

          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil dibatalkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error membatalkan pesanan: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membatalkan pesanan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    // Normalisasi status untuk perbandingan yang lebih andal
    String normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'menunggu pembayaran':
      case 'pending': // Jika 'pending' juga digunakan
        return Colors.orange;

      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    String normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'menunggu pembayaran':
        return 'Pending';
      case 'pending':
        return 'Pending';
      case 'diproses':
        return 'Sedang Diproses';
      case 'success':
        return 'success';
      case 'failed':
        return 'failed';
      default:
        // Mengembalikan status asli dengan huruf kapital di awal kata
        return status
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ', // Memberi spasi setelah Rp
      decimalDigits: 0,
    );

    final formatDate = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id_ID',
    ); // Menggunakan yyyy untuk tahun

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _populatedOrderList.isEmpty
              ? Center(
                child: Padding(
                  // Tambahkan padding untuk tampilan yang lebih baik
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 72,
                        color: Colors.grey[400],
                      ), // Icon yang lebih relevan
                      const SizedBox(height: 16),
                      const Text(
                        'Riwayat Pesanan Kosong',
                        style: AppStyles.heading2,
                      ), // Teks yang lebih jelas
                      const SizedBox(height: 8),
                      const Text(
                        'Anda belum melakukan pemesanan. Semua pesanan Anda akan tampil di sini.',
                        style: AppStyles.bodyTextSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(
                            context,
                          ); // Kembali ke halaman sebelumnya atau ke halaman utama belanja
                        },
                        child: const Text(
                          'Mulai Belanja Sekarang',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _populatedOrderList.length,
                  itemBuilder: (context, index) {
                    final populatedOrder = _populatedOrderList[index];
                    final order = populatedOrder.order;
                    final product =
                        populatedOrder.product; // ProductModel bisa null

                    // Menangani kasus jika produk tidak ditemukan (misalnya, sudah dihapus)
                    if (product == null) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesanan ID: ${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Detail produk untuk pesanan ini tidak dapat ditemukan. Produk mungkin telah dihapus atau tidak tersedia lagi.',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tanggal Pesan: ${formatDate.format(order.tanggalPesanan)}',
                              ),
                              Text(
                                'Total Harga: ${formatCurrency.format(order.totalHarga)}',
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Tampilan normal jika produk ada
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10, // Sedikit lebih lebar
                                    vertical: 5, // Sedikit lebih tinggi
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      order.status,
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _getStatusText(order.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(order.status),
                                    ),
                                  ),
                                ),
                                Text(
                                  formatDate.format(order.tanggalPesanan),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child:
                                      product.gambar.isNotEmpty
                                          ? Image.network(
                                            product.gambar,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (
                                              BuildContext context,
                                              Widget child,
                                              ImageChunkEvent? loadingProgress,
                                            ) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.0,
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey[400],
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: Colors.grey[400],
                                              size: 40,
                                            ),
                                          ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.nama,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jenis: ${product.jenis}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Jumlah: ${order.jumlah} ekor',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: ${formatCurrency.format(order.totalHarga)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Tombol batalkan hanya muncul jika pesanan bisa dibatalkan
                                if (order.status.toLowerCase() ==
                                        'menunggu pembayaran' ||
                                    order.status.toLowerCase() == 'pending')
                                  OutlinedButton(
                                    onPressed:
                                        () => _cancelOrder(populatedOrder),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      side: const BorderSide(
                                        color: Colors.redAccent,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Batalkan'),
                                  ),
                                if (order.status.toLowerCase() ==
                                        'menunggu pembayaran' ||
                                    order.status.toLowerCase() == 'pending')
                                  const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => OrderHistoryDetail(
                                              populatedOrder: populatedOrder,
                                            ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Lihat Detail'),
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
    );
  }
}
