import 'dart:typed_data';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart'; // Import ToastUtils
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_mutation_provider.dart';
import 'package:jamal/main.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:screenshot/screenshot.dart';
import 'package:file_saver/file_saver.dart';

@RoutePage()
class AdminTableReservationDetailScreen extends StatefulWidget {
  final TableReservationModel reservation;

  const AdminTableReservationDetailScreen({Key? key, required this.reservation})
    : super(key: key);

  @override
  State<AdminTableReservationDetailScreen> createState() =>
      _AdminTableReservationDetailScreenState();
}

class _AdminTableReservationDetailScreenState
    extends State<AdminTableReservationDetailScreen> {
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
      avatar: Icon(chipIcon, color: chipTextColor, size: 16),
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

    ToastUtils.showInfo(
      context: context,
      message: 'Menyiapkan bukti reservasi...',
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

      if (filePath != null && filePath.isNotEmpty) {
        if (!context.mounted) return;
        ToastUtils.showSuccess(
          context: context,
          message: 'Bukti reservasi disimpan: $filePath',
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
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
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
              Future<void> handleDeleteAction() async {
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(
                        'Konfirmasi Hapus',
                        style: dialogContext.textStyles.titleLarge,
                      ),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus reservasi "${widget.reservation.id}"?\nTindakan ini tidak dapat diurungkan.',
                        style: dialogContext.textStyles.bodyMedium,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: dialogContext.colors.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Hapus',
                            style: TextStyle(color: dialogContext.colors.error),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  try {
                    await ref
                        .read(tableReservationMutationProvider.notifier)
                        .deleteTableReservation(widget.reservation.id);

                    if (!context.mounted) return;
                    ToastUtils.showSuccess(
                      context: context,
                      message: '${widget.reservation.id} berhasil dihapus.',
                    );
                    AutoRouter.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    ToastUtils.showError(
                      context: context,
                      message:
                          'Gagal menghapus ${widget.reservation.id}: ${e.toString()}',
                    );
                  }
                }
              }

              return Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _isSavingInvoice
                              ? null
                              : _captureAndSaveReservationProof,
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
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: context.colors.onSurface.withValues(alpha: 0.8),
                      size: 28,
                    ),
                    tooltip: 'Opsi Admin',
                    onSelected: (String choice) {
                      if (choice == 'edit') {
                        AutoRouter.of(context).push(
                          AdminUpdateTableReservationRoute(
                            tableReservation: widget.reservation,
                          ),
                        );
                      } else if (choice == 'delete') {
                        handleDeleteAction();
                      }
                    },
                    itemBuilder: (BuildContext popupContext) {
                      return [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(
                              Icons.edit_outlined,
                              color: popupContext.colors.primary,
                            ),
                            title: Text(
                              'Ubah Reservasi',
                              style: popupContext.textStyles.bodyLarge,
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: popupContext.colors.error,
                            ),
                            title: Text(
                              'Hapus Reservasi',
                              style: popupContext.textStyles.bodyLarge,
                            ),
                          ),
                        ),
                      ];
                    },
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
