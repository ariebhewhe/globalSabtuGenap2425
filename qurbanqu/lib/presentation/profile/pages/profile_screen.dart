import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qurbanqu/common/custom_button.dart';
import 'package:qurbanqu/core/config/app_colors.dart';
import 'package:qurbanqu/core/config/styles.dart';
import 'package:qurbanqu/model/order_model.dart';
import 'package:qurbanqu/model/user_model.dart';
import 'package:qurbanqu/presentation/auth/pages/login_screen.dart';
import 'package:qurbanqu/service/auth_service.dart';
import 'package:qurbanqu/service/order_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isEditing = false;

  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _alamatController = TextEditingController();

  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _inProcessOrders = 0;
  int _completedOrders = 0;

  final OrderService _orderService = OrderService();

  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data ketika kembali ke screen ini
    if (ModalRoute.of(context)!.isCurrent) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      UserModel? user = await authService.getCurrentUserModel();

      if (user != null && mounted) {
        // Get user orders
        List<OrderModel> userOrders = await _orderService.getOrdersByUserId(
          user.id,
        );

        // Calculate statistics
        _totalOrders = userOrders.length;
        _pendingOrders =
            userOrders
                .where(
                  (o) =>
                      o.status.toLowerCase() == 'pending' ||
                      o.status.toLowerCase() == 'menunggu pembayaran',
                )
                .length;

        _inProcessOrders =
            userOrders
                .where(
                  (o) =>
                      o.status.toLowerCase() == 'diproses' ||
                      o.status.toLowerCase() == 'processing' ||
                      o.status.toLowerCase() == 'sedang diproses',
                )
                .length;

        _completedOrders =
            userOrders
                .where(
                  (o) =>
                      o.status.toLowerCase() == 'completed' ||
                      o.status.toLowerCase() == 'selesai' ||
                      o.status.toLowerCase() == 'success',
                )
                .length;

        setState(() {
          _currentUser = user;
          _namaController.text = user.nama;
          _teleponController.text = user.telepon;
          _alamatController.text = user.alamat;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load profile data'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_namaController.text.isEmpty ||
        _teleponController.text.isEmpty ||
        _alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      if (_currentUser != null) {
        await authService.updateUserProfile(
          userId: _currentUser!.id,
          nama: _namaController.text,
          telepon: _teleponController.text,
          alamat: _alamatController.text,
        );

        // Ambil data terbaru dari Firestore setelah update
        UserModel? updatedUser = await authService.getCurrentUserModel();

        if (mounted && updatedUser != null) {
          setState(() {
            _currentUser = updatedUser;
            _namaController.text = updatedUser.nama;
            _teleponController.text = updatedUser.telepon;
            _alamatController.text = updatedUser.alamat;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Apakah Anda yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (result == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!_isEditing)
                            Text(
                              _currentUser?.nama ?? 'Nama Pengguna',
                              style: AppStyles.heading1,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser?.email ??
                                'Email Pengguna', // Diperbaiki dari nama ke email
                            style: AppStyles.bodyText,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isEditing) _buildEditForm() else _buildProfileInfo(),
                    const SizedBox(height: 32),
                    if (!_isEditing)
                      CustomButton(
                        text: 'Logout',
                        onPressed: _logout,
                        isOutlined: true,
                        color: Colors.red,
                        icon: Icons.logout,
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informasi Pribadi', style: AppStyles.heading2),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.phone,
          title: 'Nomor Telepon',
          value: _currentUser?.telepon ?? '-',
        ),
        const Divider(),
        _buildInfoItem(
          icon: Icons.home,
          title: 'Alamat',
          value: _currentUser?.alamat ?? '-',
        ),
        const Divider(),
        const SizedBox(height: 24),
        const Text('Statistik Pesanan', style: AppStyles.heading2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                count: '$_totalOrders',
                title: 'Total Pesanan',
                icon: Icons.shopping_cart,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                count: '$_pendingOrders',
                title: 'Pending',
                icon: Icons.payment,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                count: '$_inProcessOrders',
                title: 'Sedang Diproses',
                icon: Icons.autorenew,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                count: '$_completedOrders',
                title: 'Selesai',
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Profil', style: AppStyles.heading2),
          const SizedBox(height: 16),
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _currentUser?.email,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _teleponController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _alamatController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alamat',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Batal',
                  onPressed: _toggleEditMode,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(text: 'Simpan', onPressed: _saveProfile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String count,
    required String title,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
