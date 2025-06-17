class Sale {
  String id;
  String productId;
  String productName;
  int quantity;
  double unitPrice;
  double totalPrice;
  DateTime saleDate;
  String customerName;
  String paymentMethod;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.saleDate,
    required this.customerName,
    required this.paymentMethod,
  });
}
