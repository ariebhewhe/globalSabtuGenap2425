import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_table_mutation_provider.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/features/restaurant_table/providers/restaurant_table_mutation_state.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminRestaurantTableUpsertScreen extends ConsumerStatefulWidget {
  final RestaurantTableModel? restaurantTable;

  const AdminRestaurantTableUpsertScreen({super.key, this.restaurantTable});

  @override
  ConsumerState<AdminRestaurantTableUpsertScreen> createState() =>
      _AdminRestaurantTableUpsertScreenState();
}

class _AdminRestaurantTableUpsertScreenState
    extends ConsumerState<AdminRestaurantTableUpsertScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  void _resetForm() {
    _formKey.currentState?.reset();
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      if (widget.restaurantTable != null) {
        final updateRestaurantTable = UpdateRestaurantTableDto(
          tableNumber: formValues['tableNumber'] as String,
          capacity: int.tryParse(formValues['capacity'].toString()) ?? 0,
          isAvailable: formValues['isAvailable'] as bool,
          location: formValues['location'] as Location,
        );

        await ref
            .read(restaurantTableMutationProvider.notifier)
            .updateRestaurantTable(
              widget.restaurantTable!.id,
              updateRestaurantTable,
            );
      } else {
        final createRestaurantTable = CreateRestaurantTableDto(
          tableNumber: formValues['tableNumber'] as String,
          capacity: int.tryParse(formValues['capacity'].toString()) ?? 0,
          isAvailable: formValues['isAvailable'] as bool,
          location: formValues['location'] as Location,
        );

        await ref
            .read(restaurantTableMutationProvider.notifier)
            .addRestaurantTable(createRestaurantTable);
      }

      if (ref.read(restaurantTableMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(restaurantTableMutationProvider);

    final isSubmitting = mutationState.isLoading;

    ref.listen<RestaurantTableMutationState>(restaurantTableMutationProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(restaurantTableMutationProvider.notifier).resetErrorMessage();
      }

      if (next.successMessage != null &&
          (previous?.successMessage != next.successMessage)) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref
            .read(restaurantTableMutationProvider.notifier)
            .resetSuccessMessage();

        context.router.pop();
      }
    });
    return Scaffold(
      appBar: const AdminAppBar(),
      drawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: isSubmitting,
            child: FormBuilder(
              key: _formKey,

              initialValue: {
                'tableNumber': widget.restaurantTable?.tableNumber ?? '',
                'capacity': widget.restaurantTable?.capacity.toString() ?? '',
                'location': widget.restaurantTable?.location,
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormBuilderTextField(
                    name: 'tableNumber',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Table Number',
                      labelText: 'Table Number',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.maxLength(50),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'capacity',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Capacity',
                      labelText: 'Capacity',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                      FormBuilderValidators.numeric(),
                      FormBuilderValidators.min(0),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderSwitch(
                    name: 'isAvailable',
                    title: const Text('Available'),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                  const SizedBox(height: 16),

                  FormBuilderDropdown<Location>(
                    name: 'location',
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                    items:
                        Location.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.name),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child:
                              isSubmitting
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    widget.restaurantTable != null
                                        ? 'Update'
                                        : 'Submit',
                                    style: TextStyle(fontSize: 18),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
