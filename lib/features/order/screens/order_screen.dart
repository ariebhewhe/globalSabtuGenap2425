import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/features/cart/providers/selected_cart_items_provider.dart';
import 'package:jamal/features/order/providers/order_mutation_provider.dart';
import 'package:jamal/shared/widgets/my_app_bar.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

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
