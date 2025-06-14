import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';

// FirebaseService.dart digunakan untuk menginisialisasi Firebase
// dan menyediakan instance dari FirebaseAuth, Firestore, dan FirebaseMessaging
class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up Firebase Messaging
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      
      // Get FCM token
      String? token = await messaging.getToken();
      print('FCM Token: $token');
    } catch (e) {
      print('Firebase init error: $e');
    }
  }

  // Firebase Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Messaging instance
  static FirebaseMessaging get messaging => FirebaseMessaging.instance;
}