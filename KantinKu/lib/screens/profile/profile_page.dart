import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late DatabaseReference _userRef;
  Map<String, dynamic>? _userData;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref().child('users').child(widget.userId);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    _userRef.once().then((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _userData = Map<String, dynamic>.from(data);
          _nameController.text = _userData?['name'] ?? '';
          _emailController.text = _userData?['email'] ?? '';
          _phoneController.text = _userData?['phone'] ?? '';
        });
      }
    }).catchError((error) {
      debugPrint('Error loading user data: $error');
    });
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/your-cloud-name/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = 'KantinKu'
        ..fields['api_key'] = '852269193515426'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isLoading = true);
        
        final imageUrl = await _uploadImageToCloudinary(File(image.path));
        
        if (imageUrl != null) {
          await _userRef.update({'profileImage': imageUrl});
          setState(() {
            _userData = {...?_userData, 'profileImage': imageUrl};
          });
        }
        
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);
      
      await _userRef.update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      });

      setState(() {
        _userData = {
          ...?_userData,
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
        };
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'kantinkuservice@gmail.com',
      query: 'subject=Support Needed&body=Please describe your issue here.',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    }
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri privacyPolicyUri = Uri.parse(
      'https://docs.google.com/document/d/1xO3Q6BwzKlt8yuScRglwf9gUA3xqsH0P/edit?usp=drive_link&ouid=106525602293857676424&rtpof=true&sd=true'
    );

    if (await canLaunchUrl(privacyPolicyUri)) {
      await launchUrl(
        privacyPolicyUri,
        mode: LaunchMode.inAppWebView,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Privacy Policy')),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        if (_userData?['profileImage'] != null)
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(_userData!['profileImage']),
          )
        else
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              (_userData?['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                color: Color(0xFFDC793B),
              ),
            ),
          ),
        if (_isEditing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDC793B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: _pickAndUploadImage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Name',
          enabled: _isEditing,
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          enabled: _isEditing,
          icon: Icons.email,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone',
          enabled: _isEditing,
          icon: Icons.phone,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFDC793B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC793B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC793B), width: 2),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color ?? const Color(0xFFDC793B)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color ?? Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      actions: [
                        if (!_isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => setState(() => _isEditing = true),
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: _saveProfile,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _loadUserData(); // Reset to original data
                                  });
                                },
                              ),
                            ],
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFDC793B),
                                const Color(0xFFDC793B).withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              _buildProfileImage(),
                              const SizedBox(height: 10),
                              if (!_isEditing)
                                Text(
                                  _userData?['name'] ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.person, 
                                          color: Color(0xFFDC793B)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Profile',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    _buildProfileFields(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildActionCard(
                              icon: Icons.support_agent,
                              title: 'Support',
                              onTap: _launchEmail,
                            ),
                            const SizedBox(height: 10),
                            _buildActionCard(
                              icon: Icons.privacy_tip,
                              title: 'Kebijakan Privasi',
                              onTap: _launchPrivacyPolicy,
                            ),
                            const SizedBox(height: 10),
                            _buildActionCard(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              onTap: _signOut,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }
}