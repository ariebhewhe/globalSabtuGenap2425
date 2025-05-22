import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel menuItem;
  final VoidCallback? onTap;

  const MenuItemCard({Key? key, required this.menuItem, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8.0),
                ),
                child:
                    (menuItem.imageUrl != null && menuItem.imageUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                          imageUrl: menuItem.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: context.colors.primary,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Center(
                                child: Icon(
                                  Icons.fastfood_outlined,
                                  size: 40,
                                  color: context.colors.onSurface.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                        )
                        : Center(
                          child: Text(
                            'No Image Available',
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem.name,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Rp ${menuItem.price.toStringAsFixed(0)}',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Icon(
                        menuItem.isVegetarian
                            ? Icons.local_florist
                            : Icons.fastfood,
                        size: 16,
                        color:
                            menuItem.isVegetarian
                                ? Colors.green
                                : context.colors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        menuItem.isVegetarian ? 'Vegetarian' : 'Non-Veg',
                        style: context.textStyles.bodySmall,
                      ),
                      const Spacer(),
                      if (menuItem.spiceLevel > 0)
                        Row(
                          children: List.generate(
                            menuItem.spiceLevel,
                            (i) => Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: context.colors.tertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!menuItem.isAvailable)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tidak Tersedia',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
