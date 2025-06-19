import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/routes/app_router.dart';
import 'package:jamal/core/utils/currency_utils.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/order_item_model.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/features/cart/providers/selected_cart_items_provider.dart';
import 'package:jamal/features/order/providers/order_mutation_provider.dart';
import 'package:jamal/features/order/providers/order_mutation_state.dart';
import 'package:jamal/features/payment_method/providers/payment_methods_provider.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_tables_provider.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminCreateOrderScreen extends ConsumerStatefulWidget {
  const AdminCreateOrderScreen({super.key});

  @override
  ConsumerState createState() => _AdminCreateOrderScreenState();
}

class _AdminCreateOrderScreenState
    extends ConsumerState<AdminCreateOrderScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  List<OrderItemModel> _orderItems = [];
  OrderType _selectedOrderType = OrderType.dineIn;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _convertCartItemsToOrderItems();
        setState(() {});
      }
    });
  }

  void _convertCartItemsToOrderItems() {
    final selectedCartItems = ref.read(selectedCartItemsProvider);

    _orderItems =
        selectedCartItems.map((cartItem) {
          return OrderItemModel(
            id: cartItem.id,
            orderId: '0',
            menuItemId: cartItem.menuItemId,
            quantity: cartItem.quantity,
            price: cartItem.menuItem?.price ?? 0,
            total: (cartItem.menuItem?.price ?? 0) * cartItem.quantity,
            menuItem: cartItem.menuItem,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
  }

  double _calculateTotal() {
    return _orderItems.fold(0, (total, item) => total + item.total);
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedOrderType = OrderType.dineIn;
      _convertCartItemsToOrderItems();
    });
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      CreateTableReservationDto? tableReservation;
      if (_selectedOrderType == OrderType.dineIn) {
        final selectedTable =
            formValues['selectedRestaurantTable'] as RestaurantTableModel?;
        if (selectedTable != null) {
          tableReservation = CreateTableReservationDto(
            tableId: selectedTable.id,
            reservationTime:
                formValues['estimatedReadyTime'] as DateTime? ?? DateTime.now(),
            table: selectedTable,
          );
        } else {
          ToastUtils.showWarning(
            context: context,
            message: 'Meja belum dipilih',
          );
          return;
        }
      }

      final newOrder = CreateOrderDto(
        paymentMethodId: formValues['paymentMethodId'] as String,
        orderType: _selectedOrderType,
        estimatedReadyTime: formValues['estimatedReadyTime'] as DateTime?,
        specialInstructions: formValues['specialInstructions'] as String?,
        tableReservation: tableReservation,
        orderItems: _orderItems,
      );

      await ref.read(orderMutationProvider.notifier).addOrderAdmin(newOrder);

      ref.read(selectedCartItemsProvider.notifier).clearSelectedItems();
    }
  }

  Widget _buildRestaurantTableDropdown(
    List<RestaurantTableModel> availableTables,
  ) {
    final restaurantTablesState = ref.watch(restaurantTablesProvider);

    if (restaurantTablesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurantTablesState.errorMessage != null) {
      return Center(
        child: Text(
          'Error loading tables: ${restaurantTablesState.errorMessage}',
          style: TextStyle(color: context.theme.colorScheme.error),
        ),
      );
    }

    return FormBuilderDropdown<RestaurantTableModel>(
      name: 'selectedRestaurantTable',
      decoration: const InputDecoration(
        labelText: 'Pilih Meja',
        border: OutlineInputBorder(),
        hintText: 'Pilih meja yang tersedia',
      ),
      items:
          availableTables
              .map(
                (table) => DropdownMenuItem<RestaurantTableModel>(
                  value: table,
                  child: Text(
                    'Meja ${table.tableNumber} (Kapasitas: ${table.capacity}) - ${table.location.name}',
                  ),
                ),
              )
              .toList(),
      validator:
          _selectedOrderType == OrderType.dineIn
              ? FormBuilderValidators.required(
                errorText: 'Silakan pilih meja untuk makan di tempat',
              )
              : null,
    );
  }

  Widget _buildPaymentMethodDropdown() {
    final paymentMethodsState = ref.watch(paymentMethodsProvider);
    final paymentMethods = paymentMethodsState.paymentMethods.where(
      (paymentMethod) =>
          (paymentMethod.adminPaymentCode?.isNotEmpty ?? false) ||
          (paymentMethod.adminPaymentQrCodePicture?.isNotEmpty ?? false),
    );

    if (paymentMethodsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (paymentMethodsState.errorMessage != null) {
      return Center(
        child: Text(
          'Error loading payment methods: ${paymentMethodsState.errorMessage}',
          style: TextStyle(color: context.theme.colorScheme.error),
        ),
      );
    }

    return FormBuilderDropdown<String>(
      name: 'paymentMethodId',
      decoration: const InputDecoration(
        labelText: 'Metode Pembayaran',
        border: OutlineInputBorder(),
        hintText: 'Pilih metode pembayaran',
      ),
      items:
          paymentMethods
              .map(
                (method) => DropdownMenuItem(
                  value: method.id,
                  child: Row(
                    children: [
                      if (method.logo != null) ...[
                        CachedNetworkImage(
                          width: 24,
                          height: 24,
                          imageUrl: method.logo!,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => const SizedBox(
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.error_outline, size: 24),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(method.name),
                    ],
                  ),
                ),
              )
              .toList(),
      validator: FormBuilderValidators.required(
        errorText: 'Silakan pilih metode pembayaran',
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderMutationState = ref.watch(orderMutationProvider);
    final restaurantTablesState = ref.watch(restaurantTablesProvider);

    final availableTables =
        restaurantTablesState.restaurantTables
            .where((table) => table.isAvailable)
            .toList();

    if (_orderItems.isEmpty && ref.read(selectedCartItemsProvider).isNotEmpty) {
      _convertCartItemsToOrderItems();
    }

    ref.listen<OrderMutationState>(orderMutationProvider, (previous, next) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(orderMutationProvider.notifier).resetErrorMessage();
      }

      if (next.successMessage != null &&
          (previous?.successMessage != next.successMessage)) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(orderMutationProvider.notifier).resetSuccessMessage();

        context.router.pushAndPopUntil(
          const AdminOrdersRoute(),
          predicate: (route) => route.isFirst,
        );
      }
    });

    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Pesanan',
                  style: context.theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FormBuilderDropdown<OrderType>(
                  name: 'orderType',
                  decoration: const InputDecoration(
                    labelText: 'Jenis Pesanan',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedOrderType,
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
                  onChanged: (value) {
                    setState(() {
                      _selectedOrderType = value ?? OrderType.dineIn;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedOrderType == OrderType.dineIn) ...[
                  _buildRestaurantTableDropdown(availableTables),
                  const SizedBox(height: 16),
                  FormBuilderDateTimePicker(
                    name: 'estimatedReadyTime',
                    decoration: const InputDecoration(
                      labelText: 'Waktu Reservasi',
                      border: OutlineInputBorder(),
                      hintText: 'Pilih waktu reservasi',
                    ),
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                    initialValue: DateTime.now().add(
                      const Duration(minutes: 30),
                    ),
                    validator:
                        _selectedOrderType == OrderType.dineIn
                            ? FormBuilderValidators.required(
                              errorText: 'Silakan pilih waktu reservasi',
                            )
                            : null,
                  ),
                ] else ...[
                  FormBuilderDateTimePicker(
                    name: 'estimatedReadyTime',
                    decoration: const InputDecoration(
                      labelText: 'Perkiraan Waktu Siap',
                      border: OutlineInputBorder(),
                      hintText: 'Pilih waktu',
                    ),
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                    initialValue: DateTime.now().add(
                      const Duration(minutes: 30),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildPaymentMethodDropdown(),
                const SizedBox(height: 16),
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
                Text('Item Pesanan', style: context.theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                if (_orderItems.isEmpty)
                  const Center(child: Text('Keranjang belanja Anda kosong.'))
                else
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
                                  child: CachedNetworkImage(
                                    width: 60,
                                    height: 60,
                                    imageUrl: item.menuItem!.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                  ),
                                )
                                : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.no_photography,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        title: Text(item.menuItem?.name ?? 'Item Menu'),
                        subtitle: Text(
                          '${CurrencyUtils.formatToRupiah(item.price)} x ${item.quantity}',
                        ),
                        trailing: Text(
                          CurrencyUtils.formatToRupiah(item.total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        context.theme.brightness == Brightness.dark
                            ? context.theme.colorScheme.surfaceContainerHighest
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatToRupiah(_calculateTotal()),
                        style: context.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Reset'),
                        onPressed:
                            orderMutationState.isLoading ? null : _resetForm,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        child:
                            orderMutationState.isLoading
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.theme.colorScheme.onPrimary,
                                    ),
                                    strokeWidth: 2.0,
                                  ),
                                )
                                : const Text('Order'),
                        onPressed:
                            orderMutationState.isLoading ||
                                    ref
                                        .watch(paymentMethodsProvider)
                                        .isLoading ||
                                    restaurantTablesState.isLoading
                                ? null
                                : _submitForm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getOrderTypeLabel(OrderType type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Makan di Tempat';
      case OrderType.takeAway:
        return 'Bawa Pulang';
    }
  }
}
