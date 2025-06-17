class Product {
  String id;
  String name;
  String category;
  double sellingPrice;
  int stock;
  String unit;
  String description;
  DateTime createdAt;
  String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.stock,
    required this.unit,
    required this.description,
    required this.createdAt,
    this.imageUrl = '',
  });

  // fromMap factory
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'],
      category: map['category'],
      // price: (map['price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stock: map['stock'],
      unit: map['unit'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'selling_price': sellingPrice,
      'stock': stock,
      'unit': unit,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}
