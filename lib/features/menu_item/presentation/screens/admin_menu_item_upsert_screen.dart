import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminMenuItemUpsertScreen extends ConsumerStatefulWidget {
  final MenuItemModel? menuItem;

  const AdminMenuItemUpsertScreen({super.key, this.menuItem});

  @override
  ConsumerState<AdminMenuItemUpsertScreen> createState() =>
      _AdminMenuItemUpsertScreenState();
}

class _AdminMenuItemUpsertScreenState
    extends ConsumerState<AdminMenuItemUpsertScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _deleteExistingImage = false;

  @override
  void initState() {
    super.initState();

    if (widget.menuItem != null && widget.menuItem!.imageUrl != null) {
      _deleteExistingImage = false;
    } else {
      _deleteExistingImage = true;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);

        if (widget.menuItem != null && widget.menuItem!.imageUrl != null) {
          _formKey.currentState?.fields['deleteExistingImage']?.didChange(
            false,
          );
          _deleteExistingImage = false;
        }
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _formKey.currentState?.fields['isAvailable']?.didChange(true);
    _formKey.currentState?.fields['isVegetarian']?.didChange(false);
    _formKey.currentState?.fields['spiceLevel']?.didChange(0.0);
    setState(() {
      _selectedImageFile = null;
      if (widget.menuItem != null && widget.menuItem!.imageUrl != null) {
        _deleteExistingImage = false;
      } else {
        _deleteExistingImage = true;
      }
    });
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    final bool isAdding = widget.menuItem == null;
    final bool hasExistingImage = widget.menuItem?.imageUrl != null;

    if (_selectedImageFile == null && !hasExistingImage && !isAdding) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select a new image or ensure an existing one is kept.',
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    if (isAdding && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      if (isAdding) {
        final createMenuItemDto = CreateMenuItemDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String,
          price: double.tryParse(formValues['price'].toString()) ?? 0.0,
          categoryId: formValues['categoryId'] as String,
          isAvailable: formValues['isAvailable'] as bool,
          isVegetarian: formValues['isVegetarian'] as bool,
          spiceLevel: (formValues['spiceLevel'] as int).round(),
          imageUrl: null,
        );

        await ref
            .read(menuItemMutationProvider.notifier)
            .addMenuItem(createMenuItemDto, imageFile: _selectedImageFile);
      } else {
        final updateMenuItemDto = UpdateMenuItemDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String,
          price: double.tryParse(formValues['price'].toString()) ?? 0.0,
          categoryId: formValues['categoryId'] as String,
          isAvailable: formValues['isAvailable'] as bool,
          isVegetarian: formValues['isVegetarian'] as bool,
          spiceLevel: (formValues['spiceLevel'] as double).round(),
        );

        final bool deleteImage =
            _formKey.currentState?.fields['deleteExistingImage']?.value ??
            false;

        await ref
            .read(menuItemMutationProvider.notifier)
            .updateMenuItem(
              widget.menuItem!.id,
              updateMenuItemDto,
              imageFile: _selectedImageFile,
              deleteExistingImage: deleteImage,
            );
      }

      if (ref.read(menuItemMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);
    final isAdding = widget.menuItem == null;
    final hasExistingImage = widget.menuItem?.imageUrl != null;

    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, child) {
              final mutationState = ref.watch(menuItemMutationProvider);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mutationState.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mutationState.successMessage!)),
                  );
                  ref
                      .read(menuItemMutationProvider.notifier)
                      .resetSuccessMessage();
                }

                if (mutationState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mutationState.errorMessage!),
                      backgroundColor: context.colors.error,
                    ),
                  );
                  ref
                      .read(menuItemMutationProvider.notifier)
                      .resetErrorMessage();
                }
              });

              return FormBuilder(
                key: _formKey,
                initialValue: {
                  'name': widget.menuItem?.name ?? '',
                  'description': widget.menuItem?.description ?? '',
                  'price': widget.menuItem?.price.toString() ?? '',
                  'categoryId': widget.menuItem?.categoryId ?? '',
                  'isAvailable': widget.menuItem?.isAvailable ?? true,
                  'isVegetarian': widget.menuItem?.isVegetarian ?? false,
                  'spiceLevel': widget.menuItem?.spiceLevel.toDouble() ?? 0.0,
                  'deleteExistingImage': false,
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

                    FormBuilderTextField(
                      name: 'price',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Price',
                        labelText: 'Price',
                        prefixText: '\$ ',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(0.1),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    categoriesState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : categoriesState.errorMessage != null
                        ? Center(
                          child: Text(
                            'Error loading categories: ${categoriesState.errorMessage}',
                            style: TextStyle(color: context.colors.error),
                          ),
                        )
                        : FormBuilderDropdown<String>(
                          name: 'categoryId',
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            hintText: 'Pilih kategori',
                          ),
                          items:
                              categoriesState.categories
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category.id,
                                      child: Row(
                                        children: [
                                          if (category.picture != null) ...[
                                            CachedNetworkImage(
                                              imageUrl: category.picture!,
                                              width: 24,
                                              height: 24,
                                              fit: BoxFit.cover,
                                              placeholder:
                                                  (context, url) => const Icon(
                                                    Icons.category,
                                                    size: 24,
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.category,
                                                        size: 24,
                                                      ),
                                            ),
                                          ],
                                          const SizedBox(width: 8),
                                          Text(category.name),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                          validator: FormBuilderValidators.required(
                            errorText: 'Silakan pilih kategori',
                          ),
                        ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Menu Image',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: context.colors.secondary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.colors.secondary,
                              ),
                            ),
                            child:
                                _selectedImageFile != null
                                    ? Image.file(
                                      _selectedImageFile!,
                                      fit: BoxFit.cover,
                                    )
                                    : hasExistingImage && !_deleteExistingImage
                                    ? Image.network(
                                      widget.menuItem!.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.fastfood,
                                            size: 50,
                                            color: context.colors.secondary,
                                          ),
                                    )
                                    : Icon(
                                      Icons.add_a_photo,
                                      size: 50,
                                      color: context.colors.secondary,
                                    ),
                          ),
                        ),
                        if (!isAdding && hasExistingImage)
                          FormBuilderSwitch(
                            name: 'deleteExistingImage',
                            title: const Text('Delete Existing Image'),
                            initialValue: _deleteExistingImage,
                            onChanged: (value) {
                              setState(() {
                                _deleteExistingImage = value ?? false;
                              });
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    FormBuilderSwitch(
                      name: 'isAvailable',
                      title: const Text('Available'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),

                    FormBuilderSwitch(
                      name: 'isVegetarian',
                      title: const Text('Vegetarian'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 8),
                      child: Text('Spice Level'),
                    ),

                    FormBuilderSlider(
                      name: 'spiceLevel',
                      min: 0,
                      max: 5,
                      divisions: 5,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      valueTransformer: (value) => value?.round(),
                      displayValues: DisplayValues.current,
                      initialValue: 0,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              mutationState.isLoading ? null : _submitForm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child:
                                mutationState.isLoading
                                    ? const CircularProgressIndicator()
                                    : Text(
                                      isAdding
                                          ? 'Add Menu Item'
                                          : 'Update Menu Item',
                                    ),
                          ),
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
