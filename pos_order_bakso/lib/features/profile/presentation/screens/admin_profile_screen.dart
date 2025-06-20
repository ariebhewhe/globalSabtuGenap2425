import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/user_model.dart';
import 'package:jamal/features/user/providers/user_mutation_provider.dart';
import 'package:jamal/features/auth/auth_provider.dart';
import 'package:jamal/features/user/providers/user_mutation_state.dart';

@RoutePage()
class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _passwordFormKey = GlobalKey<FormBuilderState>();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  void _toggleEditProfile() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
      if (!_isEditingProfile) {
        _selectedImageFile = null;
      }
    });
  }

  void _toggleChangePassword() {
    setState(() {
      _isChangingPassword = !_isChangingPassword;
    });
  }

  void _submitProfileUpdate(UserModel currentUser) async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      final updatedUser = UserModel(
        id: currentUser.id,
        username: formValues['username'] as String,
        email: formValues['email'] as String,
        phoneNumber: formValues['phoneNumber'] as String?,
        address: formValues['address'] as String?,
        profilePicture: currentUser.profilePicture,
        role: currentUser.role,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(userMutationProvider.notifier)
          .updateCurrentUser(updatedUser, imageFile: _selectedImageFile);

      if (ref.read(userMutationProvider).successMessage != null) {
        _toggleEditProfile();
      }
    }
  }

  void _submitPasswordChange() async {
    final isValid = _passwordFormKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _passwordFormKey.currentState!.value;
      final newPassword = formValues['newPassword'] as String;

      await ref
          .read(userMutationProvider.notifier)
          .updateUserPassword(newPassword);

      if (ref.read(userMutationProvider).successMessage != null) {
        _passwordFormKey.currentState?.reset();
        _toggleChangePassword();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final mutationState = ref.watch(userMutationProvider);

    ref.listen<UserMutationState>(userMutationProvider, (previous, next) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(userMutationProvider.notifier).resetErrorMessage();
      }

      if (next.successMessage != null &&
          (previous?.successMessage != next.successMessage)) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(userMutationProvider.notifier).resetSuccessMessage();
      }
    });

    return Scaffold(
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user data available'));
          }

          final isSubmitting = mutationState.isLoading;

          return AbsorbPointer(
            absorbing: isSubmitting,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Profile Picture
                          GestureDetector(
                            onTap:
                                _isEditingProfile && !isSubmitting
                                    ? _pickImage
                                    : null,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      _selectedImageFile != null
                                          ? FileImage(_selectedImageFile!)
                                          : (user.profilePicture != null
                                                  ? NetworkImage(
                                                    user.profilePicture!,
                                                  )
                                                  : null)
                                              as ImageProvider?,
                                  child:
                                      user.profilePicture == null &&
                                              _selectedImageFile == null
                                          ? const Icon(Icons.person, size: 40)
                                          : null,
                                ),
                                if (_isEditingProfile)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role.name.toUpperCase(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit Button
                          IconButton(
                            onPressed: isSubmitting ? null : _toggleEditProfile,
                            icon: Icon(
                              _isEditingProfile ? Icons.close : Icons.edit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Form
                  if (_isEditingProfile) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FormBuilder(
                          key: _formKey,
                          initialValue: {
                            'username': user.username,
                            'email': user.email,
                            'phoneNumber': user.phoneNumber ?? '',
                            'address': user.address ?? '',
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Profile',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                name: 'username',
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.minLength(2),
                                  FormBuilderValidators.maxLength(100),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                name: 'email',
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.required(),
                                  FormBuilderValidators.email(),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                name: 'phoneNumber',
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.minLength(10),
                                  FormBuilderValidators.maxLength(15),
                                ]),
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                name: 'address',
                                decoration: const InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                                maxLines: 3,
                                validator: FormBuilderValidators.compose([
                                  FormBuilderValidators.maxLength(500),
                                ]),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      isSubmitting
                                          ? null
                                          : () => _submitProfileUpdate(user),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child:
                                        isSubmitting
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'Update Profile',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Profile Details View
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              Icons.person,
                              'Full Name',
                              user.username,
                            ),
                            _buildDetailRow(Icons.email, 'Email', user.email),
                            if (user.phoneNumber != null &&
                                user.phoneNumber!.isNotEmpty)
                              _buildDetailRow(
                                Icons.phone,
                                'Phone',
                                user.phoneNumber!,
                              ),
                            if (user.address != null &&
                                user.address!.isNotEmpty)
                              _buildDetailRow(
                                Icons.location_on,
                                'Address',
                                user.address!,
                              ),
                            _buildDetailRow(
                              Icons.calendar_today,
                              'Member Since',
                              _formatDate(user.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Change Password Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Change Password',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              TextButton(
                                onPressed:
                                    isSubmitting ? null : _toggleChangePassword,
                                child: Text(
                                  _isChangingPassword ? 'Cancel' : 'Change',
                                ),
                              ),
                            ],
                          ),
                          if (_isChangingPassword) ...[
                            const SizedBox(height: 16),
                            FormBuilder(
                              key: _passwordFormKey,
                              child: Column(
                                children: [
                                  FormBuilderTextField(
                                    name: 'currentPassword',
                                    decoration: const InputDecoration(
                                      labelText: 'Current Password',
                                      prefixIcon: Icon(Icons.lock),
                                    ),
                                    obscureText: true,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                    ]),
                                  ),
                                  const SizedBox(height: 16),
                                  FormBuilderTextField(
                                    name: 'newPassword',
                                    decoration: const InputDecoration(
                                      labelText: 'New Password',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    obscureText: true,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      FormBuilderValidators.minLength(6),
                                    ]),
                                  ),
                                  const SizedBox(height: 16),
                                  FormBuilderTextField(
                                    name: 'confirmPassword',
                                    decoration: const InputDecoration(
                                      labelText: 'Confirm New Password',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                    obscureText: true,
                                    validator: FormBuilderValidators.compose([
                                      FormBuilderValidators.required(),
                                      (val) {
                                        final newPassword =
                                            _passwordFormKey
                                                .currentState
                                                ?.fields['newPassword']
                                                ?.value;
                                        if (val != newPassword) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ]),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          isSubmitting
                                              ? null
                                              : _submitPasswordChange,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child:
                                            isSubmitting
                                                ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                                : const Text(
                                                  'Update Password',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
