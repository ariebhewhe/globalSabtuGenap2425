import 'package:flutter/material.dart';

class MyScreenContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MyScreenContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Padding(padding: padding, child: child));
  }
}
