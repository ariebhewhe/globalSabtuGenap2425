import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playSound();

    // Navigasi ke halaman login setelah 5 detik
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  Future<void> _playSound() async {
    try {
      // Pastikan file suara ada di folder assets/sounds
      await _audioPlayer.setAsset('assets/sounds/loading_sound.mp3');
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop(); // Pastikan audio berhenti
    _audioPlayer.dispose(); // Hancurkan instance AudioPlayer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(  // Gunakan SingleChildScrollView untuk menghindari overflow
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animasi Lottie
              Lottie.asset(
                'assets/animations/loading.json',
                width: 150,
                height: 150,
                repeat: true,
                animate: true,
              ),
              const SizedBox(height: 20),
              // Teks deskripsi
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
