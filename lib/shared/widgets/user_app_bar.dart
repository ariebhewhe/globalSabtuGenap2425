import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(_getAppBarTitle(context)),
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final distinctTotalMenuItemsInCart = ref.watch(
              distinctCartItemCountProvider,
            );

            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  onPressed: () => context.pushRoute(const CartRoute()),
                  icon: const Icon(Icons.shopping_cart),
                ),
                distinctTotalMenuItemsInCart.when(
                  data: (data) {
                    return Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        child: Text(
                          data.toString(),
                          style: TextStyle(color: context.colors.tertiary),
                        ),
                      ),
                    );
                  },
                  error: (err, stack) => const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
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
