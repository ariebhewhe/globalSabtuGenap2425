import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cart_item.dart';
import '../../data/menu_data.dart';
import '../cart/cart_page.dart';
import '../order/order_page.dart';
import '../profile/profile_page.dart';
import '../auth/login_page.dart';
import 'components/category_button.dart';
import 'components/recommended_item_badge.dart';
import '../../data/recommendation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedCategory = 0;
  List<CartItem> cartItems = [];
  Map<String, RecommendationData> _recommendations = {};
  bool _isLoadingRecommendations = true;
  bool _isLoadingMenu = true;
  List<Map<dynamic, dynamic>> _menuItems = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    checkAuth();
    _loadRecommendations();
    _loadMenuData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load menu data once at initialization
  Future<void> _loadMenuData() async {
    setState(() {
      _isLoadingMenu = true;
    });

    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('menu').get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> menuMap = snapshot.value as Map<dynamic, dynamic>;
        
        List<Map<dynamic, dynamic>> items = menuMap.entries
            .map((entry) => {
                  'id': entry.key,
                  ...entry.value as Map<dynamic, dynamic>,
                })
            .toList();
        
        setState(() {
          _menuItems = items;
          _isLoadingMenu = false;
        });
      } else {
        setState(() {
          _menuItems = [];
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      setState(() {
        _menuItems = [];
        _isLoadingMenu = false;
      });
      debugPrint('Error loading menu data: $e');
    }
  }

  // Load recommendations data
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });
    
    try {
      final recommendations = await RecommendationService.getRecommendedItems();
      
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      setState(() {
        _recommendations = {};
        _isLoadingRecommendations = false;
      });
      debugPrint('Error loading recommendations: $e');
    }
  }

  void checkAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null && mounted) {
        // Jika user belum login, navigasikan ke LoginPage
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  void _addToCart(Map<dynamic, dynamic> item) {
    setState(() {
      int existingIndex = cartItems.indexWhere(
        (element) => element.name == item['name'],
      );

      if (existingIndex != -1) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(CartItem(
          name: item['name'],
          price: item['price'],
          image: item['imageUrl'],
          quantity: 1,
        ));
      }
    });

    // Tampilkan animasi dan feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${item['name']} ditambahkan ke keranjang',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC793B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CartPage(
                  cartItems: cartItems,
                  onCartCleared: () {
                    setState(() {
                      cartItems.clear();
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showItemDetail(BuildContext context, Map<dynamic, dynamic> item) {
    const Color primaryColor = Color(0xFFDC793B);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Hero(
                            tag: 'item-image-${item['id']}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: item['imageUrl'] ?? '',
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: double.infinity,
                                  height: 220,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: double.infinity,
                                  height: 220,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.fastfood, size: 50),
                                ),
                              ),
                            ),
                          ),
                          
                          // Add recommendation badge if item is recommended
                          if (!_isLoadingRecommendations && 
                              _recommendations.containsKey(item['name']) &&
                              _recommendations[item['name']]!.uniqueUsers.length >= 2)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.thumb_up, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Rekomendasi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Tidak ada nama',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, color: Colors.amber[700], size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            (item['rating'] is int || item['rating'] is double) 
                                              ? item['rating'].toString() 
                                              : '0',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        item['category']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 16),
                      
                      // Price with custom styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red[100]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'IDR ${item['price']?.toString() ?? '0'}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Description section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              item['description'] ?? 'Tidak ada deskripsi',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Add to cart button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _addToCart(item);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shopping_cart),
                              SizedBox(width: 12),
                              Text(
                                'Tambahkan ke Keranjang',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const OrderPage();
      case 2:
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          return ProfilePage(userId: userId); 
        } else {
          // Jika user belum login, arahkan ke LoginPage
          return const LoginPage();
        }
      default:
        return _buildHomePage();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFDC793B),
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat menu...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _loadMenuData();
              _loadRecommendations();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC793B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada menu tersedia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan coba kategori lain atau kembali nanti',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Map<dynamic, dynamic>> _getFilteredItems() {
    // Filter berdasarkan kategori
    return _menuItems.where((item) {
      String category = item['category'] ?? '';
      if (_selectedCategory == 0) return category == 'Makanan';
      if (_selectedCategory == 1) return category == 'Minuman';
      if (_selectedCategory == 2) return category == 'Snack';
      return true;
    }).toList();
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 70,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: MenuData.categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return CategoryButton(
                icon: MenuData.categories[index]['icon'],
                label: MenuData.categories[index]['name'],
                isSelected: _selectedCategory == index,
                onPressed: () {
                  setState(() {
                    _selectedCategory = index;
                  });
                },
              );
            },
          ),
        ),

        // Menu Items
        Expanded(
          child: _isLoadingMenu || _isLoadingRecommendations
              ? _buildLoading()
              : _buildMenuContent(),
        ),
      ],
    );
  }

 // 3. Fix untuk Grid Layout - Ganti bagian SliverGrid di _buildMenuContent
