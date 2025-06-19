import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/shared/providers/theme_provider.dart';

class MyEndDrawer extends StatelessWidget {
  const MyEndDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> userDrawerItems = [
      {
        'icon': Icons.person,
        'title': 'Profile',
        'route': const ProfileRoute(),
        'tabIndex': 3,
      },
      {
        'icon': Icons.food_bank,
        'title': 'Foods',
        'route': const MenuItemsRoute(),
        'tabIndex': null,
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Orders',
        'route': const OrdersRoute(),
        'tabIndex': 1,
      },
    ];

    final List<Map<String, dynamic>> adminDrawerItems = [
      {
        'icon': Icons.food_bank,
        'title': 'Menu',
        'route': const AdminMenuItemsRoute(),
      },
      {
        'icon': Icons.category,
        'title': 'Categories',
        'route': const AdminCategoriesRoute(),
      },
      {
        'icon': Icons.payment,
        'title': 'Payment Method',
        'route': const AdminPaymentMethodsRoute(),
      },
      {
        'icon': Icons.table_bar,
        'title': 'Restaurant Table',
        'route': const AdminRestaurantTablesRoute(),
      },
      {
        'icon': Icons.receipt_long,
        'title': 'All Orders',
        'route': const AdminOrdersRoute(),
      },
      {
        'icon': Icons.receipt,
        'title': 'All Table Reservations',
        'route': const AdminTableReservationsRoute(),
      },
    ];

    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final currentUserState = ref.watch(currentUserProvider);

