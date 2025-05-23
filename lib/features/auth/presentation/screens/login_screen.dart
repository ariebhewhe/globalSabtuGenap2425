import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
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
          .read(authMutationProvider.notifier)
          .loginWithEmail(
            email: formValues['email'] as String,
            password: formValues['password'] as String,
          );

      final authState = ref.read(authMutationProvider);

      if (mounted && authState.userModel != null) {
        _resetForm();

        if (authState.userModel!.role == Role.admin) {
          context.replaceRoute(const AdminTabRoute());
        } else {
          context.replaceRoute(const UserTabRoute());
        }
      } else if (mounted && authState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(authMutationProvider.notifier).resetErrorMessage();
      }
    }
  }

  void _loginWithGoogle() async {
    await ref.read(authMutationProvider.notifier).loginWithGoogle();
    final authState = ref.read(authMutationProvider);

    if (mounted && authState.userModel != null) {
      if (authState.userModel!.role == Role.admin) {
        context.replaceRoute(const AdminTabRoute());
      } else {
        context.replaceRoute(const UserTabRoute());
      }
    } else if (mounted && authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      ref.read(authMutationProvider.notifier).resetErrorMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: MyScreenContainer(
        child: Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authMutationProvider);

            return FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FormBuilderTextField(
                    initialValue: "rizzthenotable@gmail.com",
                    keyboardType: TextInputType.emailAddress,
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
                    initialValue: "177013",
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
                      onPressed: authState.isLoading ? null : _loginWithGoogle,
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
    );
  }
}
