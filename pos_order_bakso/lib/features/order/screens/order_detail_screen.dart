import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/main.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';

import 'package:screenshot/screenshot.dart';
import 'package:file_saver/file_saver.dart';

@RoutePage()
class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingInvoice = false;

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM リ, HH:mm', 'id_ID').format(dateTime);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Widget _buildStatusChip(BuildContext context, String statusText) {
    Color chipBackgroundColor;
    Color chipTextColor;
    IconData? chipIcon;
    String lowerStatus = statusText.toLowerCase();

    if (lowerStatus == OrderStatus.completed.toMap().toLowerCase() ||
        lowerStatus == PaymentStatus.paid.toMap().toLowerCase() ||
        lowerStatus == OrderStatus.confirmed.toMap().toLowerCase() ||
        lowerStatus == OrderStatus.ready.toMap().toLowerCase()) {
      chipBackgroundColor = context.colors.primary.withOpacity(0.15);
      chipTextColor = context.colors.primary;
      chipIcon = Icons.check_circle;
      if (lowerStatus == OrderStatus.ready.toMap().toLowerCase()) {
        chipIcon = Icons.restaurant_menu;
      }
    } else if (lowerStatus == OrderStatus.pending.toMap().toLowerCase() ||
        lowerStatus == OrderStatus.preparing.toMap().toLowerCase() ||
        lowerStatus == PaymentStatus.unpaid.toMap().toLowerCase()) {
      chipBackgroundColor = Colors.orange.withOpacity(0.15);
      chipTextColor = Colors.orange.shade700;
      chipIcon = Icons.hourglass_empty;
      if (lowerStatus == OrderStatus.preparing.toMap().toLowerCase()) {
        chipIcon = Icons.soup_kitchen_outlined;
      }
    } else if (lowerStatus == OrderStatus.cancelled.toMap().toLowerCase()) {
      chipBackgroundColor = context.colors.error.withOpacity(0.15);
      chipTextColor = context.colors.error;
      chipIcon = Icons.cancel;
    } else {
      chipBackgroundColor = context.colors.secondary.withOpacity(0.15);
      chipTextColor = context.colors.secondary;
      chipIcon = Icons.info_outline;
    }

    return Chip(
      avatar:
          chipIcon != null
              ? Icon(chipIcon, color: chipTextColor, size: 16)
              : null,
      label: Text(
        statusText,
        style: context.textStyles.labelMedium?.copyWith(
          color: chipTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: chipBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: context.colors.secondary.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const SizedBox(width: 28),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textStyles.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWidget(
    BuildContext context,
    String label,
    Widget valueWidget, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: context.colors.secondary.withOpacity(0.8),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const SizedBox(width: 28),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.textStyles.bodySmall?.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Align(alignment: Alignment.centerLeft, child: valueWidget),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndSaveInvoice() async {
    if (_isSavingInvoice) return;

    setState(() {
      _isSavingInvoice = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Menyiapkan invoice...',
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        backgroundColor: context.colors.surface.withOpacity(0.8),
        duration: const Duration(
          seconds: 1,
        ), // Kurangi durasi untuk notif singkat
      ),
    );

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 150), // Sedikit delay
        pixelRatio:
            MediaQuery.of(context).devicePixelRatio *
            1.5, // Kualitas cukup baik
      );

      if (imageBytes == null) {
        throw Exception('Gagal mengambil gambar invoice.');
      }

      final String fileName =
          'Invoice_Order_${widget.order.id.length > 6 ? widget.order.id.substring(0, 6) : widget.order.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

      // Menggunakan file_saver
      // Ini akan membuka dialog "Save As" dari sistem operasi
      String? filePath = await FileSaver.instance.saveFile(
        name: fileName, // Nama file (tanpa ekstensi)
        bytes: imageBytes,
        ext: 'png', // Ekstensi file
        mimeType: MimeType.png, // Tipe MIME
      );

      if (filePath != null && filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invoice disimpan: $filePath',
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onPrimary,
              ),
            ),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5), // Tampilkan path lebih lama
          ),
        );
      } else {
        // Pengguna mungkin membatalkan dialog penyimpanan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Penyimpanan dibatalkan oleh pengguna.',
              style: context.textStyles.labelMedium,
            ),
            backgroundColor: context.colors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error menyimpan: ${e.toString()}',
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onError,
            ),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      logger.e("Error capturing or saving invoice: ${e.toString()}");
    } finally {
      setState(() {
        _isSavingInvoice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget invoiceContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: context.cardTheme.color,
          elevation: 0,
          shape: context.cardTheme.shape,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Umum',
                  style: context.textStyles.titleMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  color: context.theme.dividerTheme.color?.withOpacity(0.5),
                  height: 20,
                ),
                _buildDetailRow(
                  context,
                  'ID Pesanan:',
                  widget.order.id,
                  icon: Icons.vpn_key_outlined,
                ),
                _buildDetailRow(
                  context,
                  'ID Pengguna:',
                  widget.order.userId,
                  icon: Icons.person_outline,
                ),
                _buildDetailRow(
                  context,
                  'Tanggal Pesan:',
                  _formatDateTime(widget.order.orderDate),
                  icon: Icons.calendar_today_outlined,
                ),
                _buildDetailRowWidget(
                  context,
                  'Jenis Pesanan:',
                  _buildStatusChip(context, widget.order.orderType.toMap()),
                  icon: Icons.shopping_bag_outlined,
                ),
                _buildDetailRowWidget(
                  context,
                  'Status Pesanan:',
                  _buildStatusChip(context, widget.order.status.toMap()),
                  icon: Icons.flag_outlined,
                ),
                _buildDetailRow(
                  context,
                  'Total Bayar:',
                  _formatCurrency(widget.order.totalAmount),
                  icon: Icons.monetization_on_outlined,
                ),
                _buildDetailRowWidget(
                  context,
                  'Status Pembayaran:',
                  _buildStatusChip(context, widget.order.paymentStatus.toMap()),
                  icon: Icons.payment_outlined,
                ),
                if (widget.order.paymentMethodId != null)
                  _buildDetailRow(
                    context,
                    'ID Metode Bayar:',
                    widget.order.paymentMethodId!,
                    icon: Icons.credit_card_outlined,
                  ),
                if (widget.order.estimatedReadyTime != null)
                  _buildDetailRow(
                    context,
                    'Estimasi Siap:',
                    _formatDateTime(widget.order.estimatedReadyTime),
                    icon: Icons.timer_outlined,
                  ),
                if (widget.order.specialInstructions != null &&
                    widget.order.specialInstructions!.isNotEmpty)
                  _buildDetailRow(
                    context,
                    'Instruksi Khusus:',
                    widget.order.specialInstructions!,
                    icon: Icons.speaker_notes_outlined,
                  ),
                _buildDetailRow(
                  context,
                  'Dibuat Pada:',
                  _formatDateTime(widget.order.createdAt),
                  icon: Icons.add_circle_outline,
                ),
                _buildDetailRow(
                  context,
                  'Diperbarui Pada:',
                  _formatDateTime(widget.order.updatedAt),
                  icon: Icons.edit_calendar_outlined,
                ),
              ],
            ),
          ),
        ),
        if (widget.order.orderItems != null &&
            widget.order.orderItems!.isNotEmpty)
          Card(
            color: context.cardTheme.color,
            elevation: 0,
            shape: context.cardTheme.shape,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Pesanan (${widget.order.orderItems!.length})',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.order.orderItems!.length,
                    itemBuilder: (ctx, index) {
                      final item = widget.order.orderItems![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                item.menuItem?.imageUrl != null &&
                                        Uri.tryParse(
                                              item.menuItem!.imageUrl!,
                                            )?.hasAbsolutePath ==
                                            true
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        item.menuItem!.imageUrl!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.fastfood_outlined,
                                                  size: 50,
                                                  color: context
                                                      .colors
                                                      .secondary
                                                      .withOpacity(0.5),
                                                ),
                                      ),
                                    )
                                    : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: context.colors.secondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.fastfood_outlined,
                                        size: 30,
                                        color: context.colors.secondary
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.menuItem?.name ??
                                            "Nama Menu Tidak Ada",
                                        style: context.textStyles.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.quantity} x ${_formatCurrency(item.price)}',
                                        style: context.textStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatCurrency(item.total),
                                  style: context.textStyles.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (item.specialRequests != null &&
                                item.specialRequests!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 6.0,
                                  left: 62,
                                ),
                                child: Text(
                                  "Catatan: ${item.specialRequests}",
                                  style: context.textStyles.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: context.colors.secondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder:
                        (ctx, index) => Divider(
                          color: context.theme.dividerTheme.color?.withOpacity(
                            0.5,
                          ),
                          height: 16,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const UserAppBar(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80, left: 4, right: 4, top: 8),
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
              color:
                  context
                      .theme
                      .scaffoldBackgroundColor, // Background untuk screenshot
              padding: const EdgeInsets.all(
                8.0,
              ), // Sedikit padding di sekitar konten screenshot
              child: invoiceContent,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSavingInvoice ? null : _captureAndSaveInvoice,
        label:
            _isSavingInvoice
                ? Text(
                  'Menyimpan...',
                  style: TextStyle(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : Text(
                  'Simpan Invoice',
                  style: TextStyle(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        icon:
            _isSavingInvoice
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: context.colors.onPrimary,
                  ),
                )
                : Icon(
                  Icons.save_alt_outlined,
                  color: context.colors.onPrimary,
                ), // Ikon save
        backgroundColor: context.colors.primary,
        elevation: 4.0,
      ),
    );
  }
}
