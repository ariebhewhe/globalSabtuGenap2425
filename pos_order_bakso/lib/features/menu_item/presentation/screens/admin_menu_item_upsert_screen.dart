import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/category/providers/categories_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_provider.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_state.dart';
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

    if (_selectedImageFile == null &&
        hasExistingImage &&
        _deleteExistingImage) {
      ToastUtils.showWarning(
        context: context,
        message: 'Please select a new image or ensure an existing one is kept.',
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;
      final priceString = (formValues['price'] as String).replaceAll('.', '');

      if (isAdding) {
        if (_selectedImageFile == null) {
          ToastUtils.showWarning(
            context: context,
            message: 'Please select an image.',
          );
          return;
        }

        final createMenuItemDto = CreateMenuItemDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String,
          price: double.tryParse(priceString) ?? 0.0,
          categoryId: formValues['categoryId'] as String,
          isAvailable: formValues['isAvailable'] as bool,
          imageFile: _selectedImageFile,
        );

        await ref
            .read(menuItemMutationProvider.notifier)
            .addMenuItem(createMenuItemDto);
      } else {
        final updateMenuItemDto = UpdateMenuItemDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String,
          price: double.tryParse(priceString) ?? 0.0,
          categoryId: formValues['categoryId'] as String,
          isAvailable: formValues['isAvailable'] as bool,
          imageFile: _selectedImageFile,
        );

        final bool deleteImage =
            _formKey.currentState?.fields['deleteExistingImage']?.value ??
            false;

        await ref
            .read(menuItemMutationProvider.notifier)
            .updateMenuItem(
              widget.menuItem!.id,
              updateMenuItemDto,
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
    ref.listen<MenuItemMutationState>(menuItemMutationProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(menuItemMutationProvider.notifier).resetErrorMessage();
      }

      if (next.successMessage != null &&
          (previous?.successMessage != next.successMessage)) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(menuItemMutationProvider.notifier).resetSuccessMessage();

        context.router.pop();
      }
    });

    final categoriesState = ref.watch(categoriesProvider);
    final isAdding = widget.menuItem == null;
    final hasExistingImage = widget.menuItem?.imageUrl != null;
    final mutationState = ref.watch(menuItemMutationProvider);

    final priceFormat = NumberFormat.decimalPattern('id_ID');
    final initialPrice =
        widget.menuItem?.price != null
            ? priceFormat.format(widget.menuItem!.price)
            : '';

    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            initialValue: {
              'name': widget.menuItem?.name ?? '',
              'description': widget.menuItem?.description ?? '',
              'price': initialPrice,
              'categoryId': widget.menuItem?.categoryId,
              'isAvailable': widget.menuItem?.isAvailable ?? true,
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (newValue.text.isEmpty) {
                        return newValue.copyWith(text: '');
                      }
                      final num value = num.tryParse(newValue.text) ?? 0;
                      final String newText = priceFormat.format(value);
                      return newValue.copyWith(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: newText.length,
                        ),
                      );
                    }),
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Price',
                    labelText: 'Price',
                    prefixText: 'Rp ',
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price cannot be empty';
                      }
                      final price = int.tryParse(value.replaceAll('.', ''));
                      if (price == null || price <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ]),
                ),
                const SizedBox(height: 16),
                categoriesState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : categoriesState.errorMessage != null
                    ? Center(
                      child: Text(
                        'Error loading categories: ${categoriesState.errorMessage}',
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
                    const Text('Menu Image', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child:
                            _selectedImageFile != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : (hasExistingImage && !_deleteExistingImage)
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: widget.menuItem!.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (context, url, error) => const Icon(
                                          Icons.fastfood,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                                : const Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
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
                            if (value == true) {
                              _selectedImageFile = null;
                            }
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
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mutationState.isLoading ? null : _submitForm,
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
          ),
        ),
      ),
    );
  }
}
