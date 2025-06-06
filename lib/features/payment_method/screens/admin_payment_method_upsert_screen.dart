import 'dart:io';
import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamal/core/utils/toast_utils.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/features/payment_method/providers/payment_method_mutation_provider.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/features/payment_method/providers/payment_method_mutation_state.dart';
import 'package:jamal/shared/widgets/admin_app_bar.dart';
import 'package:jamal/shared/widgets/my_end_drawer.dart';
import 'package:jamal/shared/widgets/my_screen_container.dart';

@RoutePage()
class AdminPaymentMethodUpsertScreen extends ConsumerStatefulWidget {
  final PaymentMethodModel? paymentMethod;

  const AdminPaymentMethodUpsertScreen({super.key, this.paymentMethod});

  @override
  ConsumerState<AdminPaymentMethodUpsertScreen> createState() =>
      _AdminPaymentMethodUpsertScreenState();
}

class _AdminPaymentMethodUpsertScreenState
    extends ConsumerState<AdminPaymentMethodUpsertScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _deleteExistingImage = false;

  @override
  void initState() {
    super.initState();

    if (widget.paymentMethod != null && widget.paymentMethod!.logo != null) {
      _deleteExistingImage = false;
    } else {
      _deleteExistingImage = true;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);

        if (widget.paymentMethod != null &&
            widget.paymentMethod!.logo != null) {
          _formKey.currentState?.fields['deleteExistingImage']?.didChange(
            false,
          );
          _deleteExistingImage = false;
        }
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedImageFile = null;
      if (widget.paymentMethod != null && widget.paymentMethod!.logo != null) {
        _deleteExistingImage = false;
      } else {
        _deleteExistingImage = true;
      }
    });
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    final bool isAdding = widget.paymentMethod == null;
    final bool hasExistingImage = widget.paymentMethod?.logo != null;

    if (_selectedImageFile == null && !hasExistingImage && !isAdding) {
      ToastUtils.showWarning(
        context: context,
        message: 'Please select a new image or ensure an existing one is kept.',
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      if (isAdding) {
        if (_selectedImageFile == null) {
          ToastUtils.showWarning(
            context: context,
            message: 'Please select an image.',
          );
          return;
        }

        final createPaymentMethodDto = CreatePaymentMethodDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String?,
          minimumAmount:
              double.tryParse(formValues['minimumAmount'].toString()) ?? 0.0,
          maximumAmount:
              double.tryParse(formValues['maximumAmount'].toString()) ?? 0.0,
          paymentMethodType:
              formValues['paymentMethodType'] as PaymentMethodType,
          logoFile: _selectedImageFile,
        );

        await ref
            .read(paymentMethodMutationProvider.notifier)
            .addPaymentMethod(createPaymentMethodDto);
      } else {
        final updatePaymentMethodDto = UpdatePaymentMethodDto(
          name: formValues['name'] as String,
          description: formValues['description'] as String?,
          minimumAmount:
              double.tryParse(formValues['minimumAmount'].toString()) ?? 0.0,
          maximumAmount:
              double.tryParse(formValues['maximumAmount'].toString()) ?? 0.0,
          paymentMethodType:
              formValues['paymentMethodType'] as PaymentMethodType,
          logoFile: _selectedImageFile,
        );

        final bool deleteImage =
            _formKey.currentState?.fields['deleteExistingImage']?.value ??
            false;

        await ref
            .read(paymentMethodMutationProvider.notifier)
            .updatePaymentMethod(
              widget.paymentMethod!.id,
              updatePaymentMethodDto,
              deleteExistingImage: deleteImage,
            );
      }

      if (ref.read(paymentMethodMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdding = widget.paymentMethod == null;
    final hasExistingImage = widget.paymentMethod?.logo != null;

    ref.listen<PaymentMethodMutationState>(paymentMethodMutationProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null &&
          (previous?.errorMessage != next.errorMessage)) {
        ToastUtils.showError(context: context, message: next.errorMessage!);
        ref.read(paymentMethodMutationProvider.notifier).resetErrorMessage();
      }

      if (next.successMessage != null &&
          (previous?.successMessage != next.successMessage)) {
        ToastUtils.showSuccess(context: context, message: next.successMessage!);
        ref.read(paymentMethodMutationProvider.notifier).resetSuccessMessage();

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
              final mutationState = ref.watch(paymentMethodMutationProvider);
              final isSubmitting = mutationState.isLoading;

              return AbsorbPointer(
                absorbing: isSubmitting,
                child: FormBuilder(
                  key: _formKey,

                  initialValue: {
                    'name': widget.paymentMethod?.name ?? '',
                    'description': widget.paymentMethod?.description ?? '',
                    'minimumAmount':
                        widget.paymentMethod?.minimumAmount.toString() ?? '',
                    'maximumAmount':
                        widget.paymentMethod?.maximumAmount.toString() ?? '',

                    'paymentMethodType':
                        widget.paymentMethod?.paymentMethodType,
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormBuilderTextField(
                        name: 'name',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Name',
                          labelText: 'Name',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(3),
                          FormBuilderValidators.maxLength(50),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderTextField(
                        name: 'description',
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Description',
                          labelText: 'Description',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(10),
                          FormBuilderValidators.maxLength(500),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderTextField(
                        name: 'minimumAmount',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Minimum Amount',
                          labelText: 'Minimum Amount',
                          prefixText: 'Rp ',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          FormBuilderValidators.min(0.0),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderTextField(
                        name: 'maximumAmount',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Maximum Amount',
                          labelText: 'Maximum Amount',
                          prefixText: 'Rp ',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          FormBuilderValidators.min(0.1),

                          (val) {
                            final minAmount =
                                double.tryParse(
                                  _formKey
                                          .currentState
                                          ?.fields['minimumAmount']
                                          ?.value
                                          ?.toString() ??
                                      '0.0',
                                ) ??
                                0.0;
                            final maxAmount =
                                double.tryParse(val?.toString() ?? '0.0') ??
                                0.0;
                            if (maxAmount < minAmount) {
                              return 'Maximum amount cannot be less than minimum amount.';
                            }
                            return null;
                          },
                        ]),
                      ),
                      const SizedBox(height: 16),

                      FormBuilderDropdown<PaymentMethodType>(
                        name: 'paymentMethodType',
                        decoration: const InputDecoration(
                          labelText: 'Payment Method Type',
                          border: OutlineInputBorder(),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                        items:
                            PaymentMethodType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.name),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Logo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: isSubmitting ? null : _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child:
                                    _selectedImageFile != null
                                        ? Image.file(
                                          _selectedImageFile!,
                                          fit: BoxFit.cover,
                                        )
                                        : hasExistingImage &&
                                            !_deleteExistingImage
                                        ? Image.network(
                                          widget.paymentMethod!.logo!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Icon(
                                                Icons.fastfood,
                                                size: 50,
                                                color: context.colors.secondary,
                                              ),
                                        )
                                        : Icon(
                                          Icons.add_a_photo,
                                          size: 50,
                                          color: context.colors.secondary,
                                        ),
                              ),
                            ),
                          ),
                          if (!isAdding && hasExistingImage)
                            FormBuilderSwitch(
                              name: 'deleteExistingImage',
                              title: const Text('Delete Existing Image'),
                              initialValue: _deleteExistingImage,
                              onChanged: (value) {
                                setState(() {
                                  _deleteExistingImage = value ?? false;
                                });
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                        ],
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
                                  mutationState.isLoading
                                      ? const CircularProgressIndicator()
                                      : Text(
                                        isAdding
                                            ? 'Add Payment Method'
                                            : 'Update Payment Method',
                                      ),
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
