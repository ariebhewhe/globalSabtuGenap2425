import 'package:flutter/material.dart'; // Tambahkan ini untuk Icons
import 'package:firebase_database/firebase_database.dart';

class MenuData {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref().child('menu');

  static final List<Map<String, dynamic>> categories = [
    {'name': 'Makanan', 'icon': Icons.restaurant},
    {'name': 'Minuman', 'icon': Icons.local_drink},
    {'name': 'Snack', 'icon': Icons.fastfood},
  ];

  static Stream<List<Map<String, dynamic>>> getMenuItems() {
    return _database.onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
      if (data == null) return [];

      return data.entries.map((entry) {
        final item = entry.value as Map<dynamic, dynamic>;
        return {
          'id': entry.key,
          'name': item['name'] ?? '',
          'price': item['price'] ?? 0,
          'description': item['description'] ?? '',
          'image': item['imageUrl'] ?? '',
          'rating': item['rating']?.toDouble() ?? 4.5,
          'category': item['category'] ?? 'Makanan',
        };
      }).toList();
    });
  }
}