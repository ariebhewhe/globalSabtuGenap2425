import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/order_item_model.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/features/cart/providers/selected_cart_items_provider.dart';
import 'package:jamal/features/order/providers/order_mutation_provider.dart';
import 'package:jamal/shared/widgets/user_app_bar.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  List<OrderItemModel> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _convertCartItemsToOrderItems();
  }

  void _convertCartItemsToOrderItems() {
    final selectedCartItems = ref.read(selectedCartItemsProvider);

    _orderItems =
        selectedCartItems.map((cartItem) {
          return OrderItemModel(
            id: cartItem.id,
            orderId: 0,
            menuItemId: int.parse(cartItem.menuItemId),
            quantity: cartItem.quantity,
            price: cartItem.menuItem?.price ?? 0,
            subtotal: (cartItem.menuItem?.price ?? 0) * cartItem.quantity,
            menuItem: cartItem.menuItem,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
  }

  double _calculateTotal() {
    return _orderItems.fold(0, (total, item) => total + item.subtotal);
  }

  void _resetForm() {
    _formKey.currentState?.reset();
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      final newOrder = CreateOrderDto(
        tableId:
            formValues['tableId'] != null
                ? int.tryParse(formValues['tableId'].toString())
                : null,
        orderType: formValues['orderType'] ?? OrderType.dineIn,
        paymentMethodType:
            formValues['paymentMethod'] ?? PaymentMethodType.cash,
        estimatedReadyTime: formValues['estimatedReadyTime'],
        specialInstructions: formValues['specialInstructions'],
        orderItems: _orderItems,
      );

      await ref.read(orderMutationProvider.notifier).addOrder(newOrder);

      ref.read(selectedCartItemsProvider.notifier).clearSelectedItems();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pesanan berhasil dibuat!')));

      context.router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderMutation = ref.watch(orderMutationProvider);
    final isLoading = orderMutation.isLoading;

    return Scaffold(
      appBar: const UserAppBar(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informasi pesanan
                Text(
                  'Informasi Pesanan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Jenis Pesanan
                FormBuilderDropdown<OrderType>(
                  name: 'orderType',
                  decoration: const InputDecoration(
                    labelText: 'Jenis Pesanan',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: OrderType.dineIn,
                  items:
                      OrderType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(_getOrderTypeLabel(type)),
                            ),
                          )
                          .toList(),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),

                // ID Meja (hanya untuk dine-in)
                FormBuilderTextField(
                  name: 'tableId',
                  decoration: const InputDecoration(
                    labelText: 'Nomor Meja',
                    border: OutlineInputBorder(),
                    hintText: 'Masukkan nomor meja',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Metode Pembayaran
                FormBuilderDropdown<PaymentMethodType>(
                  name: 'paymentMethod',
                  decoration: const InputDecoration(
                    labelText: 'Metode Pembayaran',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: PaymentMethodType.cash,
                  items:
                      PaymentMethodType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(_getPaymentMethodLabel(type)),
                            ),
                          )
                          .toList(),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 16),

                // Waktu Perkiraan Siap
                FormBuilderDateTimePicker(
                  name: 'estimatedReadyTime',
                  decoration: const InputDecoration(
                    labelText: 'Perkiraan Waktu Siap',
                    border: OutlineInputBorder(),
                    hintText: 'Pilih waktu',
                  ),
                  inputType: InputType.both,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  initialValue: DateTime.now().add(const Duration(minutes: 30)),
                ),
                const SizedBox(height: 16),

                // Instruksi Khusus
                FormBuilderTextField(
                  name: 'specialInstructions',
                  decoration: const InputDecoration(
                    labelText: 'Instruksi Khusus',
                    border: OutlineInputBorder(),
                    hintText: 'Tambahkan instruksi khusus (opsional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Daftar item pesanan
                Text(
                  'Item Pesanan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Daftar item
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orderItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _orderItems[index];
                    return ListTile(
                      leading:
                          item.menuItem?.imageUrl != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.menuItem!.imageUrl!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.restaurant),
                                      ),
                                ),
                              )
                              : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.restaurant),
                              ),
                      title: Text(item.menuItem?.name ?? 'Item Menu'),
                      subtitle: Text(
                        'Rp ${item.price.toStringAsFixed(0)} x ${item.quantity}',
                      ),
                      trailing: Text(
                        'Rp ${item.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Total pesanan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'Rp ${_calculateTotal().toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Reset'),
                        onPressed: _resetForm,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        child: const Text('Order'),
                        onPressed: isLoading ? null : _submitForm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk label jenis pesanan
  String _getOrderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Makan di Tempat';
      case OrderType.takeAway:
        return 'Bawa Pulang';
    }
  }

  // Helper untuk label metode pembayaran
  String _getPaymentMethodLabel(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return 'Tunai';
      case PaymentMethodType.creditCard:
        return 'Kartu Kredit';
      case PaymentMethodType.debitCard:
        return 'Kartu Debit';
      case PaymentMethodType.eWallet:
        return 'E-Wallet';
    }
  }
}
