import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/data/models/menu_item_model.dart';

class PopularMenuItemCard extends StatelessWidget {
  final MenuItemModel menuItem;

  const PopularMenuItemCard({super.key, required this.menuItem});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Food image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child:
                (menuItem.imageUrl != null && menuItem.imageUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                      imageUrl: menuItem.imageUrl!,
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
                    )
                    : const Center(child: Text('No Image Available')),
          ),

          // Food details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name and availability status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildAvailabilityIndicator(),
                    ],
                  ),

                  // Price
                  Text(
                    currencyFormatter.format(menuItem.price),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),

                  // Spice level
                  Row(
                    children: [
                      const Text(
                        'Spice Level: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      _buildSpiceLevel(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            menuItem.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
      ),
      child: Text(
        menuItem.isAvailable ? 'Available' : 'Sold Out',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color:
              menuItem.isAvailable
                  ? Colors.green.shade800
                  : Colors.red.shade800,
        ),
      ),
    );
  }

  Widget _buildSpiceLevel() {
    return Row(
      children: List.generate(
        3,
        (index) => Icon(
          Icons.local_fire_department,
          size: 16,
          color:
              index < menuItem.spiceLevel ? Colors.red : Colors.grey.shade300,
        ),
      ),
    );
  }
}
