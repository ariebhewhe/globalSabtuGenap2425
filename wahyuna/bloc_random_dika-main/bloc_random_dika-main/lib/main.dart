import 'package:bloc_random_dika/random_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter demo - dika',
      theme: ThemeData(
        primarySwatch: Colors.blue
      ),
      home: const RandomScreen(),
    );
  }
}