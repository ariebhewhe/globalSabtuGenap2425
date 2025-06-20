import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/utils/logger.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

class OrderService {
  final _createOrderUrl =
      "https://midtrans-handler-rizz4048298-5kqft3c9.leapcell.dev/v1/orders";

  Future<OrderModel> createOrder(CreateOrderDto params) async {
    final requestBody = jsonEncode(params.toMap());

    developer.log(requestBody, name: 'OrderService.createOrder');
    try {
      AppLogger().i(jsonEncode(params.toMap()));
      final response = await http.post(
        Uri.parse(_createOrderUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(params.toMap()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return OrderModel.fromMap(result as Map<String, dynamic>);
      } else {
        final errorBody = jsonDecode(response.body);
        AppLogger().e("from service", errorBody.toString());
        throw Exception(
          'Failed to create order: ${errorBody['error'] ?? response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create order: ${e.toString()}');
    }
  }
}
