import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:jamal/features/cart/providers/cart_items_provider.dart';
import 'package:jamal/features/cart/providers/selected_cart_items_provider.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:jamal/shared/widgets/user_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:skeletonizer/skeletonizer.dart';

@RoutePage()
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
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
        final cartItemsState = ref.watch(cartItemsProvider);

        // * Periksa apakah sedang loading more dan masih ada data untuk dimuat
        if (!cartItemsState.isLoadingMore && cartItemsState.hasMore) {
          ref.read(cartItemsProvider.notifier).loadMoreCartItems();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCartItems = ref.watch(selectedCartItemsProvider);

    return Scaffold(
      appBar: const UserAppBar(),
      endDrawer: const UserEndDrawer(),
      body: MyScreenContainer(
        child: Consumer(
          builder: (context, ref, child) {
            final cartItemsState = ref.watch(cartItemsProvider);
            final cartItems = cartItemsState.cartItems;
            final isLoading = cartItemsState.isLoading;
            const int skeletonItemCount = 6;

            return RefreshIndicator(
              onRefresh:
                  () => ref.read(cartItemsProvider.notifier).refreshCartItems(),
              child: Column(
                children: [
                  if (cartItemsState.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red.shade100,
                      width: double.infinity,
                      child: Text(
                        cartItemsState.errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  Expanded(
                    child: Skeletonizer(
                      enabled: isLoading,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount:
                            isLoading
                                ? skeletonItemCount
                                : cartItems.length +
                                    (cartItemsState.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          // Loading more indicator di akhir
                          if (!isLoading &&
                              index == cartItems.length &&
                              cartItemsState.isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final cartItem =
                              isLoading
                                  ? CartItemModel(
                                    id: '',
                                    userId: '',
                                    menuItemId: '',
                                    quantity: 0,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  )
                                  : cartItems[index];

                          return CartItemTile(
                            cartItem: cartItem,
                            onSelected: () {},
                            isSelected: false,
                            onIncrementQty: () {},
                            onDecrementQty: () {},
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
