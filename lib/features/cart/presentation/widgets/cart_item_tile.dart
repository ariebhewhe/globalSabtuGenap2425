import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/cart_item_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItemModel cartItem;
  final void Function() onSelected;
  final bool isSelected;
  final void Function() onIncrementQty;
  final void Function() onDecrementQty;

  const CartItemTile({
    super.key,
    required this.cartItem,
    required this.onSelected,
    required this.isSelected,
    required this.onIncrementQty,
    required this.onDecrementQty,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ListTile(
          onTap: onSelected,
          title: Text(cartItem.menuItem?.name ?? "Bakso"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onDecrementQty,
              ),
              Text(
                '${cartItem.quantity}',
                style: const TextStyle(fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onIncrementQty,
              ),
            ],
          ),
          leading: CachedNetworkImage(
            width: 56,
            height: 56,
            imageUrl:
                cartItem.menuItem?.imageUrl ??
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
