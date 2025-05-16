import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jamal/shared/widgets/my_app_bar.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(),
      body: MyScreenContainer(
        child: SingleChildScrollView(child: Column(children: [])),
      ),
    );
  }
}
