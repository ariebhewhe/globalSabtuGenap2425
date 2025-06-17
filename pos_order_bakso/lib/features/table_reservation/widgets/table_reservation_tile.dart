import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/table_reservation_model.dart';

class TableReservationTile extends StatelessWidget {
  final TableReservationModel tableReservation;
  final VoidCallback? onTap;
  final void Function()? onLongPress;

  const TableReservationTile({
    Key? key,
    required this.tableReservation,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerTheme.color ?? theme.colorScheme.outline,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Reservation #${tableReservation.id.length >= 8 ? tableReservation.id.substring(0, 8) : tableReservation.id}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                    ).format(tableReservation.reservationTime),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _buildTableInfoChip(context),
                  const SizedBox(width: 8),
                  _buildStatusChip(context, tableReservation.status),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (tableReservation.table != null)
                    _buildLocationChip(
                      context,
                      tableReservation.table!.location,
                    ),
                  Text(
                    'Order #${tableReservation.orderId.length >= 8 ? tableReservation.orderId.substring(0, 8) : tableReservation.orderId}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (tableReservation.table != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Table ${tableReservation.table!.tableNumber} • Capacity: ${tableReservation.table!.capacity}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableInfoChip(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        Icons.table_restaurant,
        size: 16,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        tableReservation.table?.tableNumber ??
            (tableReservation.tableId.length >= 8
                ? tableReservation.tableId.substring(0, 8)
                : tableReservation.tableId),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, ReservationStatus status) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case ReservationStatus.reserved:
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        textColor = theme.colorScheme.primary;
        label = 'Reserved';
        break;
      case ReservationStatus.occupied:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        label = 'Occupied';
        break;
      case ReservationStatus.completed:
        backgroundColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal.shade700;
        label = 'Completed';
        break;
      case ReservationStatus.cancelled:
        backgroundColor = theme.colorScheme.error.withValues(alpha: 0.1);
        textColor = theme.colorScheme.error;
        label = 'Cancelled';
        break;
    }

    return Chip(
      backgroundColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildLocationChip(BuildContext context, Location location) {
    final theme = Theme.of(context);
    IconData icon;
    String label;

    switch (location) {
      case Location.indoor:
        icon = Icons.home_outlined;
        label = 'Indoor';
        break;
      case Location.outdoor:
        icon = Icons.deck_outlined;
        label = 'Outdoor';
        break;
      case Location.vip:
        icon = Icons.star_outline;
        label = 'VIP';
        break;
    }

    return Chip(
      backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: theme.colorScheme.secondary),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}
