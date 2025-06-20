import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';

@RoutePage()
class UserTabScreen extends StatelessWidget {
  const UserTabScreen({super.key});

  String _formatTitle(String name) {
    var formattedName = name.replaceAll('Route', '');
    if (formattedName.startsWith('User')) {
      formattedName = formattedName.substring(5).trim();
    }

    final titleWords = <String>[];
    final chars = formattedName.characters.toList();
    String currentWord = '';

    if (chars.isEmpty) return '';

    currentWord += chars.first;
    for (int i = 1; i < chars.length; i++) {
      final char = chars[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        titleWords.add(currentWord);
        currentWord = char;
      } else {
        currentWord += char;
      }
    }
    titleWords.add(currentWord);

    return titleWords.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      appBarBuilder: (context, tabsRouter) {
        final currentRouteName = tabsRouter.current.name;

        return UserAppBar(customTitle: _formatTitle(currentRouteName));
      },
      endDrawer: const MyEndDrawer(),
      routes: const [
        HomeRoute(),
        OrdersRoute(),
        TableReservationsRoute(),
        ProfileRoute(),
      ],
      bottomNavigationBuilder: (_, tabsRouter) {
        return NavigationBar(
          selectedIndex: tabsRouter.activeIndex,
          onDestinationSelected: (index) {
            tabsRouter.setActiveIndex(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_outlined),
              selectedIcon: Icon(Icons.receipt),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.dinner_dining_outlined),
              selectedIcon: Icon(Icons.dinner_dining),
              label: 'Reservations',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}
