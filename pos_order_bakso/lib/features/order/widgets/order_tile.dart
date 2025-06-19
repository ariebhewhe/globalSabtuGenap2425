import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/enums.dart'; // Pastikan path ini benar
import 'package:jamal/data/models/order_model.dart';

class OrderTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final void Function()? onLongPress;

  const OrderTile({Key? key, required this.order, this.onTap, this.onLongPress})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              context.theme.dividerTheme.color ??
              context.theme.colorScheme.outline,
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
                      'Order #${order.id.substring(0, 8)}',
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate),
                    style: context.theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildOrderTypeChip(context, order.orderType),
                  const SizedBox(width: 8),
                  _buildStatusChip(context, order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPaymentStatusChip(context, order.paymentStatus),
                  Text(
                    currencyFormatter.format(order.totalAmount),
                    style: context.theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (order.orderItems != null && order.orderItems!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '${order.orderItems!.length} item(s)',
                    style: context.theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeChip(BuildContext context, OrderType orderType) {
    IconData icon;
    String label;

    switch (orderType) {
      case OrderType.dineIn:
        icon = Icons.restaurant_menu_rounded;
        label = 'Dine In';
        break;
      case OrderType.takeAway:
        icon = Icons.takeout_dining_rounded;
        label = 'Takeaway';
        break;
    }

    return Chip(
      backgroundColor: context.theme.colorScheme.primary.withValues(alpha: 0.1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: context.theme.colorScheme.primary),
      label: Text(
        label,
        style: context.theme.textTheme.labelSmall?.copyWith(
          color: context.theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = context.theme.colorScheme.tertiary.withValues(
          alpha: 0.1,
        );
        textColor = context.theme.colorScheme.tertiary;
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = context.theme.colorScheme.primary.withValues(
          alpha: 0.1,
        );
        textColor = context.theme.colorScheme.primary;
        label = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = context.theme.colorScheme.secondary.withValues(
          alpha: 0.1,
        );
        textColor = context.theme.colorScheme.secondary;
        label = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = context.theme.colorScheme.primary.withValues(
          alpha: 0.2,
        );
        textColor = context.theme.colorScheme.primary;
        label = 'Ready';
        break;
      case OrderStatus.completed:
        backgroundColor = context.theme.colorScheme.secondary.withValues(
          alpha: 0.2,
        );
        textColor = context.theme.colorScheme.secondary;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        backgroundColor = (context.theme.textTheme.bodySmall?.color ??
                context.theme.colorScheme.onSurface)
            .withValues(alpha: 0.1);
        textColor =
            context.theme.textTheme.bodySmall?.color ??
            context.theme.colorScheme.onSurface;
        label = 'Cancelled';
        break;
    }

    return Chip(
      backgroundColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      label: Text(
        label,
        style: context.theme.textTheme.labelSmall?.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildPaymentStatusChip(BuildContext context, PaymentStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case PaymentStatus.pending:
      case PaymentStatus.challenge:
        backgroundColor = context.theme.colorScheme.tertiary.withValues(
          alpha: 0.1,
        );
        textColor =
            context.theme.colorScheme.tertiary; // Warna oranye dari theme
        label = 'Pending';
        icon = Icons.hourglass_empty_rounded;
        break;
      case PaymentStatus.success:
        backgroundColor = context.theme.colorScheme.primary.withValues(
          alpha: 0.1,
        );
        textColor =
            context
                .theme
                .colorScheme
                .primary; // Warna cokelat utama untuk sukses
        label = 'Paid';
        icon = Icons.check_circle_outline_rounded;
        break;
      case PaymentStatus.deny:
      case PaymentStatus.failure:
        backgroundColor = context.theme.colorScheme.error.withValues(
          alpha: 0.1,
        );
        textColor =
            context.theme.colorScheme.error; // Warna merah/aksen untuk error
        label = 'Failed';
        icon = Icons.cancel_outlined;
        break;
    }

    return Chip(
      backgroundColor: backgroundColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: context.theme.textTheme.labelSmall?.copyWith(color: textColor),
      ),
    );
  }
}
