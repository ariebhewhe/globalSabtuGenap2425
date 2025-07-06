class OrderModel {
  final String id;
  final DateTime? date;
  final String status;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    this.date,
    required this.status,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    DateTime? orderDate;
    
    // Parse date if available
    if (json['orderDate'] != null && json['orderDate'].toString().isNotEmpty) {
      try {
        orderDate = DateTime.parse(json['orderDate']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    
    // Parse items
    List<OrderItemModel> orderItems = [];
    if (json['items'] != null) {
      final List<dynamic> items = json['items'] as List<dynamic>;
      orderItems = items
          .where((item) => item != null)
          .map((item) => OrderItemModel.fromJson(item as Map<dynamic, dynamic>))
          .toList();
    }
    
    return OrderModel(
      id: json['id'],
      date: orderDate,
      status: json['status'] ?? 'unknown',
      items: orderItems,
    );
  }

  // Calculate total for this order
  double calculateTotal() {
    double total = 0;
    for (var item in items) {
      total += item.price * item.quantity;
    }
    return total;
  }
}

class OrderItemModel {
  final String name;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<dynamic, dynamic> json) {
    double price = 0;
    int quantity = 0;
    
    // Safely extract price and quantity
    if (json['price'] != null) {
      price = (json['price'] is num) ? (json['price'] as num).toDouble() : 0;
    }
    
    if (json['quantity'] != null) {
      quantity = (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 0;
    }
    
    return OrderItemModel(
      name: json['name'] ?? 'Unknown Item',
      price: price,
      quantity: quantity,
    );
  }
}