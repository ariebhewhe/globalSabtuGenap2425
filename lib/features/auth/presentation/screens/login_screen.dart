import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

      if (!mounted) return;
      final authState = ref.read(authMutationProvider);

      if (authState.userModel != null) {
        _resetForm();
        if (authState.userModel!.role == Role.admin) {
          context.replaceRoute(const AdminTabRoute());
        } else {
          context.replaceRoute(const UserTabRoute());
        }
      } else if (authState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        ref.read(authMutationProvider.notifier).resetErrorMessage();
      }
    }
  }

  void _loginWithGoogle() async {
    await ref.read(authMutationProvider.notifier).loginWithGoogle();

    if (!mounted) return;
    final authState = ref.read(authMutationProvider);

    if (authState.userModel != null) {
      if (authState.userModel!.role == Role.admin) {
        context.replaceRoute(const AdminTabRoute());
      } else {
        context.replaceRoute(const UserTabRoute());
      }
    } else if (authState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.errorMessage!),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      ref.read(authMutationProvider.notifier).resetErrorMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Login Akun',
          style: context.textStyles.titleLarge?.copyWith(
            color: context.theme.appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
        elevation: context.theme.appBarTheme.elevation,
      ),
      body: MyScreenContainer(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authMutationProvider);

                return Card(
                  elevation: context.cardTheme.elevation,
                  shape: context.cardTheme.shape,
                  color: context.cardTheme.color,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CachedNetworkImage(
                            width: 48,
                            height: 48,
                            imageUrl:
                                "https://i.pinimg.com/736x/bc/38/9a/bc389aea0978b039f923054485688917.jpg",
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: context.colors.primary,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Center(
                                  child: Icon(
                                    Icons.fastfood_outlined,
                                    size: 40,
                                    color: context.colors.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 32),

                          FormBuilderTextField(
                            initialValue: "admin@gmail.com",
                            keyboardType: TextInputType.emailAddress,
                            name: 'email',
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'contoh@email.com',
                              labelText: 'Email',
                              labelStyle: context.textStyles.bodyMedium
                                  ?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                              hintStyle: context.textStyles.bodyMedium
                                  ?.copyWith(
                                    color: context.colors.onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                              prefixIcon: Icon(
                                Icons.alternate_email,
                                color: context.colors.secondary,
                              ),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: "Email tidak boleh kosong",
                              ),
                              FormBuilderValidators.email(
                                errorText: "Format email tidak valid",
                              ),
                            ]),
                          ),
                          const SizedBox(height: 20),

                          FormBuilderTextField(
                            name: 'password',
                            initialValue: "177013",
                            obscureText: true,
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan password',
                              labelText: 'Password',
                              labelStyle: context.textStyles.bodyMedium
                                  ?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                              hintStyle: context.textStyles.bodyMedium
                                  ?.copyWith(
                                    color: context.colors.onSurfaceVariant
                                        .withOpacity(0.7),
                                  ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: context.colors.secondary,
                              ),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(
                                errorText: "Password tidak boleh kosong",
                              ),
                              FormBuilderValidators.minLength(
                                3,
                                errorText: "Password minimal 3 karakter",
                              ),
                            ]),
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: context.elevatedButtonTheme.style
                                  ?.copyWith(
                                    padding: MaterialStateProperty.all(
                                      const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                  ),
                              onPressed:
                                  authState.isLoading ? null : _submitForm,
                              child:
                                  authState.isLoading
                                      ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                context.colors.onPrimary,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        'Login',
                                        style: context.textStyles.labelLarge
                                            ?.copyWith(
                                              fontSize: 16,
                                              color: context.colors.onPrimary,
                                            ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Image.asset(
                                'assets/images/google_logo.png',
                                height: 22,
                                width: 22,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: context.colors.primary,
                                    ),
                              ),
                              label: Text(
                                'Login dengan Google',
                                style: context.textStyles.labelLarge?.copyWith(
                                  fontSize: 16,
                                  color: context.colors.primary,
                                ),
                              ),
                              onPressed:
                                  authState.isLoading ? null : _loginWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.surface,
                                foregroundColor: context.colors.primary,
                                side: BorderSide(
                                  color: context.colors.outline.withOpacity(
                                    0.5,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: context.elevatedButtonTheme.style?.shape
                                    ?.resolve({}),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Belum punya akun? ",
                                style: context.textStyles.bodyMedium,
                              ),
                              TextButton(
                                onPressed:
                                    () => context.pushRoute(
                                      const RegisterRoute(),
                                    ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: context.colors.primary,
                                ),
                                child: Text(
                                  'Daftar di sini',
                                  style: context.textStyles.labelLarge
                                      ?.copyWith(
                                        color: context.colors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
