import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
// Asumsi path untuk DTO
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_provider.dart';
import 'package:jamal/features/cart/providers/cart_items_provider.dart';
import 'package:jamal/features/cart/providers/cart_items_state.dart'; // Import state
import 'package:jamal/features/cart/providers/selected_cart_items_provider.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Kita langsung akses state dari provider
        final cartItemsState = ref.read(cartItemsProvider);
        if (!cartItemsState.isLoadingMore && cartItemsState.hasMore) {
          ref.read(cartItemsProvider.notifier).loadMoreCartItems();
        }
      });
    }
  }

  void _handleCartItemSelection(CartItemModel cartItem) {
    ref.read(selectedCartItemsProvider.notifier).toggleSelection(cartItem);
  }

  void _handleIncrementQuantity(CartItemModel cartItem) {
    final newQty = cartItem.quantity + 1;
    final updateDto = UpdateCartItemDto(quantity: newQty);
    ref
        .read(cartItemMutationProvider.notifier)
        .updateCartItem(cartItem.id, updateDto);
  }

  void _handleDecrementQuantity(BuildContext context, CartItemModel cartItem) {
    if (cartItem.quantity > 1) {
      final newQty = cartItem.quantity - 1;
      final updateDto = UpdateCartItemDto(quantity: newQty);
      ref
          .read(cartItemMutationProvider.notifier)
          .updateCartItem(cartItem.id, updateDto);
    } else {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Hapus Item'),
              content: const Text(
                'Apakah Anda ingin menghapus item ini dari keranjang?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref
                        .read(cartItemMutationProvider.notifier)
                        .deleteCartItem(cartItem.id);
                  },
                  child: Text(
                    'Ya',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCartItems = ref.watch(selectedCartItemsProvider);
    final textStyles = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;

    // --- BLOK YANG DIPERBAIKI ---
    ref.listen<CartItemsState>(cartItemsProvider, (previous, next) {
      // Kondisi untuk mendeteksi transisi dari loading ke selesai
      // `previous?` digunakan untuk menangani state awal saat `previous` masih null.
      final bool wasLoading = previous?.isLoading ?? false;

      if (wasLoading && !next.isLoading && next.errorMessage == null) {
        // Jika loading selesai dan tidak ada error, perbarui item yang diseleksi.
        ref
            .read(selectedCartItemsProvider.notifier)
            .initializeSelection(next.cartItems);
      }
    });
    // --- AKHIR BLOK YANG DIPERBAIKI ---

    // Kita watch state di sini agar UI rebuild saat state berubah
    final cartItemsState = ref.watch(cartItemsProvider);
    final cartItems = cartItemsState.cartItems;
    final isLoading = cartItemsState.isLoading;

    return Scaffold(
      appBar: const UserAppBar(),
      endDrawer: const MyEndDrawer(),
      bottomNavigationBar:
          selectedCartItems.isEmpty && isLoading
              ? null
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed:
                        selectedCartItems.isEmpty
                            ? null
                            : () => context.pushRoute(const CreateOrderRoute()),
                    child: const Text('Checkout'),
                  ),
                ),
              ),
      body: MyScreenContainer(
        child: RefreshIndicator(
          onRefresh:
              () => ref.read(cartItemsProvider.notifier).refreshCartItems(),
          child: Column(
            children: [
              if (cartItemsState.errorMessage != null && !isLoading)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: colors.error.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: Text(
                    cartItemsState.errorMessage!,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              Expanded(
                child: Skeletonizer(
                  enabled: isLoading,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    itemCount:
                        isLoading
                            ? 6 // Skeleton item count
                            : cartItems.length +
                                (cartItemsState.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
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
                                id: 'skeleton_$index',
                                userId: '',
                                menuItemId: '',
                                quantity: 1,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              )
                              : cartItems[index];

                      final isSelected = ref
                          .read(selectedCartItemsProvider.notifier)
                          .isSelected(cartItem);

                      return CartItemTile(
                        cartItem: cartItem,
                        onSelected: () => _handleCartItemSelection(cartItem),
                        isSelected: isSelected,
                        onIncrementQty:
                            () => _handleIncrementQuantity(cartItem),
                        onDecrementQty:
                            () => _handleDecrementQuantity(context, cartItem),
                      );
                    },
                  ),
                ),
              ),
              if (selectedCartItems.isNotEmpty && !isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardTheme.color ?? Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, -2),
                        blurRadius: 6,
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedCartItems.length} item terpilih',
                        style: textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.error,
                          foregroundColor: colors.onError,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Hapus Item'),
                                  content: Text(
                                    'Apakah Anda ingin menghapus ${selectedCartItems.length} item terpilih dari keranjang?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        for (final item in selectedCartItems) {
                                          ref
                                              .read(
                                                cartItemMutationProvider
                                                    .notifier,
                                              )
                                              .deleteCartItem(item.id);
                                        }
                                        ref
                                            .read(
                                              selectedCartItemsProvider
                                                  .notifier,
                                            )
                                            .clearSelectedItems();
                                      },
                                      child: Text(
                                        'Hapus',
                                        style: TextStyle(color: colors.error),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                        child: const Text('Hapus Item Terpilih'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
