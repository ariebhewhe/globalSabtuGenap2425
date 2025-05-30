import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';

@RoutePage()
class MenuItemDetailScreen extends StatelessWidget {
  final MenuItemModel menuItem;

  const MenuItemDetailScreen({Key? key, required this.menuItem})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color availableColor = context.colors.primary;
    final Color unavailableColor = context.colors.error;
    final Color vegetarianColor = context.colors.secondary;
    final Color nonVegetarianColor = context.colors.tertiary;
    final Color spiceColor = context.colors.error;

    return Scaffold(
      appBar: const UserAppBar(),
      endDrawer: const MyEndDrawer(),
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
                        (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: context.colors.primary,
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: context.colors.surface.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 50,
                            color: context.colors.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      'No Image Available',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24.0),

              Text(
                menuItem.name,
                style: context.textStyles.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),

              Text(
                'Harga: Rp ${menuItem.price.toStringAsFixed(0)}',
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16.0),

              Text(
                'Deskripsi:',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                menuItem.description.isEmpty
                    ? 'Tidak ada deskripsi.'
                    : menuItem.description,
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: 16.0),

              Text(
                'Kategori: ${menuItem.categoryId}',
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: 12.0),

              Row(
                children: [
                  Icon(
                    menuItem.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color:
                        menuItem.isAvailable
                            ? availableColor
                            : unavailableColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    menuItem.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color:
                          menuItem.isAvailable
                              ? availableColor
                              : unavailableColor,
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
                        ? Icons.eco_outlined
                        : Icons.restaurant_menu_outlined,
                    color:
                        menuItem.isVegetarian
                            ? vegetarianColor
                            : nonVegetarianColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    menuItem.isVegetarian ? 'Vegetarian' : 'Non-Vegetarian',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color:
                          menuItem.isVegetarian
                              ? vegetarianColor
                              : nonVegetarianColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              if (menuItem.spiceLevel > 0)
                Row(
                  children: [
                    Text(
                      'Tingkat Pedas: ',
                      style: context.textStyles.bodyLarge,
                    ),
                    Row(
                      children: List.generate(
                        menuItem.spiceLevel,
                        (i) => Icon(
                          Icons.local_fire_department,
                          size: 20,
                          color: spiceColor,
                        ),
                      ),
                    ),
                    Text(
                      ' (${menuItem.spiceLevel}/5)',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: spiceColor,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24.0),

              Text(
                'Ditambahkan: ${menuItem.createdAt.toLocal().toString().split('.')[0]}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.textStyles.labelSmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Diperbarui: ${menuItem.updatedAt.toLocal().toString().split('.')[0]}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.textStyles.labelSmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color:
              context.theme.bottomAppBarTheme.color ??
              context.theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              return ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
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
                            imageUrl: menuItem.imageUrl,
                          ),
                        ),
                      );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${menuItem.name} ditambahkan ke keranjang!',
                      ),
                      backgroundColor: context.colors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                label: const Text('Keranjang'),

                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.secondary,
                  foregroundColor: context.colors.onSecondary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
