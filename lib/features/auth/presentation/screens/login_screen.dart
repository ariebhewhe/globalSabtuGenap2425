import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _resetForm() {
    _formKey.currentState?.reset();
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      await ref
          .read(authProvider.notifier)
          .loginWithEmail(
            email: formValues['mail'] as String,
            password: formValues['password'] as String,
          );

      if (ref.read(authProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);

              // * Menampilkan SnackBar ketika successMessage tidak null
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (authState.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(authState.successMessage!)),
                  );
                  // * Reset successMessage setelah menampilkan SnackBar
                  ref.read(authProvider.notifier).resetSuccessMessage();
                }

                if (authState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authState.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // * Reset errorMessage setelah menampilkan SnackBar
                  ref.read(authProvider.notifier).resetErrorMessage();
                }
              });

              return FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Email',
                        labelText: 'Email',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                        FormBuilderValidators.minLength(3),
                        FormBuilderValidators.maxLength(50),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: 'password',
                      keyboardType: TextInputType.multiline,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'password',
                        labelText: 'password',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(3),
                        FormBuilderValidators.maxLength(255),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child:
                              authState.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Login'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (authState.isLoading) {
                            return null;
                          }
                          ref.read(authProvider.notifier).loginWithGoogle();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child:
                              authState.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Login with google'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
