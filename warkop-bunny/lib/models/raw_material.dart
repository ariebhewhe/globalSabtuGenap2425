class RawMaterial {
  String id;
  String name;
  String supplier;
  int stock;
  String unit;
  int minStock;
  double price;
  DateTime lastRestocked;
  DateTime expiryDate;

  RawMaterial({
    required this.id,
    required this.name,
    required this.supplier,
    required this.stock,
    required this.unit,
    required this.minStock,
    required this.price,
    required this.lastRestocked,
    required this.expiryDate,
  });
}