            return currentUserState.when(
              data: (userData) {
                final bool isAdmin = userData?.role == Role.admin;
                final drawerItems =
                    isAdmin ? adminDrawerItems : userDrawerItems;

                // Ambil TabsRouter hanya jika kita berada dalam konteks user (ada AutoTabsScaffold)
                // Try-catch untuk keamanan jika drawer dipanggil di luar TabsRouter
                TabsRouter? tabsRouter;
                if (!isAdmin) {
                  try {
                    tabsRouter = AutoTabsRouter.of(context);
                  } catch (_) {
                    tabsRouter = null; // Abaikan jika tidak ditemukan
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDrawerHeader(context, ref, userData),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        children: [
                          ...drawerItems.map((item) {
                            return _buildDrawerItem(
                              context,
                              icon: item['icon'],
                              title: item['title'],
                              route: item['route'],
                              onTap: () {
                                // Selalu tutup drawer terlebih dahulu
                                Navigator.of(context).pop();

                                if (isAdmin) {
                                  // Logika untuk Admin: selalu push
                                  context.router.push(item['route']);
                                } else {
                                  // Logika untuk User: periksa tabIndex
                                  final tabIndex = item['tabIndex'] as int?;
                                  if (tabIndex != null && tabsRouter != null) {
                                    // Jika item adalah tab, ganti index
                                    tabsRouter.setActiveIndex(tabIndex);
                                  } else {
                                    // Jika bukan tab, push ke root router
                                    context.router.root.push(item['route']);
                                  }
                                }
                              },
                            );
                          }).toList(),
                          _buildThemeSelector(context, ref),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildAuthButton(context, ref, userData),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: context.theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading user data',
                          style: context.theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: context.theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(currentUserProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic userData,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(16.0),
          bottomLeft: Radius.circular(16.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Main Menu',
                style: context.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colorScheme.primary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: context.theme.colorScheme.surface,
                  foregroundColor: context.theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (userData != null) ...[
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.theme.colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl:
                          userData.profilePicture ??
                          'https://i.pinimg.com/474x/36/55/14/36551495c272fdd6d9205975b1badb83.jpg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            width: 48,
                            height: 48,
                            color: context.theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => CircleAvatar(
                            backgroundColor: context.theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            child: Icon(
                              Icons.person,
                              color: context.theme.colorScheme.primary,
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.username ?? "User",
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userData.email ?? "user@example.com",
                        style: context.theme.textTheme.bodyMedium?.copyWith(
                          color: context.theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(userData.role, context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getRoleIcon(userData.role),
                    size: 16,
                    color: context.theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getRoleDisplayName(userData.role),
                    style: context.theme.textTheme.bodySmall?.copyWith(
                      color: context.theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.theme.colorScheme.primary.withValues(
                    alpha: 0.3,
                  ),
                  child: Icon(
                    Icons.person,
                    color: context.theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest User',
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Please login to access all features',
                        style: context.theme.textTheme.bodyMedium?.copyWith(
                          color: context.theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthButton(
    BuildContext context,
    WidgetRef ref,
    dynamic userData,
  ) {
    final bool isAuthenticated = userData != null;
    return ElevatedButton.icon(
      onPressed: () {
        if (isAuthenticated) {
          _showLogoutDialog(context, ref);
        } else {
          Navigator.of(context).pop();
          context.replaceRoute(const LoginRoute());
        }
      },
      icon: Icon(isAuthenticated ? Icons.logout : Icons.login),
      label: Text(isAuthenticated ? "Logout" : "Login"),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isAuthenticated
                ? context.theme.colorScheme.tertiary
                : context.theme.colorScheme.primary,
        foregroundColor: context.theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Logout', style: context.theme.textTheme.titleLarge),
          content: Text(
            'Are you sure you want to logout?',
            style: context.theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                ref.read(authMutationProvider.notifier).logout();
                if (context.mounted) {
                  context.replaceRoute(const LoginRoute());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.colorScheme.error,
                foregroundColor: context.theme.colorScheme.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required PageRouteInfo route,
    required VoidCallback onTap,
  }) {
    bool isActive = false;
    // Cek rute aktif. Untuk tab, context.router.current merujuk pada tab router
    final currentRouteName = context.router.current.name;
    isActive = currentRouteName == route.routeName;

    return Card(
      color:
          isActive
              ? context.theme.colorScheme.primary.withValues(alpha: 0.1)
              : context.theme.cardColor,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isActive
                  ? context.theme.colorScheme.primary
                  : context.theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        title: Text(
          title,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: isActive ? context.theme.colorScheme.primary : null,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: context.theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        leading: Icon(
          Icons.palette_outlined,
          color: context.theme.colorScheme.primary,
        ),
        title: Text('Theme', style: context.theme.textTheme.bodyMedium),
        subtitle: Text(
          _getThemeDisplayName(currentTheme),
          style: context.theme.textTheme.bodySmall?.copyWith(
            color: context.theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.expand_more,
          color: context.theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
        children: [
          _buildThemeOption(
            context,
            ref,
            ThemeMode.system,
            Icons.settings_suggest_outlined,
            'System Default',
            'Mengikuti pengaturan sistem',
            currentTheme == ThemeMode.system,
          ),
          _buildThemeOption(
            context,
            ref,
            ThemeMode.light,
            Icons.light_mode_outlined,
            'Light Mode',
            'Tema terang',
            currentTheme == ThemeMode.light,
          ),
          _buildThemeOption(
            context,
            ref,
            ThemeMode.dark,
            Icons.dark_mode_outlined,
            'Dark Mode',
            'Tema gelap',
            currentTheme == ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color:
            isSelected
                ? context.theme.colorScheme.primary
                : context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
        size: 20,
      ),
      title: Text(
        title,
        style: context.theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? context.theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.theme.textTheme.bodySmall?.copyWith(
          color:
              isSelected
                  ? context.theme.colorScheme.primary.withValues(alpha: 0.8)
                  : context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
      trailing:
          isSelected
              ? Icon(
                Icons.check_circle,
                color: context.theme.colorScheme.primary,
                size: 20,
              )
              : null,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
        ToastUtils.showSuccess(
          context: context,
          message: "Tema berhasil diubah",
        );
      },
    );
  }

  Color _getRoleColor(Role? role, BuildContext context) {
    switch (role) {
      case Role.admin:
        return context.theme.colorScheme.error;
      case Role.user:
      default:
        return context.theme.colorScheme.primary;
    }
  }

  IconData _getRoleIcon(Role? role) {
    switch (role) {
      case Role.admin:
        return Icons.admin_panel_settings;
      case Role.user:
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName(Role? role) {
    switch (role) {
      case Role.admin:
        return 'Administrator';
      case Role.user:
        return 'User';
      default:
        return 'Guest';
    }
  }

  String _getThemeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }
}
