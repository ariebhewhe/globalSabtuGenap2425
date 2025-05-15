import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/user/menu_item/presentation/widgets/menu_items_card.dart';
import 'package:jamal/features/user/menu_item/providers/menu_items_provider.dart';
import 'package:jamal/shared/widgets/my_app_bar.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class MenuItemsScreen extends StatelessWidget {
  const MenuItemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(),
      body: Consumer(
        builder: (context, ref, child) {
          final menuItemsState = ref.watch(menuItemsProvider);
          final menuItems = menuItemsState.menuItems;
          final isLoading = menuItemsState.isLoading;

          const int skeletonItemCount = 6;

          return Skeletonizer(
            enabled: isLoading,
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              itemCount: isLoading ? skeletonItemCount : menuItems.length,
              itemBuilder: (context, index) {
                final menuItem =
                    isLoading
                        ? MenuItemModel(
                          id: '',
                          name: 'Loading Item',
                          description: '',
                          price: 0.0,
                          category: '',
                          imageUrl: null,
                          isAvailable: true,
                          isVegetarian: false,
                          spiceLevel: 0,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        )
                        : menuItems[index];

                return MenuItemCard(
                  menuItem: menuItem,
                  onTap:
                      isLoading
                          ? null
                          : () {
                            if (index < menuItems.length) {
                              context.router.push(
                                MenuItemDetailRoute(menuItem: menuItems[index]),
                              );
                            }
                          },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
