import 'package:flutter/material.dart';
import 'package:warkop_bunny/services/auth_service.dart';
import 'package:warkop_bunny/pages/auth/login_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // get auth service
  final AuthService authService = AuthService();

  // logout button pressed
  void logout() async {
    await authService.signOut();
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // get user email
    final userEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Logout Button
          IconButton(
            onPressed: () {
              logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text(userEmail.toString())),
    );
  }
}
