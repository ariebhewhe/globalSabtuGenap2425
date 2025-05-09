import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/menu_item_model.dart';
import 'package:jamal/features/user/menu_item/providers/menu_item_mutation_provider.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isAvailable = true;
  bool _isVegetarian = false;
  double _spiceLevel = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _reset() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _categoryController.clear();
    _imageUrlController.clear();
    setState(() {
      _isAvailable = true;
      _isVegetarian = false;
      _spiceLevel = 0;
    });
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Name',
                      label: Text('Name'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Description',
                      label: Text('Description'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    keyboardType: TextInputType.number,
                    controller: _priceController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Price',
                      label: Text('Price'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Category',
                      label: Text('Category'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Image URL',
                      label: Text('Image URL'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Boolean for isAvailable
                  SwitchListTile(
                    title: const Text('Available'),
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),

                  // Boolean for isVegetarian
                  SwitchListTile(
                    title: const Text('Vegetarian'),
                    value: _isVegetarian,
                    onChanged: (value) {
                      setState(() {
                        _isVegetarian = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Slider for spice level
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Text('Spice Level'),
                  ),

                  Slider(
                    value: _spiceLevel,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _spiceLevel.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _spiceLevel = value;
                      });
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            mutationState.isLoading
                                ? null
                                : () async {
                                  final newMenuItem = MenuItemModel(
                                    id: '',
                                    name: _nameController.text,
                                    description: _descriptionController.text,
                                    price:
                                        double.tryParse(
                                          _priceController.text,
                                        ) ??
                                        0.0,
                                    category: _categoryController.text,
                                    imageUrl: _imageUrlController.text,
                                    isAvailable: _isAvailable,
                                    isVegetarian: _isVegetarian,
                                    spiceLevel: _spiceLevel.round(),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  await ref
                                      .read(menuItemMutationProvider.notifier)
                                      .addMenuItem(newMenuItem);

                                  // Reset form fields setelah berhasil
                                  if (ref
                                          .read(menuItemMutationProvider)
                                          .successMessage !=
                                      null) {
                                    _reset();
                                  }
                                },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child:
                              mutationState.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Submit'),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
