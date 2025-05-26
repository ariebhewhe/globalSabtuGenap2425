import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/menu_item/presentation/widgets/menu_items_card.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';

import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/features/home/presentation/widgets/home_carousel.dart';
import 'package:jamal/features/home/presentation/widgets/category_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final popularItemsState = ref.watch(menuItemsProvider);

    final categories = categoriesState.categories;
    final popularItems = popularItemsState.menuItems;

    final isLoadingCategories = categoriesState.isLoading;
    final isLoadingPopular = popularItemsState.isLoading;

    const int skeletonCategoryCount = 4;
    const int skeletonPopularItemCount = 3;

    Future<void> refreshAllData() async {
      await ref.read(categoriesProvider.notifier).refreshCategories();
      await ref.read(menuItemsProvider.notifier).refreshMenuItems();
    }

    return Scaffold(
      body: MyScreenContainer(
        child: RefreshIndicator(
          onRefresh: refreshAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categoriesState.errorMessage != null ||
                    popularItemsState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.red.shade100,
                    width: double.infinity,
                    child: Text(
                      categoriesState.errorMessage ??
                          popularItemsState.errorMessage!,
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                if (categoriesState.errorMessage != null ||
                    popularItemsState.errorMessage != null)
                  const SizedBox(height: 16),

                const HomeCarousel(),

                const SizedBox(height: 24),

                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Skeletonizer(
                  enabled: isLoadingCategories,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount:
                        isLoadingCategories
                            ? skeletonCategoryCount
                            : categories.length,
                    itemBuilder: (context, index) {
                      final category =
                          isLoadingCategories
                              ? CategoryModel(
                                id: '',
                                name: 'Loading Category',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              )
                              : categories[index];

                      return CategoryCard(category: category);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Popular Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Skeletonizer(
                  enabled: isLoadingPopular,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount:
                        isLoadingPopular
                            ? skeletonPopularItemCount
                            : popularItems.length,
                    itemBuilder: (context, index) {
                      final menuItem =
                          isLoadingPopular
                              ? MenuItemModel(
                                id: '',
                                name: 'Loading Item',
                                description: '',
                                price: 0.0,
                                categoryId: '',
                                imageUrl: null,
                                isAvailable: true,
                                isVegetarian: false,
                                spiceLevel: 0,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              )
                              : popularItems[index];

                      return MenuItemCard(
                        menuItem: menuItem,
                        onTap:
                            isLoadingPopular
                                ? null
                                : () {
                                  context.router.push(
                                    MenuItemDetailRoute(menuItem: menuItem),
                                  );
                                },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
