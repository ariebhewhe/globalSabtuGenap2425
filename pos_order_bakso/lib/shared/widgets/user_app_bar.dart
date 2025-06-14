import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/features/cart/providers/cart_item_aggregate_provider.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? customTitle;
  final bool automaticLeading;
  final Widget? leading;
  final Color? backgroundColor;
  final double? elevation;
  final bool centerTitle;

  const UserAppBar({
    super.key,
    this.customTitle,
    this.automaticLeading = true,
    this.leading,
    this.backgroundColor,
    this.elevation,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _getAppBarTitle(BuildContext context) {
    // * Jika custom title disediakan, gunakan itu
    if (customTitle != null) {
      return customTitle!;
    }

    // * Gunakan data dari AutoRoute untuk mendapatkan judul
    final router = context.router;
    final routeData = router.current;

    // * Coba dapatkan nama page dari routeData
    final pageName = routeData.name;
    if (pageName.isNotEmpty) {
      // * Format nama page (contoh: 'ProfileRoute' menjadi 'Profile')
      final formattedName = pageName.replaceAll('Route', '');

      // * Pisahkan berdasarkan huruf kapital dan join dengan spasi
      final titleWords = <String>[];
      final chars = formattedName.characters.toList();

      String currentWord = '';
      for (int i = 0; i < chars.length; i++) {
        final char = chars[i];
        if (i > 0 && char.toUpperCase() == char && char.toLowerCase() != char) {
          // * Ini huruf kapital yang bukan karakter pertama
          if (currentWord.isNotEmpty) {
            titleWords.add(currentWord);
            currentWord = char;
          } else {
            currentWord += char;
          }
        } else {
          currentWord += char;
        }
      }

      if (currentWord.isNotEmpty) {
        titleWords.add(currentWord);
      }

      if (titleWords.isNotEmpty) {
        return titleWords.join(' ');
      }

      return formattedName;
    }

    // * Fallback ke path jika nama page tidak tersedia
    final currentPath = router.currentPath;
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      // * Convert route segment to title case (e.g., "user-profile" to "User Profile")
      return segments.last
          .split(RegExp(r'[-_]'))
          .map(
            (word) =>
                word.isEmpty
                    ? ''
                    : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');
    }

    // * Fallback ke default jika tidak ada informasi tersedia
    return 'App';
  }

  Widget _buildCartIcon(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final distinctTotalMenuItemsInCart = ref.watch(
          distinctCartItemCountProvider,
        );

        return distinctTotalMenuItemsInCart.when(
          data: (itemCount) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cart Icon Button with improved styling
                  Container(
                    decoration: BoxDecoration(
                      color:
                          itemCount > 0
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => context.pushRoute(const CartRoute()),
                      icon: Icon(
                        Icons.shopping_cart_outlined,
                        size: 26,
                        color:
                            itemCount > 0
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).iconTheme.color,
                      ),
                      tooltip: 'Keranjang Belanja',
                    ),
                  ),

                  // Badge with improved design
                  if (itemCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  itemCount > 99 ? '99+' : itemCount.toString(),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onError,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
          error:
              (err, stack) => IconButton(
                onPressed: () => context.pushRoute(const CartRoute()),
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Keranjang Belanja',
              ),
          loading:
              () => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.pushRoute(const CartRoute()),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'Keranjang Belanja',
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_getAppBarTitle(context)),
      actions: [
        _buildCartIcon(context),
        const SizedBox(width: 8), // Add some spacing
        Builder(
          builder:
              (innerContext) => IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Open Menu',
                onPressed: () {
                  Scaffold.of(innerContext).openEndDrawer();
                },
              ),
        ),
      ],
      automaticallyImplyLeading: automaticLeading,
      leading: leading,
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
    );
  }
}
