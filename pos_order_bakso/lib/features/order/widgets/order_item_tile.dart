import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/order_item_model.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItemModel orderItem;

  const OrderItemTile({super.key, required this.orderItem});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ListTile(
          title: Text(orderItem.menuItem?.name ?? "Bakso"),
          trailing: Text('x${orderItem.quantity}'),
          leading: CachedNetworkImage(
            width: 56,
            height: 56,
            imageUrl:
                orderItem.menuItem?.imageUrl ??
                "https://i.pinimg.com/736x/4f/6d/7e/4f6d7e577a4f3ae5045fd151fa16c2c7.jpg",
            fit: BoxFit.cover,
            placeholder:
                (context, url) =>
                    const Center(child: CircularProgressIndicator()),
            errorWidget:
                (context, url, error) => const Center(
                  child: Icon(
                    Icons.fastfood_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
          ),
        );
      },
    );
  }
}
