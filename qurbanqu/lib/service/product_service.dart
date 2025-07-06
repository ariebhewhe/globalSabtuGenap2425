// service/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qurbanqu/model/product_model.dart'; // Pastikan path import model sudah benar

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'Products'; // Nama koleksi di Firestore

  // Mengambil semua produk dari Firestore
  Future<List<ProductModel>> getAllProducts() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();
      List<ProductModel> productList =
          snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Menambahkan ID dokumen ke dalam data sebelum membuat ProductModel
            data['id'] = doc.id;
            return ProductModel.fromJson(data);
          }).toList();
      return productList;
    } catch (e) {
      print('Error mengambil produk: $e');
      throw Exception('Gagal mengambil data produk');
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(productId).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Penting: Pastikan ID dokumen disertakan saat membuat ProductModel
        // Jika ProductModel.fromJson tidak mengharapkan 'id' dari map,
        // dan mengambilnya dari parameter terpisah, sesuaikan di sini.
        // Berdasarkan ProductModel Anda, 'id' sudah diharapkan ada di json map.
        data['id'] = doc.id; // Baris ini memastikan 'id' ada di map
        return ProductModel.fromJson(data);
      }
      return null; // Produk tidak ditemukan
    } catch (e) {
      print('Error mengambil produk by ID ($productId): $e');
      // throw Exception('Gagal mengambil data produk'); // Bisa dilempar atau return null
      return null;
    }
  }

  // Mengambil produk berdasarkan jenis (filter)
  Future<List<ProductModel>> getProductsByType(String jenis) async {
    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection(_collectionName)
              .where('jenis', isEqualTo: jenis)
              .get();
      List<ProductModel> productList =
          snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return ProductModel.fromJson(data);
          }).toList();
      return productList;
    } catch (e) {
      print('Error mengambil produk berdasarkan jenis: $e');
      throw Exception('Gagal mengambil data produk berdasarkan jenis');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      // When adding, Firestore generates the ID.
      // We use the toMap() method but exclude the 'id' if it were included there.
      // Your current toMap() method already excludes 'id', which is correct for add.
      await _firestore.collection(_collectionName).add(product.toMap());
      print('Product added successfully!');
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  // --- Update Method ---
  Future<void> updateProduct(ProductModel product) async {
    try {
      // When updating, we need the existing document ID.
      // We use the toMap() method to get the data to update.
      // Ensure your ProductModel has the ID when passed to this method.
      await _firestore
          .collection(_collectionName)
          .doc(product.id) // Use the product's existing ID
          .update(product.toMap());
      print('Product updated successfully!');
    } catch (e) {
      print('Error updating product with ID ${product.id}: $e');
      rethrow;
    }
  }

   Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collectionName).doc(productId).delete();
      print('Product with ID $productId deleted successfully!');
    } catch (e) {
      print('Error deleting product with ID $productId: $e');
      rethrow;
    }
  }


  // Anda bisa menambahkan method lain di sini sesuai kebutuhan,
  // misalnya getProductById, addProduct, updateProduct, deleteProduct, dll.
}
