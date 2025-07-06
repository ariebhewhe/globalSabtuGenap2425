import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qurbanqu/model/product_model.dart';

class ProductSeederPage extends StatefulWidget {
  const ProductSeederPage({super.key});

  static const String routeName = '/seeder-product';

  @override
  State<ProductSeederPage> createState() => _ProductSeederPageState();
}

class _ProductSeederPageState extends State<ProductSeederPage> {
  bool _isLoading = false;
  String _statusMessage =
      'Tekan tombol untuk memulai proses seeding data Product.';
  final String _targetCollection = 'Products';

  Future<void> _seedData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Memulai proses seeding...';
    });

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/kurban.json',
      );

      final List<dynamic> jsonData = json.decode(jsonString);
      if (jsonData.isEmpty) {
        setState(() {
          _statusMessage = 'File JSON kosong atau tidak valid.';
          _isLoading = false;
        });
        return;
      }

      _statusMessage =
          'Data JSON berhasil dibaca. Memproses ${jsonData.length} item...';
      setState(() {});

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final CollectionReference ProductCollection = firestore.collection(
        _targetCollection,
      );

      WriteBatch batch = firestore.batch();
      int successCount = 0;

      for (var itemMap in jsonData) {
        if (itemMap is Map<String, dynamic>) {
          try {
            final ProductModel ProductItem = ProductModel.fromJson(itemMap);

            DocumentReference docRef = ProductCollection.doc(ProductItem.id);

            batch.set(docRef, ProductItem.toMap());
            successCount++;
            _statusMessage = 'Menambahkan "${ProductItem.nama}" ke batch...';
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 20));
          } catch (e) {
            print('Error memproses item: $itemMap. Kesalahan: $e');
            _statusMessage =
                'Error memproses item: ${itemMap['nama'] ?? 'Unknown'}. Lewati.';
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      }

      if (successCount > 0) {
        _statusMessage = 'Mengirim $successCount item ke Firestore...';
        setState(() {});
        await batch.commit();
        _statusMessage =
            '$successCount data Product berhasil di-seed ke koleksi "$_targetCollection".';
      } else if (jsonData.isNotEmpty) {
        _statusMessage =
            'Tidak ada item valid yang dapat di-seed. Periksa format JSON atau error.';
      } else {
        _statusMessage = 'Tidak ada data untuk di-seed.';
      }
    } catch (e) {
      _statusMessage = 'Terjadi kesalahan saat seeding: $e';
      print('Error seeding data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seeder Data Product')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Seed Data ke Firestore'),
                  onPressed: _seedData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
