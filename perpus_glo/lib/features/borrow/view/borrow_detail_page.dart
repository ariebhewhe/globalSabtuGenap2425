import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../model/borrow_model.dart';
import '../providers/borrow_provider.dart';
import '../../payment/view/payment_page.dart';

class BorrowDetailPage extends ConsumerWidget {
  final String borrowId;
  final dateFormat = DateFormat('dd MMMM yyyy');
  
  BorrowDetailPage({super.key, required this.borrowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borrowAsync = ref.watch(borrowByIdProvider(borrowId));
    final controller = ref.watch(borrowControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Peminjaman'),
      ),
      body: borrowAsync.when(
        data: (borrow) {
          if (borrow == null) {
            return const Center(
              child: Text('Data peminjaman tidak ditemukan'),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Card(
                  color: borrow.status.color.withOpacity(0.1),
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(borrow.status),
                          color: borrow.status.color,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: borrow.status.color,
                                ),
                              ),
                              Text(
                                borrow.status.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: borrow.status.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (borrow.fine != null && borrow.fine! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: borrow.isPaid ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              borrow.isPaid ? 'LUNAS' : 'BELUM BAYAR',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Book info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: borrow.bookCover != null
                          ? Image.network(
                              borrow.bookCover!,
                              width: 100,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.book, size: 40),
                                );
                              },
                            )
                          : Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.book, size: 40),
                            ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Book details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            borrow.bookTitle ?? 'Judul tidak tersedia',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID Buku: ${borrow.bookId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.calendar_today, 'Dipinjam', dateFormat.format(borrow.borrowDate)),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.event,
                            'Tenggat',
                            dateFormat.format(borrow.dueDate),
                            textColor: borrow.isOverdue() ? Colors.red : null,
                          ),
                          if (borrow.returnDate != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.check_circle,
                              'Dikembalikan',
                              dateFormat.format(borrow.returnDate!),
                              textColor: borrow.isOverdue() ? Colors.orange : Colors.green,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Fine details if any
                if (borrow.fine != null && borrow.fine! > 0) ...[
                  const Text(
                    'Informasi Denda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jumlah Denda'),
                            Text(
                              'Rp ${borrow.fine!.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status Pembayaran'),
                            Text(
                              borrow.isPaid ? 'LUNAS' : 'BELUM DIBAYAR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: borrow.isPaid ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (!borrow.isPaid) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Denda harus dibayar untuk dapat meminjam buku lainnya.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // Action buttons
                if (controller.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error: ${controller.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                if (!borrow.isPaid && borrow.fine != null && borrow.fine! > 0)
                  ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentPage(
                                  fineId: borrowId,
                                  amount: borrow.fine!,
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: controller.isLoading
                        ? const LoadingIndicator(color: Colors.white)
                        : const Text('BAYAR DENDA'),
                  ),
                
                if (borrow.status == BorrowStatus.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Kembalikan Buku'),
                                  content: const Text('Apakah Anda yakin ingin mengembalikan buku ini?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('BATALKAN'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('YA, KEMBALIKAN'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirmed == true) {
                                await ref.read(borrowControllerProvider.notifier)
                                    .returnBook(borrowId);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: controller.isLoading
                          ? const LoadingIndicator(color: Colors.white)
                          : const Text('KEMBALIKAN BUKU'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor, Color? textColor}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  IconData _getStatusIcon(BorrowStatus status) {
  switch (status) {
    case BorrowStatus.pending:
      return Icons.hourglass_empty;
    case BorrowStatus.active:
      return Icons.bookmark;
    case BorrowStatus.returned:
      return Icons.check_circle;
    case BorrowStatus.overdue:
      return Icons.warning;
    case BorrowStatus.rejected:
      return Icons.cancel;
    case BorrowStatus.rejectedReturn:
      return Icons.cancel_outlined;
    case BorrowStatus.lost:
      return Icons.report_problem;
    case BorrowStatus.pendingReturn:
      return Icons.pending_actions;
  }
}
}