// lib/screens/user/home_screen.dart
import 'package:flutter/material.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/core/config/styles.dart';
import 'package:qurbanqu/model/product_model.dart';
import 'package:qurbanqu/presentation/home/widgets/product_card.dart';
import 'package:qurbanqu/presentation/order/pages/order_history_screen.dart';
import 'package:qurbanqu/presentation/product/pages/product_detail.dart';
import 'package:qurbanqu/presentation/profile/pages/profile_screen.dart';
import 'package:qurbanqu/service/product_service.dart'; // Import ProductService

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<ProductModel> _productList = [];
  List<ProductModel> _filteredProductList = []; // Untuk menampung hasil filter
  final ProductService _productService =
      ProductService(); // Instance ProductService
  String _selectedFilter = 'Semua'; // Menyimpan nilai filter yang dipilih

  @override
  void initState() {
    super.initState();
    _loadData(); // Panggil _loadData saat inisialisasi
  }

  // Fungsi untuk memuat data produk
  Future<void> _loadData({String? filterJenis}) async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<ProductModel> products;
      if (filterJenis == null || filterJenis == 'Semua') {
        products = await _productService.getAllProducts();
      } else {
        products = await _productService.getProductsByType(filterJenis);
      }
      setState(() {
        _productList = products;
        _filteredProductList =
            products; // Awalnya, daftar yang difilter sama dengan daftar lengkap
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Tampilkan pesan error jika diperlukan, misalnya menggunakan SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
      );
      print(e); // Untuk debugging
    }
  }

  void _applyFilter(String? jenis) {
    if (jenis == null || jenis == 'Semua') {
      setState(() {
        _filteredProductList = _productList;
        _selectedFilter = 'Semua';
      });
    } else {
      setState(() {
        _filteredProductList =
            _productList.where((product) => product.jenis == jenis).toList();
        _selectedFilter = jenis;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QurbanQu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh:
                    () => _loadData(
                      filterJenis:
                          _selectedFilter == 'Semua' ? null : _selectedFilter,
                    ), // Panggil _loadData dengan filter saat refresh
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: AppColors.primary),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang di QurbanQu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Temukan hewan product terbaik untuk Anda',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.accent,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pesan product sekarang untuk dapatkan harga terbaik!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filter
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          const Text(
                            'Pilihan Hewan Kurban', // Mengganti 'product' menjadi 'Kurban' agar lebih sesuai
                            style: AppStyles.heading2,
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value:
                                _selectedFilter, // Gunakan state untuk nilai terpilih
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
                                  _selectedFilter = value;
                                });
                                // Panggil _loadData dengan filter baru ATAU filter di client side
                                // Untuk performa lebih baik jika data tidak terlalu besar, filter di client side
                                _applyFilter(value);
                                // Jika ingin load dari server setiap filter diganti:
                                // _loadData(filterJenis: value == 'Semua' ? null : value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Daftar Hewan product
                    Expanded(
                      child:
                          _filteredProductList
                                  .isEmpty // Gunakan _filteredProductList
                              ? Center(
                                child: Text(
                                  _isLoading
                                      ? 'Memuat data...'
                                      : 'Tidak ada hewan kurban tersedia untuk filter ini',
                                  style: AppStyles.bodyText,
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal:
                                      16, // Tambahkan padding horizontal jika perlu
                                ),
                                itemCount:
                                    _filteredProductList
                                        .length, // Gunakan _filteredProductList
                                itemBuilder: (context, index) {
                                  final product =
                                      _filteredProductList[index]; // Gunakan _filteredProductList
                                  return ProductCard(
                                    product: product,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ProductDetailScreen(
                                                product: product,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
