import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/menu_item/providers/menu_item_mutation_provider.dart';

@RoutePage()
class MenuItemUpsertScreen extends ConsumerStatefulWidget {
  final MenuItemModel? menuItemModel;

  const MenuItemUpsertScreen({super.key, this.menuItemModel});

  @override
  ConsumerState<MenuItemUpsertScreen> createState() =>
      _MenuItemUpsertScreenState();
}

class _MenuItemUpsertScreenState extends ConsumerState<MenuItemUpsertScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _resetForm() {
    _formKey.currentState?.reset();
    // Reset nilai spesifik yang tidak otomatis di-reset
    _formKey.currentState?.fields['isAvailable']?.didChange(true);
    _formKey.currentState?.fields['isVegetarian']?.didChange(false);
    _formKey.currentState?.fields['spiceLevel']?.didChange(0.0);
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      final menuItem = MenuItemModel(
        id: '',
        name: formValues['name'] as String,
        description: formValues['description'] as String,
        price: double.tryParse(formValues['price'].toString()) ?? 0.0,
        category: formValues['category'] as String,
        imageUrl: formValues['imageUrl'] as String,
        isAvailable: formValues['isAvailable'] as bool,
        isVegetarian: formValues['isVegetarian'] as bool,
        spiceLevel: (formValues['spiceLevel'] as double).round(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.menuItemModel != null) {
        await ref
            .read(menuItemMutationProvider.notifier)
            .updateMenuItem(widget.menuItemModel!.id, menuItem);
      } else {
        await ref.read(menuItemMutationProvider.notifier).addMenuItem(menuItem);
      }

      // Reset form fields setelah berhasil
      if (ref.read(menuItemMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, child) {
              final mutationState = ref.watch(menuItemMutationProvider);

              // * Menampilkan SnackBar ketika successMessage tidak null
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mutationState.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mutationState.successMessage!)),
                  );
                  // * Reset successMessage setelah menampilkan SnackBar
                  ref
                      .read(menuItemMutationProvider.notifier)
                      .resetSuccessMessage();
                }

                if (mutationState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mutationState.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                  // * Reset errorMessage setelah menampilkan SnackBar
                  ref
                      .read(menuItemMutationProvider.notifier)
                      .resetErrorMessage();
                }
              });

              return FormBuilder(
                key: _formKey,
                initialValue: {
                  'name': widget.menuItemModel?.name ?? '',
                  'description': widget.menuItemModel?.description ?? '',
                  'price': widget.menuItemModel?.price.toString() ?? '',
                  'category': widget.menuItemModel?.category ?? '',
                  'imageUrl': widget.menuItemModel?.imageUrl ?? '',
                  'isAvailable': widget.menuItemModel?.isAvailable ?? true,
                  'isVegetarian': widget.menuItemModel?.isVegetarian ?? false,
                  'spiceLevel':
                      widget.menuItemModel?.spiceLevel.toDouble() ?? 0.0,
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

                    FormBuilderTextField(
                      name: 'category',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Category',
                        labelText: 'Category',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    FormBuilderTextField(
                      name: 'imageUrl',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Image URL',
                        labelText: 'Image URL',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.url(),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Boolean untuk isAvailable
                    FormBuilderSwitch(
                      name: 'isAvailable',
                      title: const Text('Available'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),

                    // Boolean untuk isVegetarian
                    FormBuilderSwitch(
                      name: 'isVegetarian',
                      title: const Text('Vegetarian'),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Slider untuk spice level
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
                                      widget.menuItemModel != null
                                          ? 'Update'
                                          : 'Submit',
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
