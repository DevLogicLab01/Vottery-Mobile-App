import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/multi_currency_settlement_service.dart';
import '../../../theme/app_theme.dart';

class EnhancedWithdrawalFormWidget extends StatefulWidget {
  final Map<String, Map<String, dynamic>> zoneStatus;
  final Map<String, double> exchangeRates;
  final Map<String, String> complianceStatus;
  final Function(Map<String, dynamic>) onSubmit;

  const EnhancedWithdrawalFormWidget({
    super.key,
    required this.zoneStatus,
    required this.exchangeRates,
    required this.complianceStatus,
    required this.onSubmit,
  });

  @override
  State<EnhancedWithdrawalFormWidget> createState() =>
      _EnhancedWithdrawalFormWidgetState();
}

class _EnhancedWithdrawalFormWidgetState
    extends State<EnhancedWithdrawalFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _beneficiaryNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _taxIdController = TextEditingController();

  String _selectedZone = MultiCurrencySettlementService.zones.first;
  String _selectedCurrency = 'USD';
  String _selectedPaymentMethod = 'bank_transfer';
  bool _isSubmitting = false;
  double _taxWithholding = 0.0;

  static const Map<String, double> zoneMinimums = {
    'US_Canada': 50.0,
    'Western_Europe': 50.0,
    'Eastern_Europe': 25.0,
    'Africa': 10.0,
    'Latin_America': 20.0,
    'Middle_East_Asia': 30.0,
    'Australasia': 40.0,
    'China_Hong_Kong': 30.0,
  };

  static const Map<String, double> taxRates = {
    'US_Canada': 0.0,
    'Western_Europe': 0.0,
    'Eastern_Europe': 0.05,
    'Africa': 0.10,
    'Latin_America': 0.08,
    'Middle_East_Asia': 0.05,
    'Australasia': 0.0,
    'China_Hong_Kong': 0.10,
  };

  @override
  void dispose() {
    _amountController.dispose();
    _beneficiaryNameController.dispose();
    _accountNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _calculateTaxWithholding() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final taxRate = taxRates[_selectedZone] ?? 0.0;
    setState(() {
      _taxWithholding = amount * taxRate;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final compliance = widget.complianceStatus[_selectedZone] ?? 'pending';
    if (compliance != 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compliance verification required for $_selectedZone. Status: $compliance',
          ),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'amount': double.parse(_amountController.text),
      'zone': _selectedZone,
      'currency': _selectedCurrency,
      'payment_method': _selectedPaymentMethod,
      'beneficiary_details': {
        'name': _beneficiaryNameController.text,
        'account_number': _accountNumberController.text,
        'tax_id': _taxIdController.text,
      },
      'tax_withholding': _taxWithholding,
      'tax_document_url': null,
    };

    await widget.onSubmit(data);

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minimum = zoneMinimums[_selectedZone] ?? 50.0;

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
                    'Enhanced Withdrawal Request',
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
                  _calculateTaxWithholding();
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                  helperText: 'Minimum: \$${minimum.toStringAsFixed(2)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (_) => _calculateTaxWithholding(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount < minimum) {
                    return 'Minimum withdrawal is \$${minimum.toStringAsFixed(2)}';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  prefixIcon: const Icon(Icons.currency_exchange),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                items: ['USD', 'EUR', 'GBP', 'CNY', 'JPY']
                    .map(
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCurrency = value!);
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
              SizedBox(height: 2.h),
              TextFormField(
                controller: _taxIdController,
                decoration: InputDecoration(
                  labelText: 'Tax ID (W-8BEN/W-9)',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              if (_taxWithholding > 0) ...[
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax Withholding:',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${_taxWithholding.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
