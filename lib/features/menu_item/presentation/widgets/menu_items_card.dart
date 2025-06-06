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
        clipBehavior: Clip.antiAlias, // Memastikan konten di-clip sesuai shape
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                        child: Icon(
                          Icons.fastfood_outlined,
                          size: 40,
                          color: context.colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                  if (!menuItem.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Text(
                            'Tidak Tersedia',
                            style: context.textStyles.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
