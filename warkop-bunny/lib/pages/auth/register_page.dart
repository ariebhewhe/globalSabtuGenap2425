import 'package:flutter/material.dart';
import 'package:warkop_bunny/services/auth_service.dart';
import 'package:warkop_bunny/pages/auth/login_page.dart';
import 'package:warkop_bunny/pages/main_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // get auth service
  final AuthService authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    // ensure that the email & password fields are not empty
    if (email.isNotEmpty && password.isNotEmpty && confirmPassword.isNotEmpty) {
      // ensure that the passwords match
      if (password == confirmPassword) {
        try {
          setState(() {
            _isLoading = true;
          });
          // sign up logic here
          await authService.signUpWithEmailPassword(email, password);

          // login otomatis setelah register
          await authService.signInWithEmailPassword(email, password);

          // navigasi ke MainPage dan hapus semua halaman sebelumnya
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainPage()),
              (route) => false,
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Passwords don't match")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
    }

    setState(() {
      _isLoading = false;
    });
    // if (_formKey.currentState!.validate()) {
    //   if (!_agreeToTerms) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Harap setujui syarat dan ketentuan'),
    //         backgroundColor: Colors.red[700],
    //       ),
    //     );
    //     return;
    //   }

    //   setState(() {
    //     _isLoading = true;
    //   });

    //   // Simulasi proses register
    //   await Future.delayed(Duration(seconds: 2));

    //   setState(() {
    //     _isLoading = false;
    //   });

    //   // Tampilkan pesan sukses
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Pendaftaran berhasil! Selamat bergabung di Warkop!'),
    //       backgroundColor: Colors.green[700],
    //     ),
    //   );
    // }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B4513), // Saddle Brown
              Color(0xFF654321), // Dark Brown
              Color(0xFF3E2723), // Very Dark Brown
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Warkop
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.local_cafe,
                      size: 80,
                      color: Colors.orange[300],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Title
                  Text(
                    'WARKOP BUNNY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'HALAMAN REGISTER',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[200],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Register Form
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Welcome Text
                          Text(
                            'Daftar Akun Baru',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),

                          Text(
                            'Isi data diri untuk bergabung',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.brown[600],
                            ),
                          ),

                          SizedBox(height: 32),

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.brown[700],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[700]!,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.brown[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              if (value.length < 2) {
                                return 'Nama minimal 2 karakter';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.brown[700],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[700]!,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.brown[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Nomor HP',
                              prefixIcon: Icon(
                                Icons.phone,
                                color: Colors.brown[700],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[700]!,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.brown[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nomor HP tidak boleh kosong';
                              }
                              if (!RegExp(r'^[0-9+\-\s]+$').hasMatch(value)) {
                                return 'Format nomor HP tidak valid';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Colors.brown[700],
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.brown[700],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[700]!,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.brown[50],
                            ),
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

                          SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.brown[700],
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.brown[700],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.brown[700]!,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.brown[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (value != _passwordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),

                          SizedBox(height: 24),

                          // Register Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[700],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'DAFTAR',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),

                          SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.brown[300]),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'atau',
                                  style: TextStyle(color: Colors.brown[600]),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.brown[300]),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // Login Button
                          OutlinedButton(
                            onPressed: () {
                              // Navigasi ke halaman Login
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.brown[700],
                              side: BorderSide(color: Colors.brown[700]!),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'SUDAH PUNYA AKUN? MASUK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Footer
                  Text(
                    '☕ Powered by Warkop Bunny ☕',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
