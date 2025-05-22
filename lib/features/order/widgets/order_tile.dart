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
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(order.orderDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Order Type and Status
              Row(
                children: [
                  _buildOrderTypeChip(order.orderType),
                  const SizedBox(width: 8),
                  _buildStatusChip(order.status),
                ],
              ),

              const SizedBox(height: 12),

              // Payment Status and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPaymentStatusChip(order.paymentStatus),
                  Text(
                    currencyFormatter.format(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // If there are items, show count
              if (order.orderItems != null && order.orderItems!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    '${order.orderItems!.length} item(s)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeChip(OrderType orderType) {
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
      backgroundColor: Colors.blue.shade50,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: Colors.blue.shade700),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Ready';
        break;
      case OrderStatus.completed:
        backgroundColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        label = 'Completed';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Cancelled';
        break;
    }

    return Chip(
      backgroundColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
      label: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }

  Widget _buildPaymentStatusChip(PaymentStatus status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case PaymentStatus.unpaid:
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Unpaid';
        icon = Icons.payment_outlined;
        break;
      case PaymentStatus.paid:
        backgroundColor = Colors.green.shade50;
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
      label: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }
}
