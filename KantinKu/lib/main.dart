import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kantinku/screens/loading_screen.dart';
import 'package:lottie/lottie.dart';
import 'screens/auth/login_page.dart';
import 'screens/admin/admin_page.dart';
import 'screens/home/home_page.dart';
import 'package:app_links/app_links.dart';
import 'dart:io';
import 'deeplink_handler.dart';
import 'package:kantinku/data/notification_service.dart';
import 'utils/notification_utils.dart';
import 'dart:math';
import 'models/user_details.dart';

bool _initialUriIsHandled = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAHbcFaHjY-LXknguuSz489PcrUFqyqhj4",
        appId: "1:323941923576:android:22ed2d48c8f9c514f3190d",
        messagingSenderId: "323941923576",
        projectId: "kantinku-5b541",
        databaseURL: "https://kantinku-5b541-default-rtdb.asia-southeast1.firebasedatabase.app",
        storageBucket: "kantinku-5b541.appspot.com",
      ),
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  try {
    await NotificationService.initialize();
    print('✅ Notification service initialized');
  } catch (e) {
    print('❌ Notification service init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  Uri? _initialUri;
  StreamSubscription? _sub;
  bool _isInitializing = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _handleInitialUri();
    _checkUserLoginStatus();
    
    // Panggil fungsi notifikasi setelah frame pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentContext != null) {
        NotificationUtils.requestNotificationPermissions(_navigatorKey.currentContext!);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Fungsi baru untuk memeriksa status login user saat aplikasi dibuka
  Future<void> _checkUserLoginStatus() async {
    try {
      // Tunggu Firebase Auth untuk menginisialisasi
      await Future.delayed(const Duration(seconds: 1));
      
      // Cek apakah user sudah login atau belum
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        print('User sudah login dengan ID: ${currentUser.uid}');
        
        // Ambil data user dari database untuk menentukan role
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .get();
            
        if (snapshot.exists) {
          Map<String, dynamic> userData;
          
          if (snapshot.value is Map) {
            userData = Map<String, dynamic>.from(snapshot.value as Map);
          } else if (snapshot.value is List) {
            final list = snapshot.value as List;
            final firstNonNull = list.firstWhere((element) => element != null, orElse: () => null);
            if (firstNonNull is Map) {
              userData = Map<String, dynamic>.from(firstNonNull);
            } else {
              throw Exception('Invalid data structure in database');
            }
          } else {
            throw Exception('Unexpected data type: ${snapshot.value.runtimeType}');
          }
          
          // Simpan role untuk digunakan di build method
          setState(() {
            _userRole = userData['role'];
            _isInitializing = false;
          });
          
          print('User role: $_userRole');
        } else {
          // User tidak ditemukan di database
          print('User data tidak ditemukan di database');
          await FirebaseAuth.instance.signOut();
          setState(() {
            _isInitializing = false;
          });
        }
      } else {
        // User belum login
        print('User belum login');
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error saat cek status login: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  // Handle incoming links - the ones that the app will receive from the OS
  // while already started.
  void _handleIncomingLinks() {
    if (!Platform.isWindows && !Platform.isLinux) {
      // It will handle app links while the app is already started - be it in
      // the foreground or in the background.
      _sub = AppLinks().uriLinkStream.listen((Uri? uri) {
        if (!mounted) return;
        print('URI link stream: $uri');
        _processDeepLink(uri);
      }, onError: (Object err) {
        if (!mounted) return;
        print('URI link error: $err');
      });
    }
  }

  // Handle the initial Uri - the one the app was started with
  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
       final appLinks = AppLinks();
       final uri = await appLinks.getInitialAppLink();
        if (uri == null) {
          print('No initial URI received');
        } else {
          print('Initial URI received: $uri');
          if (!mounted) return;
          _processDeepLink(uri);
        }
      } catch (e) {
        print('Error getting initial URI: $e');
      }
    }
  }

  void _processDeepLink(Uri? uri) {
    if (uri != null) {
      final pathSegments = uri.pathSegments;
      
      // Special handling for payment callbacks
      if (uri.toString().contains('payment/success') || uri.toString().contains('payment/failure')) {
        // Store the URI to be processed once the app is fully loaded
        _initialUri = uri;
        
        // If app is already loaded and BuildContext is available, handle immediately
        if (_navigatorKey.currentContext != null) {
          _handlePaymentDeepLink(uri, _navigatorKey.currentContext!);
        }
        return;
      }
      
      // Handle other deep links
      if (pathSegments.isNotEmpty) {
        if (pathSegments[0] == 'order' && pathSegments.length > 1) {
          final orderId = pathSegments[1];
          print('Navigating to order details: $orderId');
          _initialUri = uri;
        } else if (pathSegments[0] == 'admin') {
          print('Navigating to admin page');
          _initialUri = uri;
        }
      }
    }
  }

  // Handle payment callback links
  void _handlePaymentDeepLink(Uri uri, BuildContext context) {
    print('Handling payment deep link: $uri');

    if (uri.toString().contains('payment/success')) {
      // Extract order ID from query parameters
      String? orderId = _extractOrderId(uri);
      
      if (orderId != null) {
        // Update order status in Firebase
        _updateOrderStatus(orderId, 'paid');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to success page or order detail
        // You can add navigation here when you have the route ready
        // _navigatorKey.currentState?.pushReplacementNamed('/order-success', arguments: orderId);
      }
    } 
    else if (uri.toString().contains('payment/failure')) {
      // Extract order ID from query parameters
      String? orderId = _extractOrderId(uri);
      
      if (orderId != null) {
        // Update order status in Firebase
        _updateOrderStatus(orderId, 'failed');
        
        // Show failure message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran gagal atau dibatalkan'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Optional: Navigate to failure page
        // _navigatorKey.currentState?.pushReplacementNamed('/payment-failed');
      }
    }
  }

  // Extract order ID from URI
  String? _extractOrderId(Uri uri) {
    // Check if there's a query parameter for order_id
    if (uri.queryParameters.containsKey('order_id')) {
      return uri.queryParameters['order_id'];
    }
    
    // If not in query parameters, try to extract from path segments
    List<String> segments = uri.pathSegments;
    if (segments.length > 2 && segments[0] == 'payment') {
      return segments[2]; // Assuming format like "payment/success/ORDER123"
    }
    
    return null;
  }

  // Update order status in Firebase
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('orders')
          .child(orderId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      print('Order status updated: $orderId -> $status');
    } catch (e) {
      print('Failed to update order status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan halaman awal berdasarkan status login
    Widget initialScreen;
    
    if (_isInitializing) {
      // Jika masih memuat status, tampilkan loading screen
      initialScreen = const LoadingScreen();
    } else {
      if (_userRole == 'admin') {
        // Jika user adalah admin, arahkan ke halaman admin
        initialScreen = const AdminDashboard();
      } else if (_userRole != null) {
        // Jika user biasa sudah login, arahkan ke home page
        initialScreen = const HomePage();
      } else {
        // Jika belum login, arahkan ke halaman login
        initialScreen = const LoginPage();
      }
    }

    return MaterialApp(
      title: 'MyKantin',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: DeepLinkHandler(
        initialUri: _initialUri,
        child: initialScreen,
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin': (context) => const AdminDashboard(),
        '/home': (context) => const HomePage(),
        // Add other routes as needed
        // '/order-success': (context) => OrderSuccessPage(),
        // '/payment-failed': (context) => PaymentFailedPage(),
      },
    );
  }
}

// Widget untuk menangani deeplink setelah app selesai loading
class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  final Uri? initialUri;

  const DeepLinkHandler({
    Key? key,
    required this.child,
    this.initialUri,
  }) : super(key: key);

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cek apakah ada initialUri yang perlu diproses
    _processInitialUri(context);
  }

  void _processInitialUri(BuildContext context) {
    if (widget.initialUri != null) {
      final uri = widget.initialUri!;
      
      // Handle payment callbacks
      if (uri.toString().contains('payment/success') || uri.toString().contains('payment/failure')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Access MyApp state to use payment handling methods
          final myAppState = context.findAncestorStateOfType<_MyAppState>();
          if (myAppState != null) {
            myAppState._handlePaymentDeepLink(uri, context);
          }
        });
        return;
      }
      
      // Handle other deep links
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        if (pathSegments[0] == 'order' && pathSegments.length > 1) {
          final orderId = pathSegments[1];
          // Navigate to order details page
          // Example: Navigator.of(context).pushNamed('/order-details', arguments: orderId);
        } else if (pathSegments[0] == 'admin') {
          // Navigate to admin page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/admin');
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playSplashSound();
    _navigateToLogin();
  }

  Future<void> _playSplashSound() async {
    // Pastikan Anda menambahkan file suara ke folder `assets/sounds/` dan mendaftarkan di pubspec.yaml
    await _audioPlayer.play(AssetSource('sounds/splash_sound.mp3'));
  }

  void _navigateToLogin() {
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi Lottie
            Lottie.asset(
              'assets/animations/splash_animation.json', // Tambahkan file animasi JSON di folder assets
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const Text(
              'Kantinku',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}