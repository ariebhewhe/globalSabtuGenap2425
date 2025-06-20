import 'dart:ui'; // Pastikan import ini ada

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/core/utils/currency_utils.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItemModel menuItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MenuItemCard({
    super.key,
    required this.menuItem,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: context.cardTheme.shape,
      elevation: context.cardTheme.elevation,
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildImage(context),
                if (!menuItem.isAvailable) _buildAvailabilityOverlay(context),
                // Mengganti _buildCategoryChip dengan _buildFrostedCategoryInfo
                if (menuItem.category != null)
                  _buildFrostedCategoryInfo(context),
              ],
            ),
            // [FIX OVERFLOW] Bungkus panel info dengan Expanded
            Expanded(child: _buildInfoPanel(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return SizedBox(
      height: 140,
      width: double.infinity,
      child:
          (menuItem.imageUrl != null && menuItem.imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                imageUrl: menuItem.imageUrl!,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: context.colors.surface.withValues(alpha: 0.5),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => _buildPlaceholderIcon(context),
              )
              : _buildPlaceholderIcon(context),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Container(
      color: context.isDarkMode ? Colors.black26 : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.fastfood_outlined,
          size: 50,
          color: context.colors.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildAvailabilityOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Text(
            'Tidak Tersedia',
            style: context.textStyles.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// [DESAIN BARU] Widget untuk menampilkan kategori dengan efek kaca buram.
  Widget _buildFrostedCategoryInfo(BuildContext context) {
    return Positioned(
      top: 8,
      left: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.all(Radius.circular(8.0)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Text(
              menuItem.category!.name,
              style: context.textStyles.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  const Shadow(
                    blurRadius: 2.0,
                    color: Colors.black54,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [FIX OVERFLOW] Panel info sekarang berada di dalam Expanded,
  /// kita gunakan MainAxisAlignment.center agar kontennya rapi secara vertikal.
  Widget _buildInfoPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.center, // Pusatkan konten secara vertikal
        children: [
          Text(
            menuItem.name,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(), // Beri jarak fleksibel
          Text(
            CurrencyUtils.formatToRupiah(menuItem.price),
            style: context.textStyles.bodyLarge?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
