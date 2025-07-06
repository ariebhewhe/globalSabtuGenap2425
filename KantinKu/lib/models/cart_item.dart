// models/cart_item.dart
class CartItem {
  final String name;
  final int price; // Changed to int for easier calculation
  final String image;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });
}
