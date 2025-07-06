// lib/screens/admin/add_edit_Product_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qurbanqu/common/custom_button.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/core/config/styles.dart';
import 'package:qurbanqu/model/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? Product;

  const AddEditProductScreen({Key? key, this.Product}) : super(key: key);

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _beratController = TextEditingController();
  final _stokController = TextEditingController();
  final _gambarController = TextEditingController();
  String _selectedJenis = 'Sapi';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.Product != null) {
      // Edit mode - fill form with data
      _namaController.text = widget.Product!.nama;
      _deskripsiController.text = widget.Product!.deskripsi;
      _hargaController.text = widget.Product!.harga.toString();
      _beratController.text = widget.Product!.berat.toString();
      _gambarController.text = widget.Product!.gambar;
      _selectedJenis = widget.Product!.jenis;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _beratController.dispose();
    _gambarController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulasi menyimpan data ke database
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.Product == null
              ? 'Hewan Product berhasil ditambahkan'
              : 'Hewan Product berhasil diperbarui',
        ),
        backgroundColor: AppColors.primary,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.Product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Hewan Product' : 'Tambah Hewan Product'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Form
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Anda sedang mengedit ${widget.Product!.nama}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Nama
              const Text('Informasi Dasar', style: AppStyles.heading2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Hewan',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama hewan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Jenis
              const Text('Jenis Hewan'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedJenis,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Sapi', child: Text('Sapi')),
                      DropdownMenuItem(
                        value: 'Kambing',
                        child: Text('Kambing'),
                      ),
                      DropdownMenuItem(value: 'Domba', child: Text('Domba')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedJenis = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deskripsi
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Spesifikasi
              const Text('Spesifikasi', style: AppStyles.heading2),
              const SizedBox(height: 16),

              // Harga
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Harga harus berupa angka';
                  }
                  if (int.parse(value) <= 0) {
                    return 'Harga harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // lib/screens/admin/add_edit_Product_screen.dart (lanjutan)
              // Berat
              TextFormField(
                controller: _beratController,
                decoration: const InputDecoration(
                  labelText: 'Berat (kg)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Berat tidak boleh kosong';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Berat harus berupa angka';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Berat harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gambar
              const Text('Gambar', style: AppStyles.heading2),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gambarController,
                decoration: const InputDecoration(
                  labelText: 'URL Gambar',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://example.com/gambar.jpg',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'URL gambar tidak boleh kosong';
                  }
                  if (!Uri.tryParse(value)!.isAbsolute) {
                    return 'URL gambar tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Preview gambar
              if (_gambarController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Preview Gambar:'),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _gambarController.text,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text('Gambar tidak valid'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),

              // Tombol Submit
              CustomButton(
                text: isEditing ? 'Simpan Perubahan' : 'Tambah Hewan Product',
                onPressed: _saveProduct,
                isLoading: _isLoading,
                icon: isEditing ? Icons.save : Icons.add,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
