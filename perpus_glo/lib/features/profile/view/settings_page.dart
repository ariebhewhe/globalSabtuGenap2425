import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCategory(
            context,
            'Akun',
            [
              _buildSettingTile(
                context,
                'Edit Profil',
                Icons.edit,
                () => context.push('/profile/edit'),
              ),
              _buildSettingTile(
                context,
                'Ubah Email',
                Icons.email,
                () => _showChangeEmailDialog(context, ref),
              ),
              _buildSettingTile(
                context,
                'Ubah Password',
                Icons.lock,
                () => _showChangePasswordDialog(context, ref),
              ),
            ],
          ),
          
          _buildSettingCategory(
            context,
            'Aplikasi',
            [
              _buildSettingTile(
                context,
                'Notifikasi',
                Icons.notifications,
                () => context.push('/notifications'),
              ),
              _buildSettingTile(
                context,
                'Bahasa',
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildSettingTile(
                context,
                'Tentang Aplikasi',
                Icons.info,
                () => _showAboutDialog(context),
              ),
            ],
          ),
          
          _buildSettingCategory(
            context,
            'Lainnya',
            [
              _buildSettingTile(
                context,
                'Hapus Akun',
                Icons.delete_forever,
                () => _showDeleteAccountDialog(context, ref),
                isDestructive: true,
              ),
              _buildSettingTile(
                context,
                'Keluar',
                Icons.logout,
                () => _showLogoutDialog(context, ref),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCategory(
      BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: tiles,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showChangeEmailDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Email'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Baru'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@')) {
                    return 'Email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password Saat Ini'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final profileState = ref.watch(profileControllerProvider);
              
              return TextButton(
                onPressed: profileState.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          await ref.read(profileControllerProvider.notifier).updateEmail(
                            emailController.text.trim(),
                            passwordController.text,
                          );
                          
                          if (!ref.read(profileControllerProvider).hasError && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email berhasil diperbarui')),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                child: profileState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: LoadingIndicator(),
                      )
                    : const Text('SIMPAN'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(labelText: 'Password Saat Ini'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konfirmasi password tidak boleh kosong';
                  }
                  if (value != newPasswordController.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final profileState = ref.watch(profileControllerProvider);
              
              return TextButton(
                onPressed: profileState.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          await ref.read(profileControllerProvider.notifier).updatePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );
                          
                          if (!ref.read(profileControllerProvider).hasError && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password berhasil diperbarui')),
                            );
                            Navigator.pop(context);
                          }
                        }
                      },
                child: profileState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: LoadingIndicator(),
                      )
                    : const Text('SIMPAN'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Bahasa'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              // Handle language change
              Navigator.pop(context);
            },
            child: const Text('Bahasa Indonesia'),
          ),
          SimpleDialogOption(
            onPressed: () {
              // Handle language change
              Navigator.pop(context);
            },
            child: const Text('English'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Perpustakaan GLO',
      applicationVersion: 'v1.0.0',
      applicationIcon: Image.asset(
        'assets/images/logo.png',
        height: 64,
        width: 64,
      ),
      applicationLegalese: '© 2023 GLO Team',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Perpustakaan GLO adalah aplikasi peminjaman buku digital. Dengan aplikasi ini, '
          'Anda dapat dengan mudah mencari, meminjam, dan mengembalikan buku dari koleksi perpustakaan kami.',
        ),
      ],
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Perhatian: Semua data Anda akan dihapus secara permanen dan tidak dapat dikembalikan. Apakah Anda yakin ingin menghapus akun?',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final profileState = ref.watch(profileControllerProvider);
              
              return TextButton(
                onPressed: profileState.isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          await ref.read(profileControllerProvider.notifier).deleteAccount(
                            passwordController.text,
                          );
                          
                          if (!ref.read(profileControllerProvider).hasError && context.mounted) {
                            Navigator.pop(context);
                            context.go('/login');
                          }
                        }
                      },
                child: profileState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: LoadingIndicator(),
                      )
                    : const Text(
                        'HAPUS AKUN',
                        style: TextStyle(color: Colors.red),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
  }
}