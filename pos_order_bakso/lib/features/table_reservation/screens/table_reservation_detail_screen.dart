import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/main.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:screenshot/screenshot.dart';
import 'package:file_saver/file_saver.dart';

@RoutePage()
class TableReservationDetailScreen extends StatefulWidget {
  final TableReservationModel reservation;

  const TableReservationDetailScreen({Key? key, required this.reservation})
    : super(key: key);

  @override
  State<TableReservationDetailScreen> createState() =>
      _TableReservationDetailScreenState();
}

class _TableReservationDetailScreenState
    extends State<TableReservationDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSavingInvoice = false;

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  Widget _buildStatusChip(
    BuildContext context,
    String statusText, {
    bool isTableAvailability = false,
  }) {
    Color chipBackgroundColor;
    Color chipTextColor;
    IconData? chipIcon;

    String lowerStatus = statusText.toLowerCase();

    if (isTableAvailability) {
      if (lowerStatus == 'tersedia') {
        chipBackgroundColor = context.colors.primary.withValues(alpha: 0.15);
        chipTextColor = context.colors.primary;
        chipIcon = Icons.check_circle_outline;
      } else {
        chipBackgroundColor = context.colors.error.withValues(alpha: 0.15);
        chipTextColor = context.colors.error;
        chipIcon = Icons.cancel_outlined;
      }
    } else {
      if (lowerStatus == ReservationStatus.completed.toMap().toLowerCase() ||
          lowerStatus == ReservationStatus.occupied.toMap().toLowerCase() ||
          lowerStatus == ReservationStatus.reserved.toMap().toLowerCase()) {
        chipBackgroundColor = context.colors.primary.withValues(alpha: 0.15);
        chipTextColor = context.colors.primary;
        chipIcon = Icons.event_available;
        if (lowerStatus == ReservationStatus.occupied.toMap().toLowerCase()) {
          chipIcon = Icons.person_pin_circle_outlined;
        }
      } else if (lowerStatus ==
          ReservationStatus.cancelled.toMap().toLowerCase()) {
        chipBackgroundColor = context.colors.error.withValues(alpha: 0.15);
        chipTextColor = context.colors.error;
        chipIcon = Icons.event_busy;
      } else {
        chipBackgroundColor = Colors.orange.withValues(alpha: 0.15);
        chipTextColor = Colors.orange.shade700;
        chipIcon = Icons.hourglass_empty;
      }
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

  Future<void> _captureAndSaveReservationProof() async {
    if (_isSavingInvoice) return;

    setState(() {
      _isSavingInvoice = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Menyiapkan bukti reservasi...',
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        backgroundColor: context.colors.surface.withValues(alpha: 0.8),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 150),
        pixelRatio: MediaQuery.of(context).devicePixelRatio * 1.5,
      );

      if (imageBytes == null) {
        throw Exception('Gagal mengambil gambar bukti reservasi.');
      }

      final String fileName =
          'Bukti_Reservasi_${widget.reservation.id.length > 6 ? widget.reservation.id.substring(0, 6) : widget.reservation.id}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

      String? filePath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: imageBytes,
        ext: 'png',
        mimeType: MimeType.png,
      );

      if (filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bukti reservasi disimpan: $filePath',
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onPrimary,
              ),
            ),
            backgroundColor: context.colors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Penyimpanan dibatalkan oleh pengguna.',
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSecondary,
              ),
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
      logger.e("Error capturing or saving reservation proof: ${e.toString()}");
    } finally {
      setState(() {
        _isSavingInvoice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget reservationContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: context.cardTheme.color ?? context.colors.surface,
          elevation: context.cardTheme.elevation ?? 1.0,
          shape:
              context.cardTheme.shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Reservasi',
                  style: context.textStyles.titleMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  color:
                      context.theme.dividerTheme.color?.withValues(
                        alpha: 0.5,
                      ) ??
                      context.colors.outline.withValues(alpha: 0.5),
                  height: 20,
                ),
                _buildDetailRow(
                  context,
                  'ID Reservasi:',
                  widget.reservation.id,
                  icon: Icons.vpn_key_outlined,
                ),
                _buildDetailRow(
                  context,
                  'ID Pengguna:',
                  widget.reservation.userId,
                  icon: Icons.person_outline,
                ),

                if (widget.reservation.orderId.isNotEmpty)
                  _buildDetailRow(
                    context,
                    'ID Pesanan Terkait:',
                    widget.reservation.orderId,
                    icon: Icons.receipt_long_outlined,
                  ),
                _buildDetailRow(
                  context,
                  'Waktu Reservasi:',
                  _formatDateTime(widget.reservation.reservationTime),
                  icon: Icons.calendar_today_outlined,
                ),
                _buildDetailRowWidget(
                  context,
                  'Status:',
                  _buildStatusChip(context, widget.reservation.status.toMap()),
                  icon: Icons.flag_outlined,
                ),

                _buildDetailRow(
                  context,
                  'Dibuat Pada:',
                  _formatDateTime(widget.reservation.createdAt),
                  icon: Icons.add_circle_outline,
                ),
                _buildDetailRow(
                  context,
                  'Diperbarui Pada:',
                  _formatDateTime(widget.reservation.updatedAt),
                  icon: Icons.edit_calendar_outlined,
                ),
              ],
            ),
          ),
        ),
        if (widget.reservation.table != null)
          Card(
            color: context.cardTheme.color ?? context.colors.surface,
            elevation: context.cardTheme.elevation ?? 1.0,
            shape:
                context.cardTheme.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Meja',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(
                    color:
                        context.theme.dividerTheme.color?.withValues(
                          alpha: 0.5,
                        ) ??
                        context.colors.outline.withValues(alpha: 0.5),
                    height: 20,
                  ),
                  _buildDetailRow(
                    context,
                    'ID Meja:',
                    widget.reservation.tableId,
                    icon: Icons.table_restaurant_outlined,
                  ),
                  _buildDetailRow(
                    context,
                    'Nomor Meja:',
                    widget.reservation.table!.tableNumber,
                    icon: Icons.confirmation_number_outlined,
                  ),
                  _buildDetailRow(
                    context,
                    'Kapasitas:',
                    '${widget.reservation.table!.capacity} orang',
                    icon: Icons.people_outline,
                  ),
                  _buildDetailRowWidget(
                    context,
                    'Ketersediaan:',
                    _buildStatusChip(
                      context,
                      widget.reservation.table!.isAvailable
                          ? "Tersedia"
                          : "Tidak Tersedia",
                      isTableAvailability: true,
                    ),
                    icon: Icons.event_seat_outlined,
                  ),
                  _buildDetailRow(
                    context,
                    'Lokasi:',
                    widget.reservation.table!.location.toMap(),
                    icon: Icons.location_on_outlined,
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
              color: context.theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.all(8.0),
              child: reservationContent,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSavingInvoice ? null : _captureAndSaveReservationProof,
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
        backgroundColor: context.colors.primary,
        elevation: 4.0,
      ),
    );
  }
}
