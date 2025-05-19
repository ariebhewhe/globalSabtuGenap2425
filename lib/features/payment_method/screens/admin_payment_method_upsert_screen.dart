import 'dart:io';
import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jamal/data/models/payment_method_model.dart';
import 'package:jamal/features/payment_method/providers/payment_method_mutation_provider.dart';
import 'package:jamal/core/utils/enums.dart';

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedImageFile = null;
    });
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    if (widget.paymentMethod == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a logo image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.paymentMethod != null &&
        widget.paymentMethod!.logo == null &&
        _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a logo image or ensure an existing one exists.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      final paymentMethod = PaymentMethodModel(
        id: widget.paymentMethod?.id ?? '',
        name: formValues['name'] as String,
        description: formValues['description'] as String?,
        minimumAmount:
            double.tryParse(formValues['minimumAmount'].toString()) ?? 0.0,
        maximumAmount:
            double.tryParse(formValues['maximumAmount'].toString()) ?? 0.0,
        paymentMethodType: formValues['paymentMethodType'] as PaymentMethodType,
        logo: widget.paymentMethod?.logo,
        createdAt: widget.paymentMethod?.createdAt ?? DateTime.now(),
        updatedAt: widget.paymentMethod?.updatedAt ?? DateTime.now(),
      );

      if (widget.paymentMethod != null) {
        await ref
            .read(paymentMethodMutationProvider.notifier)
            .updatePaymentMethod(
              widget.paymentMethod!.id,
              paymentMethod,
              imageFile: _selectedImageFile,
            );
      } else {
        await ref
            .read(paymentMethodMutationProvider.notifier)
            .addPaymentMethod(paymentMethod, imageFile: _selectedImageFile);
      }

      if (ref.read(paymentMethodMutationProvider).successMessage != null) {
        _resetForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentMethod != null
              ? 'Edit Payment Method'
              : 'Add Payment Method',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          child: Consumer(
            builder: (context, ref, child) {
              final mutationState = ref.watch(paymentMethodMutationProvider);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mutationState.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(mutationState.successMessage!)),
                  );

                  ref
                      .read(paymentMethodMutationProvider.notifier)
                      .resetSuccessMessage();
                }

                if (mutationState.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(mutationState.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );

                  ref
                      .read(paymentMethodMutationProvider.notifier)
                      .resetErrorMessage();
                }
              });

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
                                        : (widget.paymentMethod?.logo != null
                                            ? Image.network(
                                              widget.paymentMethod!.logo!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(Icons.error),
                                            )
                                            : const Icon(
                                              Icons.camera_alt,
                                              size: 40,
                                              color: Colors.grey,
                                            )),
                              ),
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
                                  isSubmitting
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        widget.paymentMethod != null
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
              );
            },
          ),
        ),
      ),
    );
  }
}
