import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../model/borrow_model.dart';
import '../providers/borrow_provider.dart';
import 'borrow_detail_page.dart';

class BorrowHistoryPage extends ConsumerStatefulWidget {
  const BorrowHistoryPage({super.key});

  @override
  ConsumerState<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends ConsumerState<BorrowHistoryPage> {
  final dateFormat = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final borrowsAsync = ref.watch(userBorrowHistoryProvider);
    final selectedFilter = ref.watch(borrowFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Peminjaman'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: borrowsAsync.when(
              data: (borrows) {
                if (borrows.isEmpty) {
                  return const Center(
                    child: Text('Belum ada riwayat peminjaman'),
                  );
                }

                // Filter borrows if filter is selected
                final filteredBorrows = selectedFilter != null
                    ? borrows.where((b) => b.status == selectedFilter).toList()
                    : borrows;

                if (filteredBorrows.isEmpty) {
                  return Center(
                    child: Text(
                      'Tidak ada peminjaman dengan status ${selectedFilter?.name ?? ""}',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBorrows.length,
                  itemBuilder: (context, index) {
                    return _buildBorrowItem(filteredBorrows[index]);
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          // All filter
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text('Semua'),
              selected: ref.watch(borrowFilterProvider) == null,
              onSelected: (selected) {
                if (selected) {
                  ref.read(borrowFilterProvider.notifier).state = null;
                }
              },
            ),
          ),

          // Status filters
          ...BorrowStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(status.name),
                selected: ref.watch(borrowFilterProvider) == status,
                labelStyle: TextStyle(
                  color: ref.watch(borrowFilterProvider) == status
                      ? Colors.white
                      : null,
                ),
                backgroundColor: status.color.withOpacity(0.1),
                selectedColor: status.color,
                onSelected: (selected) {
                  ref.read(borrowFilterProvider.notifier).state =
                      selected ? status : null;
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBorrowItem(BorrowModel borrow) {
    final bool isOverdue = borrow.status == BorrowStatus.overdue;
    final bool isPending = borrow.status == BorrowStatus.pending;
    final bool hasReturned = borrow.returnDate != null;
    final bool isPendingReturn = borrow.status == BorrowStatus.pendingReturn;

// Tambahkan metode baru untuk cek apakah tanggal sudah lewat
    bool _isDatePassed(DateTime dateTime) {
      final DateTime now = DateTime.now();
      final DateTime normalizedDate =
          DateTime(dateTime.year, dateTime.month, dateTime.day);
      final DateTime normalizedNow = DateTime(now.year, now.month, now.day);
      return normalizedNow.isAfter(normalizedDate);
    }

    // Cek jika terlambat (jatuh tempo sudah lewat dari hari ini)
    final bool isLate =
        !hasReturned && !isPending && _isDatePassed(borrow.dueDate) ||
            borrow.status == BorrowStatus.overdue;
    ;

    // Cek jika perlu pembayaran:
    // 1. Ada denda (fine != null && fine > 0) ATAU
    // 2. Buku belum dikembalikan dan sudah lewat jatuh tempo
    final bool needsPayment = (!borrow.isPaid && isLate) ||
        (borrow.fine != null && borrow.fine! > 0 && !borrow.isPaid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BorrowDetailPage(borrowId: borrow.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Container(
              color: borrow.status.color,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Text(
                borrow.status.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Book info - TAMBAHKAN INI
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book cover
                  if (borrow.bookCover != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        borrow.bookCover!,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, color: Colors.grey),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, color: Colors.grey),
                    ),

                  const SizedBox(width: 16),

                  // Book details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          borrow.bookTitle ?? 'Unknown Book',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (borrow.booksAuthor != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              borrow.booksAuthor!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Dates
                        Row(
                          children: [
                            const Icon(Icons.date_range, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Tanggal pinjam: ${dateFormat.format(borrow.borrowDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 14,
                              color: borrow.dueDate.isBefore(DateTime.now()) &&
                                      !hasReturned
                                  ? Colors.red
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Jatuh tempo: ${dateFormat.format(borrow.dueDate)}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    borrow.dueDate.isBefore(DateTime.now()) &&
                                            !hasReturned
                                        ? Colors.red
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        if (isLate)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'TERLAMBAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Status pembayaran
                        if (borrow.fine != null && borrow.fine! > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: borrow.isPaid
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: borrow.isPaid
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  borrow.isPaid
                                      ? Icons.check_circle
                                      : Icons.account_balance_wallet,
                                  size: 14,
                                  color: borrow.isPaid
                                      ? Colors.green
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    borrow.isPaid
                                        ? 'Denda Rp ${borrow.fine!.toStringAsFixed(0)} sudah dibayar'
                                        : 'Denda Rp ${borrow.fine!.toStringAsFixed(0)} belum dibayar',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: borrow.isPaid
                                          ? Colors.green
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPendingReturn)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.autorenew, color: Colors.teal),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Permintaan Pengembalian',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Menunggu konfirmasi pengembalian dari pustakawan.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Tombol kembalikan hanya muncul jika:
                  // 1. Belum dikembalikan
                  // 2. Status bukan pending
                  if (borrow.status == BorrowStatus.active ||
                      borrow.status ==
                          BorrowStatus.overdue) // Hanya aktif atau terlambat
                    ElevatedButton(
                      onPressed: () {
                        _showReturnConfirmation(borrow.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text('KEMBALIKAN BUKU'),
                    ),
// Untuk peminjaman yang ditolak
                  if (borrow.status == BorrowStatus.rejected &&
                      borrow.rejectReason != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel_outlined,
                                    color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Peminjaman Ditolak',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alasan: ${borrow.rejectReason}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            if (borrow.rejectDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Tanggal: ${dateFormat.format(borrow.rejectDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  //  tampilan feedback untuk penolakan pengembalian
                  if (borrow.returnRejectReason != null &&
                      borrow.returnRejectReason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pengembalian Ditolak',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alasan: ${borrow.returnRejectReason}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            if (borrow.rejectDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Tanggal: ${dateFormat.format(borrow.rejectDate!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Tombol bayar denda muncul jika:
                  // 1. Ada denda
                  // 2. Belum dibayar
                  if (needsPayment)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          // Tentukan jumlah denda: jika sudah ada nilai denda, gunakan itu
                          // Jika belum ada nilai denda (keterlambatan baru), gunakan perhitungan default
                          final double fineAmount =
                              borrow.fine ?? _calculateDefaultFine(borrow);

                          // _showPaymentDialog(borrow.id, borrow.fine!);
                          // Riderect to payment page

                          context.push(
                            '/payment/${borrow.id}?amount=${fineAmount.toStringAsFixed(0)}',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('BAYAR DENDA'),
                      ),
                    ),

                  // Peringatan keterlambatan
                  if (isLate && !hasReturned && !isPending && !isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Sudah ${_getDaysLate(borrow.dueDate)} hari dipinjam, harap segera dikembalikan untuk menghindari denda.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  // Info jika status pending
                  if (isPending)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Permintaan peminjaman sedang menunggu konfirmasi pustakawan.',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tambahkan method untuk menampilkan dialog pembayaran denda
  void _showPaymentDialog(String borrowId, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bayar Denda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah denda: Rp ${amount.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            const Text('Pilih metode pembayaran:'),
            const SizedBox(height: 8),
            _buildPaymentMethodButton(
              icon: Icons.account_balance_wallet,
              title: 'E-Wallet',
              onTap: () => _processPayment(borrowId, 'e-wallet'),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodButton(
              icon: Icons.credit_card,
              title: 'Kartu Kredit/Debit',
              onTap: () => _processPayment(borrowId, 'card'),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodButton(
              icon: Icons.person,
              title: 'Bayar di Perpustakaan',
              onTap: () => _processPayment(borrowId, 'onsite'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATALKAN'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Tambahkan helper method untuk menghitung jumlah denda default
  double _calculateDefaultFine(BorrowModel borrow) {
    // Hitung hari keterlambatan
    final int daysLate = _getDaysLate(borrow.dueDate);

    // Misalnya, denda Rp 2.000 per hari keterlambatan
    const double finePerDay = 2000;
    return daysLate * finePerDay;
  }

// Helper method untuk menghitung hari keterlambatan
  int _getDaysLate(DateTime dueDate) {
    final DateTime now = DateTime.now();

    // Normalisasi kedua waktu ke tengah malam untuk perhitungan hari yang lebih akurat
    final DateTime normalizedDueDate =
        DateTime(dueDate.year, dueDate.month, dueDate.day);
    final DateTime normalizedNow = DateTime(now.year, now.month, now.day);

    // Hitung perbedaan hari
    final int daysDifference =
        normalizedNow.difference(normalizedDueDate).inDays;

    // Pastikan hasilnya minimal 1 jika sudah melewati jatuh tempo
    return daysDifference > 0 ? daysDifference : 1;
  }

  Future<void> _processPayment(String borrowId, String method) async {
    Navigator.pop(context); // Close payment dialog

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingIndicator(),
            SizedBox(height: 16),
            Text('Memproses pembayaran...'),
          ],
        ),
      ),
    );

    try {
      // Process payment
      final success = await ref
          .read(borrowControllerProvider.notifier)
          .payFine(borrowId, method);

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil diproses'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memproses pembayaran'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReturnConfirmation(String borrowId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kembalikan Buku'),
        content: const Text('Apakah Anda yakin ingin mengembalikan buku ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATALKAN'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await ref
                  .read(borrowControllerProvider.notifier)
                  .returnBook(borrowId);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buku berhasil dikembalikan'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('YA, KEMBALIKAN'),
          ),
        ],
      ),
    );
  }
}