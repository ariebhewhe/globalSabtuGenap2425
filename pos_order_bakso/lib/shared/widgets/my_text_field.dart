import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class MyTextField extends StatelessWidget {
  final String name;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const MyTextField({
    super.key,
    required this.name,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(name: name);
  }
}
