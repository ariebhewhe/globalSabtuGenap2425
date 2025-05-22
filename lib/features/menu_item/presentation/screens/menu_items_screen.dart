import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/menu_item/presentation/widgets/menu_items_card.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class MenuItemsScreen extends ConsumerStatefulWidget {
  const MenuItemsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MenuItemsScreen> createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends ConsumerState<MenuItemsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      // * Ketika pengguna scroll mendekati bawah, muat lebih banyak data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final menuItemsState = ref.watch(menuItemsProvider);

        // * Periksa apakah sedang loading more dan masih ada data untuk dimuat
        if (!menuItemsState.isLoadingMore && menuItemsState.hasMore) {
          ref.read(menuItemsProvider.notifier).loadMoreMenuItems();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: Consumer(
          builder: (context, ref, child) {
            final menuItemsState = ref.watch(menuItemsProvider);
            final menuItems = menuItemsState.menuItems;
            final isLoading = menuItemsState.isLoading;
            const int skeletonItemCount = 6;

            return RefreshIndicator(
              onRefresh:
                  () => ref.read(menuItemsProvider.notifier).refreshMenuItems(),
              child: Column(
                children: [
                  //  Error message jika ada
                  if (menuItemsState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red.shade100,
                      width: double.infinity,
                      child: Text(
                        menuItemsState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  //  Konten utama
                  Expanded(
                    child: Skeletonizer(
                      enabled: isLoading,
                      child: GridView.builder(
                        controller: _scrollController,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.8,
                            ),
                        itemCount:
                            isLoading
                                ? skeletonItemCount
                                : menuItems.length +
                                    (menuItemsState.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (!isLoading &&
                              index == menuItems.length &&
                              menuItemsState.isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final menuItem =
                              isLoading
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
                                  : menuItems[index];

                          return MenuItemCard(
                            menuItem: menuItem,
                            onTap:
                                isLoading
                                    ? null
                                    : () {
                                      if (index < menuItems.length) {
                                        context.router.push(
                                          MenuItemDetailRoute(
                                            menuItem: menuItems[index],
                                          ),
                                        );
                                      }
                                    },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
