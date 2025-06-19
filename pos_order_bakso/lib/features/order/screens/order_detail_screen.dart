import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/currency_utils.dart';
import 'package:jamal/core/utils/date_convention.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/features/payment_method/providers/payment_method_provider.dart';
import 'package:jamal/main.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';

import 'package:screenshot/screenshot.dart';
import 'package:file_saver/file_saver.dart';

@RoutePage()
class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingInvoice = false;

  Widget _buildStatusChip(BuildContext context, String statusText) {
    Color chipBackgroundColor;
    Color chipTextColor;
    IconData? chipIcon;
    String lowerStatus = statusText.toLowerCase();

    if (lowerStatus == OrderStatus.completed.toMap().toLowerCase() ||
        lowerStatus == PaymentStatus.success.toMap().toLowerCase() ||
        lowerStatus == OrderStatus.confirmed.toMap().toLowerCase() ||
        lowerStatus == OrderStatus.ready.toMap().toLowerCase()) {
      chipBackgroundColor = context.colors.primary.withValues(alpha: 0.15);
      chipTextColor = context.colors.primary;
      chipIcon = Icons.check_circle;
      if (lowerStatus == OrderStatus.ready.toMap().toLowerCase()) {
        chipIcon = Icons.restaurant_menu;
      }
    } else if (lowerStatus == OrderStatus.pending.toMap().toLowerCase() ||
        lowerStatus == OrderStatus.preparing.toMap().toLowerCase() ||
        lowerStatus == PaymentStatus.pending.toMap().toLowerCase()) {
      chipBackgroundColor = Colors.orange.withValues(alpha: 0.15);
      chipTextColor = Colors.orange.shade700;
      chipIcon = Icons.hourglass_empty;
      if (lowerStatus == OrderStatus.preparing.toMap().toLowerCase()) {
        chipIcon = Icons.soup_kitchen_outlined;
      }
    } else if (lowerStatus == OrderStatus.cancelled.toMap().toLowerCase()) {
      chipBackgroundColor = context.colors.error.withValues(alpha: 0.15);
      chipTextColor = context.colors.error;
      chipIcon = Icons.cancel;
    } else {
      chipBackgroundColor = context.colors.secondary.withValues(alpha: 0.15);
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
              color: context.colors.secondary.withValues(alpha: 0.8),
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
              color: context.colors.secondary.withValues(alpha: 0.8),
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

  // WIDGET BARU: Section khusus untuk detail pembayaran
  Widget _buildPaymentDetailsSection() {
    final paymentMethodId = widget.order.paymentMethodId;
    if (paymentMethodId == null) {
      return const SizedBox.shrink();
    }

    final paymentMethodState = ref.watch(
      paymentMethodProvider(paymentMethodId),
    );
    final paymentMethod = paymentMethodState.paymentMethod;

    // Hanya tampilkan section ini jika ada kode atau QR yang perlu ditampilkan
    bool hasPaymentDetails =
        (paymentMethod?.adminPaymentCode != null &&
            paymentMethod!.adminPaymentCode!.isNotEmpty) ||
        (paymentMethod?.adminPaymentQrCodePicture != null &&
            paymentMethod!.adminPaymentQrCodePicture!.isNotEmpty);

    if (paymentMethodState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (paymentMethod == null || !hasPaymentDetails) {
      return const SizedBox.shrink();
    }

    return Card(
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
              'Detail Pembayaran',
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(
              color: context.theme.dividerTheme.color?.withValues(alpha: 0.5),
              height: 20,
            ),

            // Nama Metode Pembayaran
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Text("Metode:", style: context.textStyles.bodyMedium),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      paymentMethod.name,
                      style: context.textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Konten dinamis (QR atau Kode)
            if (paymentMethod.adminPaymentQrCodePicture != null &&
                paymentMethod.adminPaymentQrCodePicture!.isNotEmpty)
              _buildQrCodeContent(paymentMethod.adminPaymentQrCodePicture!)
            else if (paymentMethod.adminPaymentCode != null &&
                paymentMethod.adminPaymentCode!.isNotEmpty)
              _buildPaymentCodeContent(paymentMethod.adminPaymentCode!),
          ],
        ),
      ),
    );
  }

  // Helper untuk konten QR Code
  Widget _buildQrCodeContent(String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Bayar:', style: context.textStyles.bodyMedium),
        const SizedBox(height: 4),
        Text(
          'Scan QR Code di bawah menggunakan aplikasi pembayaran Anda.',
          style: context.textStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      contentPadding: const EdgeInsets.all(8),
                      content: Image.network(imageUrl),
                    ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 150,
                    height: 150,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder:
                    (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 150),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper untuk konten Kode Pembayaran
  Widget _buildPaymentCodeContent(String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cara Bayar:', style: context.textStyles.bodyMedium),
        const SizedBox(height: 4),
        Text(
          'Salin kode di bawah dan lakukan pembayaran melalui channel yang sesuai.',
          style: context.textStyles.bodySmall,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  code,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ToastUtils.showInfo(
                    context: context,
                    message: 'Kode pembayaran disalin!',
                  );
                },
                tooltip: 'Salin Kode',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _captureAndSaveInvoice() async {
    if (_isSavingInvoice) return;

    setState(() {
      _isSavingInvoice = true;
    });

    ToastUtils.showInfo(context: context, message: 'Menyiapkan invoice...');

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 150),
        pixelRatio: MediaQuery.of(context).devicePixelRatio * 1.5,
      );

      if (imageBytes == null) {
        throw Exception('Gagal mengambil gambar invoice.');
      }

      final String fileName =
          'Invoice_Order_${widget.order.id.length > 6 ? widget.order.id.substring(0, 6) : widget.order.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

      String? filePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: imageBytes,
        ext: 'png',
        mimeType: MimeType.png,
      );

      if (filePath.isNotEmpty) {
        if (!context.mounted) return;
        ToastUtils.showSuccess(
          context: context,
          message: 'Invoice disimpan: $filePath',
        );
      } else {
        if (!context.mounted) return;
        ToastUtils.showWarning(
          context: context,
          message: 'Penyimpanan dibatalkan oleh pengguna.',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ToastUtils.showError(
        context: context,
        message: 'Error menyimpan: ${e.toString()}',
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
                  color: context.theme.dividerTheme.color?.withValues(
                    alpha: 0.5,
                  ),
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
                  DateConvention.formatToIndoConv(widget.order.orderDate),
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
                  CurrencyUtils.formatToRupiah(widget.order.totalAmount),
                  icon: Icons.monetization_on_outlined,
                ),
                _buildDetailRowWidget(
                  context,
                  'Status Pembayaran:',
                  _buildStatusChip(context, widget.order.paymentStatus.toMap()),
                  icon: Icons.payment_outlined,
                ),
                if (widget.order.estimatedReadyTime != null)
                  _buildDetailRow(
                    context,
                    'Estimasi Siap:',
                    DateConvention.formatToIndoConv(
                      widget.order.estimatedReadyTime,
                    ),
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
                  DateConvention.formatToIndoConv(widget.order.createdAt),
                  icon: Icons.add_circle_outline,
                ),
                _buildDetailRow(
                  context,
                  'Diperbarui Pada:',
                  DateConvention.formatToIndoConv(widget.order.updatedAt),
                  icon: Icons.edit_calendar_outlined,
                ),
              ],
            ),
          ),
        ),
        _buildPaymentDetailsSection(),

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
                                                      .withValues(alpha: 0.5),
                                                ),
                                      ),
                                    )
                                    : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: context.colors.secondary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.fastfood_outlined,
                                        size: 30,
                                        color: context.colors.secondary
                                            .withValues(alpha: 0.7),
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
                                        '${item.quantity} x ${CurrencyUtils.formatToRupiah(item.price)}',
                                        style: context.textStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyUtils.formatToRupiah(item.total),
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
                          color: context.theme.dividerTheme.color?.withValues(
                            alpha: 0.5,
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
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80, left: 4, right: 4, top: 8),
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
              color: context.theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8.0),
              child: invoiceContent,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        // ... (BottomNavigationBar tidak diubah)
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color:
              context.theme.bottomAppBarTheme.color ??
              context.theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              return Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSavingInvoice ? null : _captureAndSaveInvoice,
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
                                'Simpan Bukti',
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
                              ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
