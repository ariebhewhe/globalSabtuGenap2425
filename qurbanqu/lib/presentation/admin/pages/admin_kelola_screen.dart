import 'dart:io'; // Import for File class
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qurbanqu/main.dart'; // Assuming supabase is initialized here
import 'package:qurbanqu/model/product_model.dart'; // Adjust path as needed
import 'package:qurbanqu/service/product_service.dart'; // Adjust path as needed
import 'package:supabase_flutter/supabase_flutter.dart'; // Adjust path as needed

class AdminKelolaScreen extends StatefulWidget {
  const AdminKelolaScreen({Key? key}) : super(key: key);

  @override
  State<AdminKelolaScreen> createState() => _AdminKelolaScreenState();
}

class _AdminKelolaScreenState extends State<AdminKelolaScreen> {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controllers for the form
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _jenisController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _beratController = TextEditingController();
  // _gambarController is no longer needed as a user input field for URL

  ProductModel? _editingProduct; // To store the product being edited

  // --- State variables specific to the Add/Edit Dialog ---
  // These will be managed by StatefulBuilder inside the dialog
  XFile? _dialogSelectedImage;
  bool _dialogIsUploadingImage = false;
  // ----------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _namaController.dispose();
    _jenisController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _beratController.dispose();
    super.dispose(); // No need to dispose _gambarController
  }

  // --- Fetch Products ---
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat produk: $e';
        _isLoading = false;
      });
      _showSnackBar('Gagal memuat produk: ${e.toString()}', isError: true);
    }
  }

  // --- Show SnackBar ---
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return; // Ensure widget is still mounted
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // --- Helper function to pick image (used inside the dialog) ---
  Future<void> _pickImage(StateSetter dialogSetState) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        dialogSetState(() {
          _dialogSelectedImage = image;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: ${e.toString()}', isError: true);
    }
  }

  // --- Helper function to upload image to Supabase ---
  Future<String> _uploadImageToSupabase(XFile imageFile) async {
    if (!mounted)
      throw Exception('Widget not mounted during upload'); // Basic check
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName =
          'product_images/${DateTime.now().millisecondsSinceEpoch}.$fileExt'; // Unique file name

      const String bucketName =
          'images'; // Ensure your Supabase bucket name is 'images'

      // Upload image
      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: imageFile.mimeType ?? 'image/$fileExt',
              upsert: false, // Prevent overwriting by default
            ),
          );

      // Get the public URL
      final String publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      // More specific error handling might be needed based on Supabase Storage exceptions
      print('Supabase image upload error: $e');
      throw Exception('Gagal mengunggah gambar: ${e.toString()}');
    }
  }

  // --- Show Add/Edit Form Dialog ---
  void _showProductFormDialog({ProductModel? product}) {
    _editingProduct = product; // Set the product being edited (or null for add)

    // Reset dialog specific state
    _dialogSelectedImage = null;
    _dialogIsUploadingImage = false;

    // Populate controllers if editing
    if (_editingProduct != null) {
      _namaController.text = _editingProduct!.nama;
      _jenisController.text = _editingProduct!.jenis;
      _deskripsiController.text = _editingProduct!.deskripsi;
      _hargaController.text = _editingProduct!.harga.toString();
      _beratController.text = _editingProduct!.berat.toString();
      // _gambarController is not used for user input
    } else {
      // Clear controllers for adding
      _namaController.clear();
      _jenisController.clear();
      _deskripsiController.clear();
      _hargaController.clear();
      _beratController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to manage state within the dialog
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: Text(
                _editingProduct == null ? 'Tambah Produk Baru' : 'Edit Produk',
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _jenisController,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Produk',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _deskripsiController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: null, // Allow multiple lines
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Deskripsi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _hargaController,
                        decoration: const InputDecoration(labelText: 'Harga'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harga tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _beratController,
                        decoration: const InputDecoration(
                          labelText: 'Berat (kg/g)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Berat tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // --- Image Picking and Preview ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child:
                                _dialogSelectedImage != null
                                    ? Image.file(
                                      File(_dialogSelectedImage!.path),
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                    : (_editingProduct?.gambar.isNotEmpty ??
                                        false)
                                    ? Image.network(
                                      _editingProduct!.gambar,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                size: 100,
                                                color: Colors.grey,
                                              ),
                                    )
                                    : const Icon(
                                      Icons.image_not_supported,
                                      size: 100,
                                      color: Colors.grey,
                                    ), // Placeholder for no image
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_dialogIsUploadingImage)
                                const CircularProgressIndicator()
                              else
                                ElevatedButton(
                                  onPressed:
                                      () => _pickImage(
                                        dialogSetState,
                                      ), // Call pick image with dialogSetState
                                  child: const Text('Pilih Gambar'),
                                ),
                              if (_dialogSelectedImage != null)
                                TextButton(
                                  onPressed: () {
                                    dialogSetState(() {
                                      _dialogSelectedImage = null;
                                    });
                                  },
                                  child: const Text('Batal Pilih'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Removed TextFormField for Gambar URL
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  // Disable button while image is uploading or main screen is loading
                  onPressed:
                      _dialogIsUploadingImage || _isLoading
                          ? null
                          : () => _saveProduct(), // Call save method
                  child: Text(_editingProduct == null ? 'Simpan' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Save Product (Add or Update) ---
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Form is valid, create ProductModel object
      final double? harga = double.tryParse(_hargaController.text);
      final double? berat = double.tryParse(_beratController.text);

      if (harga == null || berat == null) {
        _showSnackBar(
          'Invalid number format for Harga or Berat',
          isError: true,
        );
        return;
      }

      // Determine the final image URL
      String finalImageUrl = '';
      if (_dialogSelectedImage != null) {
        // If a new image is selected, upload it first
        if (!mounted) return; // Check mounted before state update
        setState(() {
          _dialogIsUploadingImage =
              true; // Use main screen state for broader loading indication
        });

        try {
          finalImageUrl = await _uploadImageToSupabase(_dialogSelectedImage!);
          _showSnackBar(
            'Gambar berhasil diunggah.',
          ); // Show success after upload
        } catch (e) {
          _showSnackBar(
            'Gagal mengunggah gambar: ${e.toString()}',
            isError: true,
          );
          if (!mounted) return;
          setState(() {
            _dialogIsUploadingImage = false;
          });
          // Do not proceed with saving if image upload fails
          return;
        } finally {
          if (!mounted) return;
          setState(() {
            _dialogIsUploadingImage =
                false; // Hide loading indicator after upload attempt
          });
        }
      } else if (_editingProduct != null) {
        // If editing and no new image selected, keep the existing URL
        finalImageUrl = _editingProduct!.gambar;
      } else {
        // Adding a new product without selecting an image
        finalImageUrl = ''; // Or a default image URL if you have one
      }

      // Close dialog after image handling
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      setState(() {
        _isLoading =
            true; // Show main screen loading indicator while saving DB data
      });

      final productToSave = ProductModel(
        id:
            _editingProduct?.id ??
            '', // Use existing ID if editing, empty string if adding
        nama: _namaController.text,
        jenis: _jenisController.text,
        deskripsi: _deskripsiController.text,
        harga: harga,
        berat: berat,
        gambar: finalImageUrl, // Use the determined image URL
      );

      try {
        if (_editingProduct == null) {
          // Add new product
          await _productService.addProduct(productToSave);
          _showSnackBar('Produk berhasil ditambahkan');
        } else {
          // Update existing product
          await _productService.updateProduct(productToSave);
          _showSnackBar('Produk berhasil diperbarui');
        }
        _fetchProducts(); // Refresh list after save/update
      } catch (e) {
        _showSnackBar('Gagal menyimpan produk: ${e.toString()}', isError: true);
        if (!mounted) return;
        setState(() {
          _isLoading = false; // Hide main screen loading indicator on error
        });
      }
    }
  }

  // --- Delete Product ---
  Future<void> _deleteProduct(ProductModel product) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Konfirmasi Hapus'),
              content: Text(
                'Anda yakin ingin menghapus produk "${product.nama}"?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Cancel
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Confirm
                  child: const Text('Hapus'),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if dialog is dismissed

    if (confirm) {
      if (!mounted) return;
      setState(() {
        _isLoading = true; // Show loading indicator while deleting
      });
      try {
        await _productService.deleteProduct(product.id);
        _showSnackBar('Produk berhasil dihapus');
        _fetchProducts(); // Refresh list after deletion
      } catch (e) {
        _showSnackBar('Gagal menghapus produk: ${e.toString()}', isError: true);
        if (!mounted) return;
        setState(() {
          _isLoading = false; // Hide loading indicator on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
              : _products.isEmpty
              ? const Center(child: Text('Belum ada produk.'))
              : ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading:
                          product.gambar.isNotEmpty
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(product.gambar),
                                onBackgroundImageError: (e, stackTrace) {
                                  print(
                                    'Error loading image for ${product.nama}: $e',
                                  );
                                  // You could return a placeholder widget here instead of just printing
                                },
                              )
                              : const CircleAvatar(
                                child: Icon(Icons.image_not_supported),
                              ), // Placeholder
                      title: Text(product.nama),
                      subtitle: Text(
                        'Rp ${product.harga.toStringAsFixed(2)} - ${product.jenis}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                // Disable buttons while main screen is loading
                                _isLoading
                                    ? null
                                    : () => _showProductFormDialog(
                                      product: product,
                                    ),
                            tooltip: 'Edit Produk',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _deleteProduct(
                                      product,
                                    ), // Disable while loading
                            tooltip: 'Hapus Produk',
                            color: Colors.red,
                          ),
                        ],
                      ),
                      // You can add onTap to view product details
                      // onTap: () { /* Navigate to detail screen */ },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _isLoading
                ? null
                : () => _showProductFormDialog(), // Disable while loading
        tooltip: 'Tambah Produk',
        child: const Icon(Icons.add),
      ),
    );
  }
}
