import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:http/http.dart' as http;

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

class OrderService {
  final _createOrderUrl =
      "https://midtrans-handler-rizz4048298-5kqft3c9.leapcell.dev/v1/orders";

  Future<OrderModel> createOrder(CreateOrderDto params) async {
    try {
      final response = await http.post(
        Uri.parse(_createOrderUrl),
        body: params.toMap(),
      );

      final result = jsonDecode(response.body);

      return OrderModel.fromJson(result);
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }
}
