import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
// import 'package:jamal/core/utils/enums.dart'; // Tidak terpakai di kode ini secara langsung, namun mungkin dipakai di tempat lain
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_provider.dart';

// Import untuk fungsionalitas "Tambah ke Keranjang"
import 'package:jamal/data/models/cart_item_model.dart';
import 'package:jamal/features/cart/providers/cart_item_mutation_provider.dart';

import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

// Asumsi Anda memiliki ekstensi ini atau cara serupa untuk mengakses colors dan textStyles
// Jika tidak, Anda mungkin perlu menggantinya dengan Theme.of(context).colorScheme...
// atau ThemeData.of(context).textTheme...
extension BuildContextEntensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textStyles => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}

// Asumsi Color.withValues adalah ekstensi custom, jika standar Flutter, gunakan withOpacity
// Misalnya: color.withOpacity(0.1)
extension ColorExtensions on Color {
  Color withValues({double? alpha}) {
    return withOpacity(alpha ?? this.alpha / 255);
  }
}

@RoutePage()
class AdminMenuItemDetailScreen extends StatelessWidget {
  final MenuItemModel menuItem;

  const AdminMenuItemDetailScreen({Key? key, required this.menuItem})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color availableColor = context.colors.primary;
    final Color unavailableColor = context.colors.error;
    final Color vegetarianColor = context.colors.secondary;
    final Color nonVegetarianColor =
        context.colors.tertiary; // Pastikan tertiary ada di ColorScheme Anda
    final Color spiceColor = context.colors.error;

    return Scaffold(
      appBar: const AdminAppBar(),
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
                'Kategori: ${menuItem.categoryId}', // Anda mungkin ingin menampilkan nama kategori
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
              const SizedBox(height: 80), // Extra space for scrolling
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
              // Helper method untuk menangani aksi hapus
              Future<void> handleDeleteAction() async {
                final bool? confirmed = await showDialog<bool>(
                  context: context, // Menggunakan context dari Consumer builder
                  barrierDismissible: false,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(
                        'Konfirmasi Hapus',
                        style: dialogContext.textStyles.titleLarge,
                      ),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus menu "${menuItem.name}"?\nTindakan ini tidak dapat diurungkan.',
                        style: dialogContext.textStyles.bodyMedium,
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: dialogContext.colors.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(false);
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Hapus',
                            style: TextStyle(color: dialogContext.colors.error),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  try {
                    await ref
                        .read(menuItemMutationProvider.notifier)
                        .deleteMenuItem(menuItem.id);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${menuItem.name} berhasil dihapus.'),
                        backgroundColor: context.colors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    AutoRouter.of(context).pop();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal menghapus ${menuItem.name}: ${e.toString()}',
                        ),
                        backgroundColor: context.colors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }

              return Row(
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
                        ), // Sedikit lebih besar
                        textStyle: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ), // Sesuaikan style text
                      ),
                      onPressed:
                          !menuItem.isAvailable
                              ? null
                              : () {
                                // Disable jika tidak tersedia
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: context.colors.onSurface.withValues(alpha: 0.8),
                      size: 28,
                    ),
                    tooltip: 'Opsi Admin',
                    onSelected: (String choice) {
                      if (choice == 'edit') {
                        AutoRouter.of(
                          context,
                        ).push(AdminMenuItemUpsertRoute(menuItem: menuItem));
                      } else if (choice == 'delete') {
                        handleDeleteAction();
                      }
                    },
                    itemBuilder: (BuildContext popupContext) {
                      return [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(
                              Icons.edit_outlined,
                              color: popupContext.colors.primary,
                            ),
                            title: Text(
                              'Ubah Menu',
                              style: popupContext.textStyles.bodyLarge,
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: popupContext.colors.error,
                            ),
                            title: Text(
                              'Hapus Menu',
                              style: popupContext.textStyles.bodyLarge,
                            ),
                          ),
                        ),
                      ];
                    },
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
