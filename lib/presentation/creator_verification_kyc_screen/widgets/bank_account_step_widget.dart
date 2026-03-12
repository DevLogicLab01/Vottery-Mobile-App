import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/creator_verification_service.dart';
import '../../../theme/app_theme.dart';

class BankAccountStepWidget extends StatefulWidget {
  final VoidCallback onNext;
  final Map<String, dynamic>? initialData;

  const BankAccountStepWidget({
    super.key,
    required this.onNext,
    this.initialData,
  });

  @override
  State<BankAccountStepWidget> createState() => _BankAccountStepWidgetState();
}

class _BankAccountStepWidgetState extends State<BankAccountStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final CreatorVerificationService _verificationService =
      CreatorVerificationService.instance;

  late TextEditingController _accountNumberController;
  late TextEditingController _routingNumberController;
  late TextEditingController _swiftCodeController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController(
      text: widget.initialData?['bank_account_number'] ?? '',
    );
    _routingNumberController = TextEditingController(
      text: widget.initialData?['bank_routing_number'] ?? '',
    );
    _swiftCodeController = TextEditingController(
      text: widget.initialData?['bank_swift_code'] ?? '',
    );
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 3: Bank Account',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Connect your bank account for payouts',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                labelText: 'Account Number',
                prefixIcon: Icon(Icons.account_balance),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your account number';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _routingNumberController,
              decoration: InputDecoration(
                labelText: 'Routing Number',
                prefixIcon: Icon(Icons.route),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your routing number';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _swiftCodeController,
              decoration: InputDecoration(
                labelText: 'SWIFT/IBAN Code (Optional for international)',
                prefixIcon: Icon(Icons.public),
              ),
            ),
            SizedBox(height: 3.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: AppTheme.primaryLight, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Your bank details are encrypted and securely stored',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBankAccount,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBankAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await _verificationService.submitBankAccountDetails(
      accountNumber: _accountNumberController.text,
      routingNumber: _routingNumberController.text,
      swiftCode: _swiftCodeController.text.isNotEmpty
          ? _swiftCodeController.text
          : null,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save bank account details'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }
}
