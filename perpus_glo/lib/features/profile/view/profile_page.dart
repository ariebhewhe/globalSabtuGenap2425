import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../model/user_profile_model.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
// Tambahkan provider untuk cek pembayaran pending
    // final pendingPaymentsProvider = StreamProvider<int>((ref) {
    //   final repository = ref.watch(paymentRepositoryProvider);
    //   return repository.getUserPayments().map((payments) =>
    //       payments.where((p) => p.status == PaymentStatus.pending).length);
    // });

// Di ProfilePage
    // final pendingPaymentsCount = ref.watch(pendingPaymentsProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              context.push('/settings');
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Profil tidak ditemukan'),
            );
          }
          return _buildProfileContent(context, ref, profile);
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, WidgetRef ref, UserProfileModel profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile picture
          _buildProfilePicture(context, ref, profile),
          const SizedBox(height: 16),

          // User name
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // User email
          Text(
            profile.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          // User role badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(profile.role),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              profile.role.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Information cards
          _buildInfoCard('Informasi Kontak', [
            _buildInfoRow(Icons.phone, 'Nomor Telepon',
                profile.phoneNumber ?? 'Belum diatur'),
            _buildInfoRow(
                Icons.location_on, 'Alamat', profile.address ?? 'Belum diatur'),
          ]),

          const SizedBox(height: 16),

          // Account information card
          _buildInfoCard('Informasi Akun', [
            _buildInfoRow(Icons.calendar_today, 'Terdaftar Pada',
                _formatDate(profile.createdAt)),
            if (profile.lastLoginAt != null)
              _buildInfoRow(Icons.access_time, 'Login Terakhir',
                  _formatDate(profile.lastLoginAt!)),
          ]),

          const SizedBox(height: 24),

          // Action buttons
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16, // jarak horizontal antar tombol
            runSpacing: 12, // jarak vertikal antar baris
            children: [
              ElevatedButton(
                onPressed: () {
                  context.push('/profile/edit');
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Profil'),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  context.push('/history');
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Riwayat Aktivitas'),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  context.push('/payment-history');
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment),
                    SizedBox(width: 8),
                    Text('Riwayat Pembayaran'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Admin Dashboard button (only shown for admin/librarian)
          if (profile.role == UserRole.admin ||
              profile.role == UserRole.librarian)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/admin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getRoleColor(profile.role),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text(
                  'Dashboard Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(
      BuildContext context, WidgetRef ref, UserProfileModel profile) {
    final profileController = ref.watch(profileControllerProvider);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Profile image
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          // backgroundImage:
          //     profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
          child: profile.photoUrl == null
              ? Text(
                  _getInitials(profile.name),
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold),
                )
              : null,
        ),

        // Edit profile picture button
        // Container(
        //   decoration: BoxDecoration(
        //     color: AppTheme.lightTheme.primaryColor,
        //     shape: BoxShape.circle,
        //     border: Border.all(color: Colors.white, width: 2),
        //   ),
        //   child: IconButton(
        //     icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
        //     onPressed: profileController.isLoading
        //         ? null
        //         : () => _changeProfilePicture(context, ref),
        //   ),
        // ),
      ],
    );
  }

  // Future<void> _changeProfilePicture(BuildContext context, WidgetRef ref) async {
  //   final controller = ref.read(profileControllerProvider.notifier);

  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => SafeArea(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: const Icon(Icons.photo_camera),
  //             title: const Text('Ambil Foto'),
  //             onTap: () async {
  //               Navigator.pop(context);
  //               final image = await _pickImage(ImageSource.camera);
  //               if (image != null) {
  //                 await controller.updateProfilePicture(File(image.path));
  //               }
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.photo_library),
  //             title: const Text('Pilih dari Galeri'),
  //             onTap: () async {
  //               Navigator.pop(context);
  //               final image = await _pickImage(ImageSource.gallery);
  //               if (image != null) {
  //                 await controller.updateProfilePicture(File(image.path));
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<XFile?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.lightTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.length == 1 && nameParts[0].isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return '?';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.librarian:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }
}