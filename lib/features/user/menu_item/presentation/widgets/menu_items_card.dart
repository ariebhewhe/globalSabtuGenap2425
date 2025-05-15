import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => const Center(
                                child: Icon(
                                  Icons.fastfood_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : const Center(child: Text('No Image Available')),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItem.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Rp ${menuItem.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Theme.of(context).primaryColor,
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
                            menuItem.isVegetarian ? Colors.green : Colors.brown,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        menuItem.isVegetarian ? 'Vegetarian' : 'Non-Veg',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      if (menuItem.spiceLevel > 0)
                        Row(
                          children: List.generate(
                            menuItem.spiceLevel,
                            (i) => const Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!menuItem.isAvailable)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tidak Tersedia',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
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
