import 'dart:io';
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/features/category/providers/category_mutation_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminCategoryUpsertScreen extends ConsumerStatefulWidget {
  final CategoryModel? category;

  const AdminCategoryUpsertScreen({super.key, this.category});

  @override
  ConsumerState<AdminCategoryUpsertScreen> createState() =>
      _AdminCategoryUpsertScreenState();
}

class _AdminCategoryUpsertScreenState
    extends ConsumerState<AdminCategoryUpsertScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedImageFile = null;
    });
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (widget.category == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a picture image.'),
          backgroundColor: context.theme.colorScheme.error,
        ),
      );
      return;
    }

    if (widget.category != null &&
        widget.category!.picture == null &&
        _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select a picture image or ensure an existing one exists.',
          ),
          backgroundColor: context.theme.colorScheme.error,
        ),
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      final category = CategoryModel(
        id: widget.category?.id ?? '',
        name: formValues['name'] as String,
        description: formValues['description'] as String?,
        picture: widget.category?.picture,
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: widget.category?.updatedAt ?? DateTime.now(),
      );

      if (widget.category != null) {
        await ref
            .read(categoryMutationProvider.notifier)
            .updateCategory(
              widget.category!.id,
              category,
              imageFile: _selectedImageFile,
            );
      } else {
        await ref
            .read(categoryMutationProvider.notifier)
            .addCategory(category, imageFile: _selectedImageFile);
        context.replaceRoute(const AdminCategoriesRoute());
      }

      if (ref.read(categoryMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, child) {
              final mutationState = ref.watch(categoryMutationProvider);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mutationState.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mutationState.successMessage!)),
                  );

                  ref
                      .read(categoryMutationProvider.notifier)
                      .resetSuccessMessage();
                }

                if (mutationState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mutationState.errorMessage!),
                      backgroundColor: context.theme.colorScheme.error,
                    ),
                  );

                  ref
                      .read(categoryMutationProvider.notifier)
                      .resetErrorMessage();
                }
              });

              final isSubmitting = mutationState.isLoading;

              return AbsorbPointer(
                absorbing: isSubmitting,
                child: FormBuilder(
                  key: _formKey,

                  initialValue: {
                    'name': widget.category?.name ?? '',
                    'description': widget.category?.description ?? '',
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Name',
                          labelText: 'Name',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(3),
                          FormBuilderValidators.maxLength(50),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderTextField(
                        name: 'description',
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Description',
                          labelText: 'Description',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(10),
                          FormBuilderValidators.maxLength(500),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Logo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: isSubmitting ? null : _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context.colors.primary,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child:
                                    _selectedImageFile != null
                                        ? Image.file(
                                          _selectedImageFile!,
                                          fit: BoxFit.cover,
                                        )
                                        : (widget.category?.picture != null
                                            ? Image.network(
                                              widget.category!.picture!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(Icons.error),
                                            )
                                            : Icon(
                                              Icons.camera_alt,
                                              size: 40,
                                              color: context.colors.secondary,
                                            )),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : _submitForm,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child:
                                  isSubmitting
                                      ? const CircularProgressIndicator()
                                      : Text(
                                        widget.category != null
                                            ? 'Update'
                                            : 'Submit',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