Widget _buildMenuContent() {
  // Filter berdasarkan kategori yang dipilih
  final filteredItems = _getFilteredItems();
  
  if (filteredItems.isEmpty) {
    return _buildEmptyView();
  }
  
  // Identifikasi item rekomendasi
  List<Map<dynamic, dynamic>> recommendedItems = [];
  for (var item in filteredItems) {
    final name = item['name'];
    if (_recommendations.containsKey(name) && 
        _recommendations[name]!.uniqueUsers.length >= 2) {
      recommendedItems.add(item);
    }
  }
  
  // Urutkan item rekomendasi berdasarkan skor SAW
  recommendedItems.sort((a, b) {
    final scoreA = _recommendations[a['name']]?.sawScore ?? 0;
    final scoreB = _recommendations[b['name']]?.sawScore ?? 0;
    return scoreB.compareTo(scoreA); // Urutan menurun
  });
  
  // Hapus item rekomendasi dari daftar biasa
  final regularItems = filteredItems
      .where((item) => !recommendedItems
          .any((rec) => rec['name'] == item['name']))
      .toList();
  
  // Gabungkan daftar: item rekomendasi terlebih dahulu, lalu item biasa
  final allItems = [...recommendedItems, ...regularItems];

  return RefreshIndicator(
    onRefresh: () async {
      await Future.wait([
        _loadMenuData(),
        _loadRecommendations(),
      ]);
    },
    color: const Color(0xFFDC793B),
    child: CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Rekomendasi Section Header (jika ada item rekomendasi)
        if (recommendedItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.recommend,
                    color: Color(0xFFDC793B),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rekomendasi untuk Anda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Rekomendasi Items (jika ada) - Dikurangi tingginya
        if (recommendedItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              height: 220, // Kurangi dari 260 ke 220
              padding: const EdgeInsets.only(left: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recommendedItems.length,
                itemBuilder: (context, index) {
                  final item = recommendedItems[index];
                  return _buildHorizontalItemCard(item);
                },
              ),
            ),
          ),
          
        // Menu section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(
                  _selectedCategory == 0 
                      ? Icons.restaurant 
                      : _selectedCategory == 1 
                          ? Icons.local_drink 
                          : Icons.cake,
                  color: const Color(0xFFDC793B),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  MenuData.categories[_selectedCategory]['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Grid menu items - Responsive grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8, // Ubah dari 0.75 ke 0.8
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final itemIndex = recommendedItems.isNotEmpty 
                    ? index + recommendedItems.length 
                    : index;
                    
                if (itemIndex >= allItems.length) {
                  return null;
                }
                
                final item = allItems[itemIndex];
                return _buildGridItemCard(item);
              },
              childCount: allItems.length,
            ),
          ),
        ),
      ],
    ),
  );
}

  // 2. Fix untuk Horizontal Item Card - Ganti _buildHorizontalItemCard method
Widget _buildHorizontalItemCard(Map<dynamic, dynamic> item) {
  final isRecommended = _recommendations.containsKey(item['name']) &&
      _recommendations[item['name']]!.uniqueUsers.length >= 2;
      
  return Container(
    width: 180, // Kurangi lebar
    margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.15),
          spreadRadius: 0,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image - Responsive
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Hero(
                  tag: 'item-h-${item['id']}',
                  child: CachedNetworkImage(
                    imageUrl: item['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDC793B),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 32),
                    ),
                  ),
                ),
              ),
            ),
            
            // Item Details - Responsive
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item['name'] ?? 'Tidak ada nama',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IDR ${item['price']?.toString() ?? '0'}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber[700],
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (item['rating'] is int || item['rating'] is double) 
                            ? item['rating'].toString() 
                            : '0',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Recommendation badge if applicable
        if (isRecommended)
          const Positioned(
            top: 6,
            right: 6,
            child: RecommendedBadge(size: 28),
          ),
        
        // Add to cart button
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFDC793B),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC793B).withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _addToCart(item),
                borderRadius: BorderRadius.circular(10),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        
        // Clickable overlay for item details
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showItemDetail(context, item),
            ),
          ),
        ),
      ],
    ),
  );
}

  
  // 1. Fix untuk Grid Items - Ganti _buildGridItemCard method
Widget _buildGridItemCard(Map<dynamic, dynamic> item) {
  final isRecommended = _recommendations.containsKey(item['name']) &&
      _recommendations[item['name']]!.uniqueUsers.length >= 2;
      
  return Card(
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image - Buat responsive
            Expanded(
              flex: 3, // 60% dari tinggi card
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Hero(
                  tag: 'item-image-${item['id']}',
                  child: CachedNetworkImage(
                    imageUrl: item['imageUrl'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDC793B),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, size: 32),
                    ),
                  ),
                ),
              ),
            ),
            
            // Item Details - Buat responsive
            Expanded(
              flex: 2, // 40% dari tinggi card
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name dengan flexible text
                    Flexible(
                      child: Text(
                        item['name'] ?? 'Tidak ada nama',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Price
                    Text(
                      'IDR ${item['price']?.toString() ?? '0'}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Rating
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber[700],
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          (item['rating'] is int || item['rating'] is double) 
                            ? item['rating'].toString() 
                            : '0',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Recommendation badge if applicable
        if (isRecommended)
          const Positioned(
            top: 6,
            right: 6,
            child: RecommendedBadge(size: 28),
          ),
        
        // Add to cart button
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFDC793B),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC793B).withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _addToCart(item),
                borderRadius: BorderRadius.circular(10),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        
        // Clickable overlay for item details
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showItemDetail(context, item),
            ),
          ),
        ),
      ],
    ),
  );
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: AppBar(
         centerTitle: false, // Ini yang membuat title/logo ke kiri
  title: _selectedIndex == 0 
      ? Image.asset(
          'assets/icon/Brand.png',  // Path to your logo image
          height: 45,  // Adjust height as needed
        )
        
          : Text(
              _selectedIndex == 1 
                  ? 'Pesanan'
                  : 'Profil',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ), 
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: _selectedIndex == 0
            ? [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      color: Colors.black87,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartPage(
                              cartItems: cartItems,
                              onCartCleared: () {
                                setState(() {
                                  cartItems.clear();
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    if (cartItems.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cartItems.fold(
                              0,
                              (sum, item) => sum + item.quantity,
                            ).toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: _buildPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFDC793B),
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Pesanan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}