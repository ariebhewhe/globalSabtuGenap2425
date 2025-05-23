import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';

@RoutePage()
class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppBar(),
      body: MyScreenContainer(child: SingleChildScrollView(child: Column())),
    );
  }
}
