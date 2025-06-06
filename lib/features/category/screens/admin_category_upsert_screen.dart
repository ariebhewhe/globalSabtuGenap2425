import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/category_model.dart';
import 'package:jamal/features/category/providers/category_mutation_provider.dart';
import 'package:jamal/features/category/providers/category_mutation_state.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
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

    final bool isAdding = widget.category == null;
    final bool hasExistingImage = widget.category?.picture != null;

    if (_selectedImageFile == null && !hasExistingImage && !isAdding) {
      ToastUtils.showWarning(
        context: context,
        message: 'Please select a new image or ensure an existing one is kept.',
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      if (isAdding) {
        if (_selectedImageFile == null) {
          ToastUtils.showWarning(
            context: context,
            message: 'Please select an image.',
          );
          return;
        }

        final createCategoryDto = CreateCategoryDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String?,
          pictureFile: _selectedImageFile,
        );

        await ref
            .read(categoryMutationProvider.notifier)
            .addCategory(createCategoryDto);
      } else {
        final updateCategoryDto = UpdateCategoryDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String?,
          pictureFile: _selectedImageFile,
        );

        final bool deleteImage =
            _formKey.currentState?.fields['deleteExistingImage']?.value ??
            false;

        await ref
            .read(categoryMutationProvider.notifier)
            .updateCategory(
              widget.category!.id,
              updateCategoryDto,
              deleteExistingImage: deleteImage,
            );
      }

      if (ref.read(categoryMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(categoryMutationProvider);
    final isSubmitting = mutationState.isLoading;

    ref.listen<CategoryMutationState>(categoryMutationProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(categoryMutationProvider.notifier).resetErrorMessage();
      }

      if (next.successMessage != null &&
          (previous?.successMessage != next.successMessage)) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(categoryMutationProvider.notifier).resetSuccessMessage();

        context.router.pop();
      }
    });

    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: AbsorbPointer(
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
                            border: Border.all(color: context.colors.primary),
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
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
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
          ),
        ),
      ),
    );
  }
}
