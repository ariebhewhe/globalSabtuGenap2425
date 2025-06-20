import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../common/widgets/loading_indicator.dart';
import '../model/user_profile_model.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  late UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    
    // Set loading state while we wait for profile data
    setState(() {
      _isLoading = true;
    });
    
    // Schedule this to run after the first frame to avoid errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    // Get user profile
    final profileAsync = ref.read(userProfileProvider);
    
    // Wait for profile data to load
    profileAsync.whenData((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
          
          if (profile != null) {
            _nameController.text = profile.name;
            _phoneController.text = profile.phoneNumber ?? '';
            _addressController.text = profile.address ?? '';
          }
          
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _profile == null
              ? const Center(child: Text('Profil tidak ditemukan'))
              : _buildForm(context, profileState),
    );
  }

  Widget _buildForm(BuildContext context, AsyncValue<void> profileState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            const Text(
              'Nama',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan nama lengkap',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Phone field
            const Text(
              'Nomor Telepon',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan nomor telepon',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Address field
            const Text(
              'Alamat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Masukkan alamat',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Save button
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: profileState.isLoading ? null : _saveProfile,
                  child: profileState.isLoading
                      ? const LoadingIndicator()
                      : const Text('SIMPAN PERUBAHAN'),
                ),
              ),
            ),
            
            // Error message
            if (profileState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Error: ${profileState.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Update profile object with form values
      final updatedProfile = _profile!.copyWith(
        name: _nameController.text,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
      );
      
      // Save the profile
      await ref.read(profileControllerProvider.notifier).updateProfile(updatedProfile);
      
      // If there's no error, go back
      if (!mounted) return;
      if (!ref.read(profileControllerProvider).hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        context.pop();
      }
    }
  }
}