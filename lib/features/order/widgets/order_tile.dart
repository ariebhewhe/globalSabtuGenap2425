import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/order_model.dart';

class OrderTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderTile({Key? key, required this.order, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate),
                    style: theme.textTheme.bodySmall,
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
                    style: theme.textTheme.titleMedium?.copyWith(
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
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeChip(BuildContext context, OrderType orderType) {
    final theme = Theme.of(context);
    IconData icon;
    String label;

    switch (orderType) {
      case OrderType.dineIn:
        icon = Icons.restaurant;
        label = 'Dine In';
        break;
      case OrderType.takeAway:
        icon = Icons.takeout_dining;
        label = 'Takeaway';
        break;
    }

    return Chip(
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderStatus status) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.1);
        textColor = theme.colorScheme.primary;
        label = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = theme.colorScheme.secondary.withValues(alpha: 0.1);
        textColor = theme.colorScheme.secondary;
        label = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        label = 'Ready';
        break;
      case OrderStatus.completed:
        backgroundColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal.shade700;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
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

  Widget _buildPaymentStatusChip(BuildContext context, PaymentStatus status) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case PaymentStatus.unpaid:
        backgroundColor = theme.colorScheme.error.withValues(alpha: 0.1);
        textColor = theme.colorScheme.error;
        label = 'Unpaid';
        icon = Icons.payment_outlined;
        break;
      case PaymentStatus.paid:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        label = 'Paid';
        icon = Icons.check_circle_outline;
        break;
    }

    return Chip(
      backgroundColor: backgroundColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: textColor),
      ),
    );
  }
}
