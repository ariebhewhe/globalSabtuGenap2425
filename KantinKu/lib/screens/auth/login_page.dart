import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kantinku/screens/home/home_page.dart';
import 'package:kantinku/screens/admin/admin_page.dart';
import 'register_page.dart';
import '../../models/user_details.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _emailError = '';
  String _passwordError = '';
  String _generalError = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _emailError = '';
      _passwordError = '';
      _generalError = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Debug print
      print("Email: $email");
      print("Password: $password");

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(credential.user!.uid)
          .get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        final userDetails = UserDetails.fromMap(userData);

        if (!mounted) return;

        if (userDetails.role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _emailError = 'Akun tidak ditemukan dalam database.';
        });
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");

      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _emailError = 'Email tidak terdaftar.';
            break;
          case 'wrong-password':
            _passwordError = 'Password salah.';
            break;
          case 'invalid-email':
            _emailError = 'Format email tidak valid.';
            break;
          case 'user-disabled':
            _generalError = 'Akun ini telah dinonaktifkan.';
            break;
          case 'too-many-requests':
            _generalError = 'Terlalu banyak percobaan login. Coba lagi nanti.';
            break;
          case 'invalid-credential':
            _generalError = 'Email atau password salah.';
            break;
          case 'missing-email':
            _emailError = 'Email harus diisi.';
            break;
          case 'missing-password':
            _passwordError = 'Password harus diisi.';
            break;
          default:
            _generalError = e.message ?? 'Terjadi kesalahan saat login.';
        }
      });
    } catch (e) {
      print("Unexpected error: $e");
      setState(() {
        _generalError = 'Terjadi kesalahan tak terduga.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/icon/logo2.png',
                  height: 200,
                  width: 200,
                ),
                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _emailError.isNotEmpty ? _emailError : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _passwordError.isNotEmpty ? _passwordError : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffff57c00),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // General Error Message
                if (_generalError.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _generalError,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Belum punya akun?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        'Daftar',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
