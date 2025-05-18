import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/data/models/order_item_model.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_provider.dart';
import 'package:jamal/features/cart/providers/cart_item_provider.dart';

class OrderTile extends StatelessWidget {
  final OrderModel order;

  const OrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ListTile(
          // title: Text(order.menuItem?.name ?? "Bakso"),
          // trailing: Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.remove_circle_outline),
          //       onPressed:
          //           order.quantity > 1
          //               ? () => ref
          //                   .read(orderMutationProvider.notifier)
          //                   .Order(
          //                     order.id,
          //                     OrderDto(quantity: order.quantity - 1),
          //                   )
          //               : null,
          //     ),
          //     Text('${order.quantity}', style: const TextStyle(fontSize: 16)),
          //     IconButton(
          //       icon: const Icon(Icons.add_circle_outline),
          //       onPressed:
          //           () => ref
          //               .read(orderMutationProvider.notifier)
          //               .Order(
          //                 order.id,
          //                 OrderDto(quantity: order.quantity + 1),
          //               ),
          //     ),
          //   ],
          // ),
          // leading: CachedNetworkImage(
          //   width: 56,
          //   height: 56,
          //   imageUrl:
          //       order.menuItem?.imageUrl ??
          //       "https://i.pinimg.com/736x/4f/6d/7e/4f6d7e577a4f3ae5045fd151fa16c2c7.jpg",
          //   fit: BoxFit.cover,
          //   placeholder:
          //       (context, url) =>
          //           const Center(child: CircularProgressIndicator()),
          //   errorWidget:
          //       (context, url, error) => const Center(
          //         child: Icon(
          //           Icons.fastfood_outlined,
          //           size: 40,
          //           color: Colors.grey,
          //         ),
          //       ),
          // ),
        );
      },
    );
  }
}
