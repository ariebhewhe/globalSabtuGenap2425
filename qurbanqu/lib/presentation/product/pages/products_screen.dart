import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/core/config/styles.dart';
import 'package:qurbanqu/model/product_model.dart';
import 'package:qurbanqu/presentation/product/pages/add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isLoading = true;
  List<ProductModel> _ProductList = [];
  String _filterType = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulasi pemuatan data dari database
    await Future.delayed(const Duration(seconds: 2));
  }

  List<ProductModel> get _filteredProduct {
    if (_filterType == 'Semua') {
      return _ProductList;
    } else {
      return _ProductList.where(
        (Product) => Product.jenis == _filterType,
      ).toList();
    }
  }

  Future<void> _deleteProduct(String id) async {
    // Konfirmasi hapus
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Hewan Product'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus hewan Product ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      // Simulasi proses hapus dari database
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _ProductList.removeWhere((Product) => Product.id == id);
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hewan Product berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Hewan Product')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    // Filter
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text('Filter: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _filterType,
                            items: const [
                              DropdownMenuItem(
                                value: 'Semua',
                                child: Text('Semua'),
                              ),
                              DropdownMenuItem(
                                value: 'Sapi',
                                child: Text('Sapi'),
                              ),
                              DropdownMenuItem(
                                value: 'Kambing',
                                child: Text('Kambing'),
                              ),
                              DropdownMenuItem(
                                value: 'Domba',
                                child: Text('Domba'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _filterType = value;
                                });
                              }
                            },
                          ),
                          const Spacer(),
                          Text(
                            'Total: ${_filteredProduct.length} hewan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child:
                          _filteredProduct.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pets,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Tidak ada hewan Product $_filterType',
                                      style: AppStyles.heading2,
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const AddEditProductScreen(),
                                          ),
                                        ).then((_) => _refreshData());
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('Tambah Hewan'),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: _filteredProduct.length,
                                itemBuilder: (context, index) {
                                  final Product = _filteredProduct[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Gambar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              Product.gambar,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        Product.jenis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      formatCurrency.format(
                                                        Product.harga,
                                                      ),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  Product.nama,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Berat: ${Product.berat} kg',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                // Buttons
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton.icon(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => AddEditProductScreen(
                                                                  Product:
                                                                      Product,
                                                                ),
                                                          ),
                                                        ).then(
                                                          (_) => _refreshData(),
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.edit,
                                                      ),
                                                      label: const Text('Edit'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    TextButton.icon(
                                                      onPressed:
                                                          () => _deleteProduct(
                                                            Product.id,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      label: const Text(
                                                        'Hapus',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          ).then((_) => _refreshData());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
