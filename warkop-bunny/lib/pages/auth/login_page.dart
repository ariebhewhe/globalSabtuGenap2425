import 'package:flutter/material.dart';
import 'package:warkop_bunny/services/auth_service.dart';
import 'package:warkop_bunny/pages/auth/register_page.dart';
import 'package:warkop_bunny/pages/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // get auth service
  final AuthService authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    // attempt login..
    try {
      // ensure that the email & password fields are not empty
      if (email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });
        // login logic
        await authService.signInWithEmailPassword(email, password);

          // navigate to MainPage and remove all previous pages
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainPage()),
            (route) => false,
          );
        }
      } else {
        // display error if some fields are empty
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silahkan isi Email dan Password")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                      color: Colors.white.withAlpha(24),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(68),
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
                          color: Colors.black.withAlpha(127),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 8),

                  Text(
                    'HALAMAN LOGIN',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[200],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Login Form
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(238),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(68),
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
                            'Selamat Datang!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[800],
                            ),
                          ),
                          
                          Text(
                            'Silakan login untuk melanjutkan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.brown[600],
                            ),
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: Colors.brown[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.brown[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.brown[700]!, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.brown[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Format email tidak valid';
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
                              prefixIcon: Icon(Icons.lock, color: Colors.brown[700]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                                borderSide: BorderSide(color: Colors.brown[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.brown[700]!, width: 2),
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
                          
                          SizedBox(height: 8),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle forgot password
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Fitur lupa password belum tersedia')),
                                );
                              },
                              child: Text(
                                'Ubah Password?',
                                style: TextStyle(color: Colors.brown[700]),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'MASUK',
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
                              Expanded(child: Divider(color: Colors.brown[300])),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'atau',
                                  style: TextStyle(color: Colors.brown[600]),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.brown[300])),
                            ],
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Register Button
                          OutlinedButton(
                            onPressed: () {
                              // Navigasi ke halaman Register
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterPage()),
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
                              'DAFTAR',
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
