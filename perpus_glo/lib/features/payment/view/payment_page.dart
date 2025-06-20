import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:perpusglo/features/borrow/data/borrow_repository.dart';
import 'package:perpusglo/features/borrow/model/borrow_model.dart';
import 'package:perpusglo/features/notification/model/notification_model.dart';
import 'package:perpusglo/features/notification/providers/notification_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../model/payment_model.dart';
import '../providers/payment_provider.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard

class PaymentPage extends ConsumerStatefulWidget {
  final String fineId; // ID of the borrow record
  final double amount;

  PaymentPage({
    super.key,
    required this.fineId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentModel? _payment;
  BorrowModel? _borrowDetail;
  bool _isQrScanning = false;
  int _selectedPaymentMethod = 0; // 0 = QR, 1 = Transfer, 2 = Cash

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _createPayment();
    _fetchBorrowDetail();
  }

  Future<void> _fetchBorrowDetail() async {
    try {
      final borrow =
          await ref.read(borrowRepositoryProvider).getBorrowById(widget.fineId);
      if (borrow != null) {
        setState(() {
          _borrowDetail = borrow;
        });
      }
    } catch (e) {
      print("Error fetching borrow details: $e");
    }
  }

  Future<void> _createPayment() async {
    final payment = await ref
        .read(paymentControllerProvider.notifier)
        .createPayment(widget.fineId, widget.amount);

    if (payment != null) {
      setState(() {
        _payment = payment;
      });
    }
  }

  // Perbaikan di PaymentPage
  void _completePayment() async {
    if (_payment == null) {
      print('Payment is null, cannot complete');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pembayaran tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentMethod = _getPaymentMethodName();
    print('Selected payment method: $paymentMethod');
    print('Payment ID: ${_payment!.id}');
    print('Borrow ID: ${widget.fineId}');

    try {
      // Tampilkan loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Memproses pembayaran..."),
              ],
            ),
          ),
        ),
      );

      print('Calling completePayment with ID: ${_payment!.id}');
      final success = await ref
          .read(paymentControllerProvider.notifier)
          .completePayment(_payment!.id, paymentMethod);
      print('completePayment returned: $success');

      // Tutup dialog loading
      if (mounted) Navigator.of(context).pop();

      if (success && mounted) {
        print('Payment successful, sending notification');
        // Tambahkan notifikasi ke admin bahwa user telah membayar denda
        try {
          final notificationService = ref.read(notificationServiceProvider);
          await notificationService.createNotificationForAdmins(
            title: 'Denda Telah Dibayar',
            body:
                'User telah membayar denda untuk buku "${_borrowDetail?.bookTitle ?? 'Unknown Book'}"',
            type: NotificationType.payment,
            data: {
              'borrowId': widget.fineId,
              'paymentId': _payment!.id,
              'amount': widget.amount.toString(),
            },
          );
          print('Notification sent successfully');
        } catch (e) {
          print('Error sending notification: $e');
          // Lanjutkan meskipun notifikasi gagal
        }

        // Tampilkan pesan sukses
        print('Showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Pembayaran berhasil! Silakan tunggu konfirmasi pengembalian dari pustakawan.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigasi kembali ke halaman riwayat peminjaman
        print('Navigating back to borrow-history');
        if (mounted) {
          context.go('/borrow-history');
        }
      } else {
        print('Payment failed or component not mounted');
        if (mounted) {
          // Tampilkan pesan error jika gagal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal melakukan pembayaran. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Exception caught in _completePayment: $e');
      // Tutup dialog loading jika terjadi exception
      if (mounted) Navigator.of(context).pop();

      // Tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelPayment() async {
    if (_payment == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pembayaran'),
        content:
            const Text('Apakah Anda yakin ingin membatalkan pembayaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('TIDAK'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YA, BATALKAN'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(paymentControllerProvider.notifier)
          .cancelPayment(_payment!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran dibatalkan'),
            backgroundColor: Colors.orange,
          ),
        );

        Navigator.pop(context);
      }
    }
  }

  Future<void> _launchQrPayment() async {
    if (_payment?.paymentQrUrl == null) return;

    final url = Uri.parse(_payment!.paymentQrUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka QR Code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPaymentMethodName() {
    switch (_selectedPaymentMethod) {
      case 0:
        return 'QR Code';
      case 1:
        return 'Transfer Bank';
      case 2:
        return 'Tunai';
      default:
        return 'QR Code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Denda'),
      ),
      body: paymentState.isLoading && _payment == null
          ? const Center(child: LoadingIndicator())
          : _payment == null
              ? _buildErrorState()
              : _buildPaymentForm(),
      bottomNavigationBar: _payment != null ? _buildBottomButtons() : null,
    );
  }

  Widget _buildErrorState() {
    final paymentState = ref.watch(paymentControllerProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data pembayaran',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (paymentState.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Error: ${paymentState.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createPayment,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Borrow Info - Tambahkan ini
          if (_borrowDetail != null)
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Peminjaman',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Book info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book cover
                        if (_borrowDetail!.bookCover != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _borrowDetail!.bookCover!,
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 90,
                                color: Colors.grey[300],
                                child: const Icon(Icons.book),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 60,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book),
                          ),

                        const SizedBox(width: 12),

                        // Book details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _borrowDetail!.bookTitle ?? 'Unknown Book',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              if (_borrowDetail!.booksAuthor != null)
                                Text(_borrowDetail!.booksAuthor!,
                                    style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                              Text(
                                'Jatuh Tempo: ${DateFormat('dd MMM yyyy').format(_borrowDetail!.dueDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _borrowDetail!.dueDate
                                          .isBefore(DateTime.now())
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                              if (_borrowDetail!.returnDate != null)
                                Text(
                                  'Dikembalikan: ${DateFormat('dd MMM yyyy').format(_borrowDetail!.returnDate!)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Payment method selection
          const Text(
            'Pilih Metode Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Payment method options
          _buildPaymentMethodSelection(),

          const SizedBox(height: 24),

          // Selected payment method details
          _buildSelectedPaymentMethod(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      children: [
        // QR Code Payment
        RadioListTile(
          value: 0,
          groupValue: _selectedPaymentMethod,
          title: const Text('QR Code (QRIS)'),
          subtitle: const Text(
              'Bayar dengan QR Code via mobile banking atau e-wallet'),
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value as int;
              _isQrScanning = false;
            });
          },
        ),

        // Bank Transfer
        RadioListTile(
          value: 1,
          groupValue: _selectedPaymentMethod,
          title: const Text('Transfer Bank'),
          subtitle: const Text('Bayar dengan transfer bank'),
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value as int;
              _isQrScanning = false;
            });
          },
        ),

        // Cash
        RadioListTile(
          value: 2,
          groupValue: _selectedPaymentMethod,
          title: const Text('Tunai'),
          subtitle: const Text('Bayar langsung ke petugas perpustakaan'),
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value as int;
              _isQrScanning = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSelectedPaymentMethod() {
    switch (_selectedPaymentMethod) {
      case 0: // QR Code
        return _buildQrCodePayment();
      case 1: // Transfer Bank
        return _buildBankTransferPayment();
      case 2: // Cash
        return _buildCashPayment();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQrCodePayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran QR Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // QR Code Image or Scanner
        if (_isQrScanning)
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: MobileScannerController(),
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && mounted) {
                    setState(() {
                      _isQrScanning = false;
                    });

                    // In a real app, verify the QR code with the server
                    // For this demo, we'll just show a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR Code berhasil dipindai'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          )
        else
          Center(
            child: Column(
              children: [
                // QR Code display
                if (_payment?.paymentQrUrl != null)
                  GestureDetector(
                    onTap: _launchQrPayment,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          _payment!.paymentQrUrl!,
                          height: 200,
                          width: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: 200,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.qr_code,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                const Text(
                  'Scan QR Code ini dengan aplikasi mobile banking atau e-wallet Anda',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isQrScanning = true;
                    });
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code Pembayaran'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBankTransferPayment() {
    // Dapatkan username dari email (sebelum @)
    String norekFromEmail = '';
    if (_borrowDetail?.userEmail != null) {
      norekFromEmail = _borrowDetail!.userEmail!.split('@')[0];
    }

    // Dapatkan nama pengguna
    String userName = _borrowDetail?.userName ?? 'Global Institute';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transfer Bank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Bank account info
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Rekening Bank',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildBankInfo('Bank Mandiri', norekFromEmail, userName),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Silakan transfer sesuai jumlah denda. Setelah transfer, tekan tombol "Konfirmasi Pembayaran" untuk menyelesaikan proses pembayaran.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBankInfo(
      String bankName, String accountNumber, String accountName) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/images/bank-mandiri-logo.png', // Logo Bank Mandiri
                  width: 80,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Text(
                    bankName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: accountNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nomor rekening $bankName disalin'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Salin nomor rekening',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Nomor Rekening',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  accountNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.content_copy, size: 16),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: accountNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nomor rekening disalin'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Atas Nama',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              accountName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nominal: ${currencyFormat.format(widget.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pembayaran Tunai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pembayaran Tunai',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan lakukan pembayaran tunai di meja petugas perpustakaan. Setelah membayar, petugas akan memperbarui status pembayaran Anda.',
              ),
              const SizedBox(height: 16),
              Text(
                'Total yang harus dibayar: ${currencyFormat.format(widget.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final paymentState = ref.watch(paymentControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            flex: 1,
            child: TextButton(
              onPressed: paymentState.isLoading ? null : _cancelPayment,
              child: const Text('BATALKAN'),
            ),
          ),

          const SizedBox(width: 16),

          // Confirm payment button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: paymentState.isLoading ? null : _completePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: paymentState.isLoading
                  ? const LoadingIndicator(color: Colors.white)
                  : const Text('KONFIRMASI PEMBAYARAN'),
            ),
          ),
        ],
      ),
    );
  }
}