import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/table_reservation_model.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_mutation_provider.dart';
import 'package:jamal/features/table_reservation/providers/table_reservation_mutation_state.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminUpdateTableReservationScreen extends ConsumerStatefulWidget {
  final TableReservationModel? tableReservation;

  const AdminUpdateTableReservationScreen({super.key, this.tableReservation});

  @override
  ConsumerState<AdminUpdateTableReservationScreen> createState() =>
      _AdminUpdateTableReservationScreenState();
}

class _AdminUpdateTableReservationScreenState
    extends ConsumerState<AdminUpdateTableReservationScreen> {
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

      final updateTableReservationDto = UpdateTableReservationDto(
        status: formValues['status'] as ReservationStatus,
      );

      await ref
          .read(tableReservationMutationProvider.notifier)
          .updateTableReservation(
            widget.tableReservation!.id,
            updateTableReservationDto,
          );

      if (ref.read(tableReservationMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutationState = ref.watch(tableReservationMutationProvider);

    ref.listen<TableReservationMutationState>(
      tableReservationMutationProvider,
      (previous, next) {
        if (next.errorMessage != null &&
            (previous?.errorMessage != next.errorMessage)) {
          ToastUtils.showError(context: context, message: next.errorMessage!);
          ref
              .read(tableReservationMutationProvider.notifier)
              .resetErrorMessage();
        }

        if (next.successMessage != null &&
            (previous?.successMessage != next.successMessage)) {
          ToastUtils.showSuccess(
            context: context,
            message: next.successMessage!,
          );
          ref
              .read(tableReservationMutationProvider.notifier)
              .resetSuccessMessage();

          context.router.pop();
        }
      },
    );

    return Scaffold(
      appBar: const AdminAppBar(),
      endDrawer: const MyEndDrawer(),
      body: MyScreenContainer(
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: mutationState.isLoading,
            child: FormBuilder(
              key: _formKey,
              initialValue: {'status': widget.tableReservation?.status ?? ''},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormBuilderDropdown<ReservationStatus>(
                    name: 'status',
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      hintText: 'Table Reservation Status',
                    ),
                    items:
                        ReservationStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.name),
                          );
                        }).toList(),
                    validator: FormBuilderValidators.required(
                      errorText: 'Silakan pilih table reservation status',
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: mutationState.isLoading ? null : _submitForm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child:
                              mutationState.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Update TableReservation'),
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
