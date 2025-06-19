import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/currency_utils.dart';
import 'package:jamal/core/utils/date_convention.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/features/order/providers/orders_provider.dart';
import 'package:jamal/features/payment_method/providers/payment_method_provider.dart';
import 'package:jamal/main.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:screenshot/screenshot.dart';
import 'package:file_saver/file_saver.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with WidgetsBindingObserver {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingInvoice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      AppLogger().i("Aplikasi kembali aktif, me-refresh data order...");

      ref.read(ordersProvider.notifier).refreshOrders();

      ToastUtils.showInfo(
        context: context,
        message: 'Memperbarui status pesanan...',
      );
    }
  }

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

  Widget _buildPaymentDetailsSection() {
    final order = widget.order;
    // Tampilkan section ini jika ada paymentMethodId
    if (order.paymentMethodId == null) {
      return const SizedBox.shrink();
    }

    final paymentMethodState = ref.watch(
      paymentMethodProvider(order.paymentMethodId!),
    );

    if (paymentMethodState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (paymentMethodState.errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Gagal memuat metode pembayaran: ${paymentMethodState.errorMessage}',
          ),
        ),
      );
    }

    if (paymentMethodState.paymentMethod == null) {
      // Mungkin payment method tidak ditemukan, tapi kita bisa tampilkan info dasar
      return Card(
        color: context.cardTheme.color,
        elevation: 0,
        shape: context.cardTheme.shape,
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Detail pembayaran untuk metode ${order.paymentMethodId} tidak ditemukan.',
          ),
        ),
      );
    }

    return _buildPaymentGatewaySection(
      order,
      paymentMethodState.paymentMethod!,
    );
  }

  /// WIDGET YANG DIPERBAIKI
  Widget _buildPaymentGatewaySection(
    OrderModel order,
    PaymentMethodModel paymentMethod,
  ) {
    final bool hasPaymentCode =
        order.paymentCode != null && order.paymentCode!.isNotEmpty;
    final bool hasPaymentDisplayURL =
        order.paymentDisplayUrl != null && order.paymentDisplayUrl!.isNotEmpty;
    final bool shouldShowButtons = order.paymentStatus == PaymentStatus.pending;

    String? simulatorURL;
    if (paymentMethod.midtransIdentifier != null) {
      simulatorURL = _getSimulatorUrl(paymentMethod.midtransIdentifier!);
    }

    // Jangan tampilkan card sama sekali jika tidak ada info apa pun untuk ditampilkan
    if (!hasPaymentCode && !hasPaymentDisplayURL && simulatorURL == null) {
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
              'Instruksi Pembayaran',
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(
              color: context.theme.dividerTheme.color?.withValues(alpha: 0.5),
              height: 20,
            ),
            _buildDetailRow(
              context,
              'Metode',
              paymentMethod.name,
              icon: Icons.credit_card,
            ),

            if (hasPaymentCode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.pin_outlined,
                      size: 18,
                      color: context.colors.secondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Kode Bayar',
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textStyles.bodySmall?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                order.paymentCode!,
                                style: context.textStyles.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: order.paymentCode!),
                                );
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
                    ),
                  ],
                ),
              ),

            if (order.paymentExpiry != null)
              _buildDetailRow(
                context,
                'Batas Bayar',
                DateConvention.formatToIndoConv(order.paymentExpiry!),
                icon: Icons.timer_off_outlined,
              ),

            const SizedBox(height: 16),

            if (shouldShowButtons)
              Column(
                children: [
                  if (hasPaymentDisplayURL)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payment),
                        label: const Text('Lanjutkan Pembayaran'),
                        onPressed: () => _launchUrl(order.paymentDisplayUrl!),
                      ),
                    ),
                  if (simulatorURL != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Buka Simulator Pembayaran'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.secondary,
                          foregroundColor: context.colors.onSecondary,
                        ),
                        onPressed: () => _launchUrl(simulatorURL!),
                      ),
                    ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: context.colors.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.paymentStatus == PaymentStatus.success
                            ? 'Pembayaran telah berhasil'
                            : 'Pembayaran tidak tersedia untuk status ini',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.secondary,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ToastUtils.showError(
        context: context,
        message: 'Tidak dapat membuka link: $url',
      );
    }
  }

  String? _getSimulatorUrl(String identifier) {
    switch (identifier.toLowerCase()) {
      case 'bca':
        return 'https://simulator.sandbox.midtrans.com/bca/va/index';
      case 'bri':
        return 'https://simulator.sandbox.midtrans.com/openapi/va/index?bank=bri';
      case 'bni':
        return 'https://simulator.sandbox.midtrans.com/bni/va/index';
      case 'mandiri':
        return 'https://simulator.sandbox.midtrans.com/openapi/va/index?bank=mandiri';
      case 'bsi':
        return 'https://simulator.sandbox.midtrans.com/openapi/va/index?bank=bsi';
      case 'qris':
        return 'https://simulator.sandbox.midtrans.com/v2/qris/index';
      case 'gopay':
        return 'https://simulator.sandbox.midtrans.com/v2/deeplink/index';
      default:
        return null;
    }
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

      if (filePath != null && filePath.isNotEmpty) {
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
      if (mounted) {
        setState(() {
          _isSavingInvoice = false;
        });
      }
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
                      widget.order.estimatedReadyTime!,
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
