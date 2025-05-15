import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/features/auth/auth_provider.dart';

class MyEndDrawer extends StatelessWidget {
  const MyEndDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> drawerItems = [
      {'icon': Icons.person, 'title': 'Profile', 'route': const ProfileRoute()},
      {
        'icon': Icons.food_bank,
        'title': 'Foods',
        'route': const MenuItemsRoute(),
      },
    ];

    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDrawerHeader(context),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    children:
                        drawerItems.map((item) {
                          return _buildDrawerItem(
                            context,
                            icon: item['icon'],
                            title: item['title'],
                            route: item['route'],
                            onTap: () {
                              Navigator.of(context).pop();
                              context.router.push(item['route']);
                            },
                          );
                        }).toList(),
                  ),
                ),

                Consumer(
                  builder: (context, ref, child) {
                    final authState = ref.watch(authStateProvider);

                    return authState.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                      data: (user) {
                        final bool isAuth = user != null;

                        return ElevatedButton(
                          onPressed: () {
                            if (isAuth) {
                              ref.read(authMutationProvider.notifier).logout();
                            } else {
                              context.router.pushAll([const LoginRoute()]);
                            }
                          },
                          child: Text(isAuth ? "Logout" : "Login"),
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(16.0),
          bottomLeft: Radius.circular(16.0),
        ),
      ),
      child: Consumer(
        builder: (context, ref, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Main Menu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://i.pinimg.com/474x/36/55/14/36551495c272fdd6d9205975b1badb83.jpg',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
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
                          'user.username',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'user.email',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'user.role',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required dynamic route,
    required VoidCallback onTap,
  }) {
    bool isActive = false;

    if (route is PageRouteInfo) {
      final currentRouteName = context.router.current.name;

      isActive = currentRouteName == route.routeName;
    }

    return Card(
      color:
          isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).cardColor,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        onTap: onTap,
        dense: true,
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
