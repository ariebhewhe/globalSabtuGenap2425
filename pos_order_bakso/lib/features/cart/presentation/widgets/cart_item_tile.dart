import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jamal/core/utils/currency_utils.dart';
import 'package:jamal/core/utils/enums.dart';
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
        color:
            isSelected ? context.colors.primary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isSelected
                  ? context.colors.primary
                  : context.colors.onSurface.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onSelected,
        title: Text(
          cartItem.menuItem?.name ?? "Unknown Item",
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              CurrencyUtils.formatToRupiah(
                (cartItem.menuItem?.price ?? 0) * cartItem.quantity,
              ),
              style: TextStyle(
                color: context.colors.primary,
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
                color: context.colors.surface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${cartItem.quantity}',
                style: context.textStyles.titleMedium?.copyWith(
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
                  color: context.colors.onSurface.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(
                      Icons.fastfood_outlined,
                      size: 30,

                      color: context.colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
