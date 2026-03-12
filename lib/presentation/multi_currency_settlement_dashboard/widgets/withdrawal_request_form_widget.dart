import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/multi_currency_settlement_service.dart';
import '../../../theme/app_theme.dart';

class WithdrawalRequestFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const WithdrawalRequestFormWidget({super.key, required this.onSubmit});

  @override
  State<WithdrawalRequestFormWidget> createState() =>
      _WithdrawalRequestFormWidgetState();
}

class _WithdrawalRequestFormWidgetState
    extends State<WithdrawalRequestFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  String _selectedZone = MultiCurrencySettlementService.zones.first;
  String _selectedPaymentMethod = 'bank_transfer';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _beneficiaryNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'amount': double.parse(_amountController.text),
      'zone': _selectedZone,
      'payment_method': _selectedPaymentMethod,
      'beneficiary_details': {
        'name': _beneficiaryNameController.text,
        'account_number': _accountNumberController.text,
      },
      'tax_document_url': null,
    };

    await widget.onSubmit(data);

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Withdrawal Request',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount (USD)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount < 10) {
                    return 'Minimum withdrawal is \$10';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedZone,
                decoration: InputDecoration(
                  labelText: 'Zone',
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                items: MultiCurrencySettlementService.zones
                    .map(
                      (zone) => DropdownMenuItem(
                        value: zone,
                        child: Text(zone.replaceAll('_', ' ')),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedZone = value!);
                },
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: const Icon(Icons.payment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                items: MultiCurrencySettlementService.settlementTimelines.keys
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(
                          '${method.replaceAll('_', ' ')} (${MultiCurrencySettlementService.settlementTimelines[method]})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value!);
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _beneficiaryNameController,
                decoration: InputDecoration(
                  labelText: 'Beneficiary Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Beneficiary name is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Account number is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vibrantYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Submit Request',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
