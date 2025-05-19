import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_provider.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class MenuItemDetailScreen extends StatelessWidget {
  final MenuItemModel menuItem;

  const MenuItemDetailScreen({Key? key, required this.menuItem})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserAppBar(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (menuItem.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: menuItem.imageUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.error, size: 50),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No Image Available')),
                ),
              const SizedBox(height: 16.0),

              Text(
                menuItem.name,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),

              Text(
                'Harga: Rp ${menuItem.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20.0,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16.0),

              const Text(
                'Deskripsi:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4.0),
              Text(
                menuItem.description,
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 16.0),

              Text(
                'Kategori: ${menuItem.categoryId}',
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 8.0),

              Row(
                children: [
                  Icon(
                    menuItem.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: menuItem.isAvailable ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    menuItem.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: menuItem.isAvailable ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              Row(
                children: [
                  Icon(
                    menuItem.isVegetarian
                        ? Icons.local_florist
                        : Icons.fastfood,
                    color: menuItem.isVegetarian ? Colors.green : Colors.brown,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    menuItem.isVegetarian ? 'Vegetarian' : 'Mengandung Daging',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              if (menuItem.spiceLevel > 0)
                Row(
                  children: [
                    const Text(
                      'Tingkat Pedas: ',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Row(
                      children: List.generate(
                        menuItem.spiceLevel,
                        (i) => const Icon(
                          Icons.local_fire_department,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Text(
                      ' (${menuItem.spiceLevel}/5)',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),

              const SizedBox(height: 16.0),
              Text(
                'Ditambahkan: ${menuItem.createdAt.toLocal().toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
              Text(
                'Diperbarui: ${menuItem.updatedAt.toLocal().toString().split('.')[0]}',
                style: const TextStyle(fontSize: 12.0, color: Colors.grey),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),

        child: SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              return Row(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => context.pushRoute(const OrdersRoute()),
                      child: const Text('Order', style: TextStyle()),
                    ),
                  ),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(cartItemMutationProvider.notifier)
                            .addCartItem(
                              CreateCartItemDto(
                                menuItemId: menuItem.id,
                                quantity: 1,
                                menuItem: DenormalizedMenuItemModel(
                                  id: menuItem.id,
                                  name: menuItem.name,
                                  price: menuItem.price,
                                ),
                              ),
                            );
                      },
                      child: const Text('Keranjang'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
