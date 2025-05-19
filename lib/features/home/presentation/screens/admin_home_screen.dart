import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/features/menu_item/providers/menu_items_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/admin_end_drawer.dart';

@RoutePage()
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Consumer(
          builder: (context, ref, child) {
            final menuItemsState = ref.watch(menuItemsProvider);

            if (menuItemsState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (menuItemsState.errorMessage != null) {
              return Center(child: Text(menuItemsState.errorMessage!));
            } else {
              return ListView.builder(
                itemCount: menuItemsState.menuItems.length,
                itemBuilder: (context, index) {
                  final menuItem = menuItemsState.menuItems[index];
                  return ListTile(title: Text(menuItem.name));
                },
              );
            }
          },
        ),
      ),
    );
  }
}
