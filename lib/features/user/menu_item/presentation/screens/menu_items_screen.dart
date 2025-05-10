import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.gr.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/user/menu_item/providers/menu_items_provider.dart';
import 'package:jamal/shared/widgets/my_app_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class MenuItemsScreen extends StatelessWidget {
  const MenuItemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<MenuItemModel> _sampleMenuItems = [
      MenuItemModel(
        id: '1',
        name: 'Nasi Goreng',
        description: 'Nasi yang digoreng dengan bumbu rempah pilihan.',
        price: 25000.0,
        category: 'Makanan Utama',
        imageUrl:
            'https://images.unsplash.com/photo-1548940740-204726c4ed85', // Example image URL
        isAvailable: true,
        isVegetarian: false,
        spiceLevel: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MenuItemModel(
        id: '2',
        name: 'Capcay Goreng',
        description: 'Tumis berbagai macam sayuran segar.',
        price: 22000.0,
        category: 'Sayuran',
        imageUrl:
            'https://images.unsplash.com/photo-1623299036666-086198b6566a',
        isAvailable: true,
        isVegetarian: true,
        spiceLevel: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MenuItemModel(
        id: '3',
        name: 'Sate Ayam',
        description: 'Daging ayam panggang ditusuk dengan bumbu kacang.',
        price: 30000.0,
        category: 'Lauk',
        imageUrl:
            'https://images.unsplash.com/photo-1613458857569-c8a09016f574',
        isAvailable: false, // Example of unavailable item
        isVegetarian: false,
        spiceLevel: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MenuItemModel(
        id: '4',
        name: 'Es Teh Manis',
        description: 'Minuman teh dingin dengan gula.',
        price: 8000.0,
        category: 'Minuman',
        imageUrl:
            'https://images.unsplash.com/photo-1573818029581-3060c7ed3476',
        isAvailable: true,
        isVegetarian: true, // Assuming tea is vegetarian
        spiceLevel: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MenuItemModel(
        id: '5',
        name: 'Gado-Gado',
        description:
            'Campuran sayuran rebus, kentang, tahu, tempe, telur, dan bumbu kacang.',
        price: 28000.0,
        category: 'Makanan Utama',
        imageUrl:
            'https://images.unsplash.com/photo-1597404294360-feeeda0e82d9',
        isAvailable: true,
        isVegetarian: true,
        spiceLevel: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      MenuItemModel(
        id: '6',
        name: 'Mie Goreng',
        description: 'Mie kuning digoreng dengan sayuran dan bumbu.',
        price: 24000.0,
        category: 'Makanan Utama',
        imageUrl:
            'https://images.unsplash.com/photo-1613458857569-c8a09016f574', // Using same image for demo
        isAvailable: true,
        isVegetarian: false,
        spiceLevel: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      appBar: const MyAppBar(),
      body: Consumer(
        builder: (context, ref, child) {
          final menuItemsState = ref.watch(menuItemsProvider);

          return Skeletonizer(
            enabled: menuItemsState.isLoading,
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              itemCount:
                  menuItemsState.isLoading
                      ? 6
                      : menuItemsState
                          .menuItems
                          .length, // Show skeleton items when loading
              itemBuilder: (context, index) {
                final menuItem =
                    menuItemsState.isLoading
                        ? _sampleMenuItems[index % _sampleMenuItems.length]
                        : menuItemsState.menuItems[index];

                return GestureDetector(
                  onTap:
                      menuItemsState.isLoading
                          ? null
                          : () {
                            context.router.push(
                              MenuItemDetailRoute(menuItem: menuItem),
                            );
                          },
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8.0),
                            ),
                            child:
                                (menuItem.imageUrl != null &&
                                        !menuItemsState
                                            .isLoading) // Only show actual image if not loading and URL exists
                                    ? CachedNetworkImage(
                                      imageUrl: menuItem.imageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => const Center(
                                            child: CircularProgressIndicator(),
                                          ), // Basic placeholder
                                      errorWidget:
                                          (context, url, error) => const Icon(
                                            Icons.error,
                                          ), // Error icon
                                    )
                                    : Center(
                                      child: Text(
                                        menuItemsState.isLoading
                                            ? ''
                                            : 'No Image',
                                      ),
                                    ), // Show placeholder or no image text
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
                                'Rp ${menuItem.price.toStringAsFixed(0)}', // Format price
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
                                        menuItem.isVegetarian
                                            ? Colors.green
                                            : Colors.brown,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    menuItem.isVegetarian
                                        ? 'Vegetarian'
                                        : 'Non-Veg',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const Spacer(),
                                  if (menuItem.spiceLevel >
                                      0) // Show chili icons for spice level
                                    Row(
                                      children: List.generate(
                                        menuItem.spiceLevel,
                                        (i) => Icon(
                                          Icons.local_fire_department,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (!menuItem.isAvailable &&
                                  !menuItemsState
                                      .isLoading) // Show unavailable status if not loading
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
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
              },
            ),
          );
        },
      ),
    );
  }
}
