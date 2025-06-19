import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/order_model.dart';
import 'package:jamal/features/order/providers/order_mutation_provider.dart';
import 'package:jamal/features/order/providers/order_mutation_state.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminUpdateOrderScreen extends ConsumerStatefulWidget {
  final OrderModel? order;

  const AdminUpdateOrderScreen({super.key, this.order});

  @override
  ConsumerState<AdminUpdateOrderScreen> createState() =>
      _AdminUpdateOrderScreenState();
}

class _AdminUpdateOrderScreenState
    extends ConsumerState<AdminUpdateOrderScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      final updateOrderDto = UpdateOrderDto(
        orderType: formValues['orderType'] as OrderType,
        status: formValues['status'] as OrderStatus,
        paymentStatus: formValues['paymentStatus'] as PaymentStatus,
        estimatedReadyTime: formValues['estimatedReadyTime'] as DateTime,
      );

      await ref
          .read(orderMutationProvider.notifier)
          .updateOrder(widget.order!.id, updateOrderDto);

      if (ref.read(orderMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

        context.router.pop();
      }
    });
    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, child) {
              final mutationState = ref.watch(orderMutationProvider);

              return AbsorbPointer(
                absorbing: mutationState.isLoading,
                child: FormBuilder(
                  key: _formKey,
                  initialValue: {
                    'orderType': widget.order?.orderType ?? '',
                    'status': widget.order?.status ?? '',
                    'paymentStatus': widget.order?.paymentStatus ?? true,
                    'estimatedReadyTime':
                        widget.order?.estimatedReadyTime ?? false,
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormBuilderDropdown<OrderType>(
                        name: 'orderType',
                        decoration: const InputDecoration(
                          labelText: 'Order Type',
                          border: OutlineInputBorder(),
                          hintText: 'Order Type',
                        ),
                        items:
                            OrderType.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              );
                            }).toList(),
                        validator: FormBuilderValidators.required(
                          errorText: 'Silakan pilih Order Type',
                        ),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderDropdown<OrderStatus>(
                        name: 'status',
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          hintText: 'Order Status',
                        ),
                        items:
                            OrderStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              );
                            }).toList(),
                        validator: FormBuilderValidators.required(
                          errorText: 'Silakan pilih Order Status',
                        ),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderDropdown<PaymentStatus>(
                        name: 'paymentStatus',
                        decoration: const InputDecoration(
                          labelText: 'Payment Status',
                          border: OutlineInputBorder(),
                          hintText: 'Payment Status',
                        ),
                        items:
                            PaymentStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.name),
                              );
                            }).toList(),
                        validator: FormBuilderValidators.required(
                          errorText: 'Silakan pilih Payment Status',
                        ),
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                mutationState.isLoading ? null : _submitForm,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child:
                                  mutationState.isLoading
                                      ? const CircularProgressIndicator()
                                      : const Text('Update Order'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
