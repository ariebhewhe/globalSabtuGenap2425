import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';

@RoutePage()
class AdminTabScreen extends StatelessWidget {
  const AdminTabScreen({super.key});

  // Helper untuk memformat nama rute menjadi judul yang rapi
  String _formatTitle(String name) {
    var formattedName = name.replaceAll('Route', '');
    if (formattedName.startsWith('Admin')) {
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

        return AdminAppBar(customTitle: _formatTitle(currentRouteName));
      },
      endDrawer: const MyEndDrawer(),
      routes: const [AdminHomeRoute(), AdminProfileRoute()],
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
