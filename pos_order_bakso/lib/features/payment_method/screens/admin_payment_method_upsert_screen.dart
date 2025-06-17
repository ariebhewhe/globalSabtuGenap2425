import 'dart:io';
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
  File? _selectedLogoFile;
  File? _selectedQrCodeFile;
  final ImagePicker _picker = ImagePicker();
  bool _deleteExistingLogo = false;
  bool _deleteExistingQrCode = false;

  @override
  void initState() {
    super.initState();

    if (widget.paymentMethod != null) {
      if (widget.paymentMethod!.logo != null) {
        _deleteExistingLogo = false;
      } else {
        _deleteExistingLogo = true;
      }

      if (widget.paymentMethod!.adminPaymentQrCodePicture != null) {
        _deleteExistingQrCode = false;
      } else {
        _deleteExistingQrCode = true;
      }
    }
  }

  Future<void> _pickLogoImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedLogoFile = File(pickedFile.path);

        if (widget.paymentMethod != null &&
            widget.paymentMethod!.logo != null) {
          _formKey.currentState?.fields['deleteExistingLogo']?.didChange(false);
          _deleteExistingLogo = false;
        }
      });
    }
  }

  Future<void> _pickQrCodeImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedQrCodeFile = File(pickedFile.path);

        if (widget.paymentMethod != null &&
            widget.paymentMethod!.adminPaymentQrCodePicture != null) {
          _formKey.currentState?.fields['deleteExistingQrCode']?.didChange(
            false,
          );
          _deleteExistingQrCode = false;
        }
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedLogoFile = null;
      _selectedQrCodeFile = null;

      if (widget.paymentMethod != null) {
        if (widget.paymentMethod!.logo != null) {
          _deleteExistingLogo = false;
        } else {
          _deleteExistingLogo = true;
        }

        if (widget.paymentMethod!.adminPaymentQrCodePicture != null) {
          _deleteExistingQrCode = false;
        } else {
          _deleteExistingQrCode = true;
        }
      } else {
        _deleteExistingLogo = true;
        _deleteExistingQrCode = true;
      }
    });
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;

    final bool isAdding = widget.paymentMethod == null;
    final bool hasExistingLogo = widget.paymentMethod?.logo != null;
    final bool hasExistingQrCode =
        widget.paymentMethod?.adminPaymentQrCodePicture != null;

    if (_selectedLogoFile == null && !hasExistingLogo && !isAdding) {
      ToastUtils.showWarning(
        context: context,
        message:
            'Please select a new logo image or ensure an existing one is kept.',
      );
      return;
    }

    if (isValid) {
      final formValues = _formKey.currentState!.value;

      if (isAdding) {
        if (_selectedLogoFile == null) {
          ToastUtils.showWarning(
            context: context,
            message: 'Please select a logo image.',
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
          logoFile: _selectedLogoFile,
          adminPaymentCode: formValues['adminPaymentCode'] as String?,
          adminPaymentQrCodeFile: _selectedQrCodeFile,
        );

        await ref
            .read(paymentMethodMutationProvider.notifier)
            .addPaymentMethod(createPaymentMethodDto);
      } else {
        final updatePaymentMethodDto = UpdatePaymentMethodDto(
          name: formValues['name'] as String?,
          description: formValues['description'] as String?,
          minimumAmount: double.tryParse(
            formValues['minimumAmount'].toString(),
          ),
          maximumAmount: double.tryParse(
            formValues['maximumAmount'].toString(),
          ),
          paymentMethodType:
              formValues['paymentMethodType'] as PaymentMethodType?,
          logoFile: _selectedLogoFile,
          adminPaymentCode: formValues['adminPaymentCode'] as String?,
          adminPaymentQrCodeFile: _selectedQrCodeFile,
        );

        final bool deleteLogo =
            _formKey.currentState?.fields['deleteExistingLogo']?.value ?? false;
        final bool deleteQrCode =
            _formKey.currentState?.fields['deleteExistingQrCode']?.value ??
            false;

        await ref
            .read(paymentMethodMutationProvider.notifier)
            .updatePaymentMethod(
              widget.paymentMethod!.id,
              updatePaymentMethodDto,
              deleteExistingLogo: deleteLogo,
              deleteExistingQrCode: deleteQrCode,
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
    final hasExistingLogo = widget.paymentMethod?.logo != null;
    final hasExistingQrCode =
        widget.paymentMethod?.adminPaymentQrCodePicture != null;

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
                        widget.paymentMethod?.minimumAmount.toString() ?? '0.0',
                    'maximumAmount':
                        widget.paymentMethod?.maximumAmount.toString() ?? '0.0',
                    'paymentMethodType':
                        widget.paymentMethod?.paymentMethodType,
                    'adminPaymentCode':
                        widget.paymentMethod?.adminPaymentCode ?? '',
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

                      // Input for Admin Payment Code
                      FormBuilderTextField(
                        name: 'adminPaymentCode',
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Admin Payment Code (e.g., Virtual Account No.)',
                          labelText: 'Admin Payment Code',
                        ),
                        validator: FormBuilderValidators.compose([
                          // Make this required if needed, or leave optional
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Logo Section
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
                            onTap: isSubmitting ? null : _pickLogoImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child:
                                    _selectedLogoFile != null
                                        ? Image.file(
                                          _selectedLogoFile!,
                                          fit: BoxFit.cover,
                                        )
                                        : hasExistingLogo &&
                                            !_deleteExistingLogo
                                        ? Image.network(
                                          widget.paymentMethod!.logo!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color:
                                                    context
                                                        .colors
                                                        .error, // Assuming context.colors is available
                                              ),
                                        )
                                        : Icon(
                                          Icons.add_a_photo,
                                          size: 50,
                                          color:
                                              context
                                                  .colors
                                                  .secondary, // Assuming context.colors is available
                                        ),
                              ),
                            ),
                          ),
                          if (!isAdding && hasExistingLogo)
                            FormBuilderSwitch(
                              name: 'deleteExistingLogo',
                              title: const Text('Delete Existing Logo'),
                              initialValue: _deleteExistingLogo,
                              onChanged: (value) {
                                setState(() {
                                  _deleteExistingLogo = value ?? false;
                                });
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Admin QR Code Picture Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin QR Code Picture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: isSubmitting ? null : _pickQrCodeImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child:
                                    _selectedQrCodeFile != null
                                        ? Image.file(
                                          _selectedQrCodeFile!,
                                          fit: BoxFit.cover,
                                        )
                                        : hasExistingQrCode &&
                                            !_deleteExistingQrCode
                                        ? Image.network(
                                          widget
                                              .paymentMethod!
                                              .adminPaymentQrCodePicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                                    Icons.broken_image,
                                                    size: 50,
                                                    color: context.colors.error,
                                                  ),
                                        )
                                        : Icon(
                                          Icons.qr_code, // Icon for QR code
                                          size: 50,
                                          color: context.colors.secondary,
                                        ),
                              ),
                            ),
                          ),
                          if (!isAdding && hasExistingQrCode)
                            FormBuilderSwitch(
                              name: 'deleteExistingQrCode',
                              title: const Text('Delete Existing QR Code'),
                              initialValue: _deleteExistingQrCode,
                              onChanged: (value) {
                                setState(() {
                                  _deleteExistingQrCode = value ?? false;
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
