import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onSelected,
        title: Text(
          cartItem.menuItem?.name ?? "Unknown Item",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Rp ${(cartItem.menuItem?.price ?? 0) * cartItem.quantity}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrementQty,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${cartItem.quantity}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrementQty,
            ),
          ],
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            width: 60,
            height: 60,
            imageUrl:
                cartItem.menuItem?.imageUrl ??
                "https://i.pinimg.com/736x/4f/6d/7e/4f6d7e577a4f3ae5045fd151fa16c2c7.jpg",
            fit: BoxFit.cover,
            placeholder:
                (context, url) =>
                    const Center(child: CircularProgressIndicator()),
            errorWidget:
                (context, url, error) => Container(
                  color: Colors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(
                      Icons.fastfood_outlined,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
