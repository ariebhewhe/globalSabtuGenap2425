// lib/screens/user/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/main.dart'; // Pastikan supabase client diekspor atau diakses dari sini
import 'package:qurbanqu/presentation/home/pages/home_screen.dart';
import 'package:qurbanqu/presentation/order/pages/order_history_screen.dart';
import 'package:qurbanqu/service/order_service.dart';
import 'package:qurbanqu/model/order_model.dart';
import 'package:qurbanqu/common/custom_button.dart'; // Asumsi Anda punya widget ini
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

// import 'package:supabase_flutter/supabase_flutter.dart'; // Hapus jika sudah ada di main.dart dan terekspos global

class PaymentScreen extends StatefulWidget {
  final String orderId;

  const PaymentScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final OrderService _orderService = OrderService();
  OrderModel? _order;
  bool _isLoading = true;
  XFile? _selectedImage;
  bool _isUploading = false;
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Inisialisasi DateFormat di sini agar locale terpakai
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data pesanan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _uploadBuktiTransfer() async {
    if (_selectedImage == null || _order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih gambar dan pastikan data pesanan ada.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tambahan null check untuk order ID, meskipun seharusnya tidak null jika _order tidak null
    if (_order!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Pesanan tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // getPublicUrl mengembalikan String, bukan String?. Jadi uploadedImageUrl akan String.
      String uploadedImageUrl;
      final bytes = await _selectedImage!.readAsBytes();
      final fileExt = _selectedImage!.path.split('.').last.toLowerCase();
      final fileName =
          'bukti_transfer/${_order!.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      final String bucketName = 'images'; // PASTIKAN BUCKET INI ADA

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _selectedImage!.mimeType ?? 'image/$fileExt',
              upsert: false,
            ),
          );

      uploadedImageUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      // Tidak perlu cek null untuk uploadedImageUrl karena getPublicUrl akan throw error jika gagal.
      // Jika ingin lebih aman, bisa dibungkus try-catch spesifik untuk getPublicUrl.

      await _orderService.updateOrderAfterPayment(
        _order!.id, // _order sudah dijamin tidak null di awal fungsi
        uploadedImageUrl, // Ini adalah String, bukan String?
        'pending',
      );

      if (!mounted) return;
      await _loadOrderData();

      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Bukti Transfer Terunggah'),
              content: const Text(
                'Bukti transfer Anda telah berhasil diunggah. Pesanan Anda sedang pending.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah bukti transfer: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pembayaran')),
        body: const Center(child: Text('Data pesanan tidak ditemukan')),
      );
    }

    // Gunakan variabel lokal untuk status dan fotoBuktiTransfer untuk menghindari null access
    // dan memastikan tipe data yang benar (dengan asumsi OrderModel Anda memberi default string kosong)
    String orderStatus =
        _order!
            .status; // Jika OrderModel menjamin status tidak null (misal default ke '')
    String orderFotoBukti = _order!.fotoBuktiTransfer!;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Pembayaran'),
              const SizedBox(height: 8),
              Container(
                // ... (Container Informasi Pembayaran tetap sama) ...
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem(
                      'Total Pembayaran',
                      formatCurrency.format(_order!.totalHarga),
                      valueColor: AppColors.primary,
                      valueFontSize: 18,
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Silakan transfer sesuai nominal di atas ke rekening:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildBankInfo(
                      bankName: 'Bank BCA',
                      accountNumber: '1234567890',
                      accountName: 'PT. QurbanQu Indonesia',
                    ),
                    const SizedBox(height: 8),
                    _buildBankInfo(
                      bankName: 'Bank Mandiri',
                      accountNumber: '0987654321',
                      accountName: 'PT. QurbanQu Indonesia',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Detail Pesanan'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('ID Pesanan', _order!.id),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Tanggal Pesanan',
                      // Perbaiki format tanggal dan pastikan locale 'id_ID' sudah di set
                      DateFormat(
                        'dd MMMM yyyy, HH:mm',
                      ).format(_order!.tanggalPesanan),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem('Jumlah', '${_order!.jumlah} ekor'),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Total Harga',
                      formatCurrency.format(_order!.totalHarga),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoItem(
                      'Status',
                      // Akses orderStatus yang sudah dijamin String
                      orderStatus.isNotEmpty
                          ? orderStatus.replaceAll('_', ' ').toUpperCase()
                          : 'N/A',
                      valueColor: _getStatusColor(
                        orderStatus,
                      ), // orderStatus adalah String
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (orderStatus == 'menunggu pembayaran') ...[
                // Gunakan orderStatus
                _buildSectionTitle('Upload Bukti Transfer'),
                const SizedBox(height: 8),
                Container(
                  // ... (Container Upload Bukti Transfer tetap sama) ...
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Silakan unggah bukti transfer untuk memverifikasi pembayaran Anda:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Pilih Gambar',
                              onPressed: _pickImage,
                              icon: Icons.photo_library,
                              color: AppColors.primary.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomButton(
                              onPressed: () {
                                if (_selectedImage != null) {
                                  _uploadBuktiTransfer();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Silakan pilih gambar terlebih dahulu',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              text: 'Upload Bukti',
                              isLoading: _isUploading,
                              icon: Icons.upload,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (orderFotoBukti.isNotEmpty) ...[
                // Gunakan orderFotoBukti
                _buildSectionTitle('Bukti Transfer Terunggah'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderStatus ==
                                'pending' // Gunakan orderStatus
                            ? 'Bukti transfer Anda sedang pending oleh admin.'
                            : 'Bukti transfer Anda telah diterima.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          orderFotoBukti, // orderFotoBukti adalah String
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                            BuildContext context,
                            Widget child,
                            ImageChunkEvent? loadingProgress,
                          ) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 40,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    Color valueColor = Colors.black87,
    double valueFontSize = 14,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankInfo({
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) {
    // ... (Widget _buildBankInfo tetap sama) ...
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bankName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                accountNumber,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                iconSize: 18,
                splashRadius: 20,
                onPressed: () {
                  // Clipboard.setData(ClipboardData(text: accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nomor rekening disalin (implementasi copy belum ada)',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: AppColors.primary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'a.n $accountName',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    // Parameter status sekarang adalah String non-nullable
    switch (status.toLowerCase()) {
      case 'menunggu pembayaran':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      case 'diproses':
        return Colors.teal;
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return AppColors.primary; // atau Colors.grey jika status tidak dikenal
    }
  }
}
