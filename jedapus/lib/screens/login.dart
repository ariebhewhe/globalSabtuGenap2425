import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController();
  bool _obscureTextPassword = true;

  static const Color primaryColor = Color(0xFFFDD835);
  static const Color darkGrey = Color(0xFF424242);

  static const String loginTitle = 'Selamat Datang Kembali!';
  static const String loginSubtitle = 'Masuk untuk melanjutkan cuti Anda.';
  static const String nikLabel = 'NIK'; 
  static const String passwordLabel = 'Kata Sandi';
  static const String loginButton = 'Masuk';
  static const String forgotPassword = 'Lupa Kata Sandi?';

  Future<void> _login() async {
    final nik = _emailController.text.trim();
    final password = _passwordController.text;

    if (nik.isEmpty || password.isEmpty) {
      _showErrorDialog('NIK dan Kata Sandi harus diisi!');
      return;
    }

    try {
      _showLoading();

      final admin =
          await Supabase.instance.client
              .from('admin')
              .select()
              .eq('nik', nik)
              .eq('password', password)
              .maybeSingle();

      if (admin != null) {
        if (mounted) Navigator.of(context).pop(); 
        final adminId = admin['id_admin'];
        if (mounted) Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard(idAdmin: adminId)),
        );
        return;
      }

      final karyawan =
          await Supabase.instance.client
              .from('karyawan')
              .select()
              .eq('nik', nik)
              .eq('password', password)
              .maybeSingle();

      if (mounted) Navigator.of(context).pop(); 

      if (karyawan != null) {
        final karyawanId = karyawan['id_karyawan'];
        if (mounted) {
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(idUser: karyawanId)),
        );
        }
      } else {
        _showErrorDialog('NIK atau Kata Sandi salah.');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Tutup loading
      _showErrorDialog('Terjadi kesalahan saat login. Silakan coba lagi.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [             
              Image.asset(
                'lib/assets/images/logos.png', 
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
              const SizedBox(height: 10),
              const Text(
                'Memuat...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: screenWidth,
              height: screenHeight,
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.8)),
              child: Stack(
                children: [
                  Positioned(
                    top: -90,
                    right: -180,
                    child: Container(
                      width: 500,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withOpacity(0.5),
                            primaryColor.withOpacity(0.8),
                          ],
                          stops: const [0.4, 1.0],
                          radius: 0.3,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.06),
                        Image.asset(
                          'lib/assets/images/logos.png', 
                          width: screenWidth * 0.45,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          loginSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              top:
                  keyboardHeight > 0
                      ? screenHeight * 0.20
                      : screenHeight * 0.35,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 3,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          loginTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: darkGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.065,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildTextField(
                          controller: _emailController,
                          labelText: nikLabel, 
                          icon: Icons.badge_outlined, 
                          keyboardType: TextInputType.number, 
                          fontSize: 16,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildPasswordField(
                          controller: _passwordController,
                          labelText: passwordLabel,
                          obscureText: _obscureTextPassword,
                          onPressedSuffix: () {
                            setState(() {
                              _obscureTextPassword = !_obscureTextPassword;
                            });
                          },
                          fontSize: 16,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Aksi untuk lupa kata sandi
                            },
                            child: const Text(
                              forgotPassword,
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: darkGrey,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            loginButton,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    double fontSize = 16,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => value == null || value.isEmpty ? 'Harap isi $labelText' : null,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: darkGrey.withOpacity(0.7),
          fontSize: fontSize,
        ),
        prefixIcon:
            icon != null
                ? Icon(icon, color: primaryColor.withOpacity(0.7))
                : null,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 10.0,
        ),
        fillColor: Colors.grey.shade50,
        filled: true,
      ),
      style: TextStyle(color: darkGrey, fontSize: fontSize),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback onPressedSuffix,
    double fontSize = 16,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) => value == null || value.isEmpty ? 'Harap isi $labelText' : null,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: darkGrey.withOpacity(0.7),
          fontSize: fontSize,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: primaryColor.withOpacity(0.7),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: darkGrey.withOpacity(0.7),
          ),
          onPressed: onPressedSuffix,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 10.0,
        ),
        fillColor: Colors.grey.shade50,
        filled: true,
      ),
      style: TextStyle(color: darkGrey, fontSize: fontSize),
    );
  }
}