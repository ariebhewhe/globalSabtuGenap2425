import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/currency_utils.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_provider.dart';
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class MenuItemDetailScreen extends ConsumerStatefulWidget {
  final MenuItemModel menuItem;

  const MenuItemDetailScreen({super.key, required this.menuItem});

  @override
  ConsumerState<MenuItemDetailScreen> createState() =>
      _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends ConsumerState<MenuItemDetailScreen> {
  void _handleAddToCart() {
    ref
        .read(cartItemMutationProvider.notifier)
        .addCartItem(
          CreateCartItemDto(
            menuItemId: widget.menuItem.id,
            quantity: 1,
            menuItem: DenormalizedMenuItemModel(
              id: widget.menuItem.id,
              name: widget.menuItem.name,
              price: widget.menuItem.price,
              imageUrl: widget.menuItem.imageUrl,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listener untuk aksi pada menu item (hapus, ubah)
    ref.listen(menuItemMutationProvider, (previous, next) {
      if (next.errorMessage != null) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(menuItemMutationProvider.notifier).resetErrorMessage();
      }
      if (next.successMessage != null) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(menuItemMutationProvider.notifier).resetSuccessMessage();
        context.router.pop(); // Kembali setelah sukses
      }
    });

    // Listener untuk aksi pada keranjang
    ref.listen(cartItemMutationProvider, (previous, next) {
      if (next.errorMessage != null) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(cartItemMutationProvider.notifier).resetErrorMessage();
      }
      if (next.successMessage != null) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(cartItemMutationProvider.notifier).resetSuccessMessage();
      }
    });

    final Color availableColor = context.colors.primary;
    final Color unavailableColor = context.colors.error;

    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.menuItem.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.menuItem.imageUrl!,
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
                widget.menuItem.name,
                style: context.textStyles.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Harga: ${CurrencyUtils.formatToRupiah(widget.menuItem.price)}',
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
                widget.menuItem.description.isEmpty
                    ? 'Tidak ada deskripsi.'
                    : widget.menuItem.description,
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Kategori: ${widget.menuItem.category?.name ?? "category"}',
                style: context.textStyles.bodyMedium,
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Icon(
                    widget.menuItem.isAvailable
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color:
                        widget.menuItem.isAvailable
                            ? availableColor
                            : unavailableColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    widget.menuItem.isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color:
                          widget.menuItem.isAvailable
                              ? availableColor
                              : unavailableColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Text(
                'Ditambahkan: ${widget.menuItem.createdAt.toLocal().toString().split('.')[0]}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.textStyles.labelSmall?.color?.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Diperbarui: ${widget.menuItem.updatedAt.toLocal().toString().split('.')[0]}',
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
          child: Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Keranjang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.secondary,
                    foregroundColor: context.colors.onSecondary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    textStyle: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed:
                      !widget.menuItem.isAvailable ? null : _handleAddToCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
