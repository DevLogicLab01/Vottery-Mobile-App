import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/advertiser_registration_service.dart';

class FinancialInfoStepWidget extends StatefulWidget {
  final Map<String, dynamic>? registration;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const FinancialInfoStepWidget({
    super.key,
    this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<FinancialInfoStepWidget> createState() =>
      _FinancialInfoStepWidgetState();
}

class _FinancialInfoStepWidgetState extends State<FinancialInfoStepWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessRegController;
  late TextEditingController _taxIdController;

  @override
  void initState() {
    super.initState();
    _businessRegController = TextEditingController(
      text: widget.registration?['business_registration_number'] ?? '',
    );
    _taxIdController = TextEditingController(
      text: widget.registration?['tax_identification_number'] ?? '',
    );
  }

  @override
  void dispose() {
    _businessRegController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Information', style: theme.textTheme.titleMedium),
            SizedBox(height: 2.h),
            Text(
              'Provide your business registration and tax details',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _businessRegController,
              decoration: InputDecoration(
                labelText: 'Business Registration Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_center),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Business registration number is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _taxIdController,
              decoration: InputDecoration(
                labelText: 'Tax Identification Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tax ID is required';
                }
                return null;
              },
            ),
            SizedBox(height: 3.h),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 2.w),
                        Text(
                          'Bank Account Verification',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Bank account verification will be completed in the payment setup step.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    child: Text('Back'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (widget.registration != null) {
                          await AdvertiserRegistrationService.instance
                              .updateCompanyInfo(
                                registrationId: widget.registration!['id'],
                                businessRegistrationNumber:
                                    _businessRegController.text,
                                taxIdentificationNumber: _taxIdController.text,
                              );
                        }
                        widget.onNext({});
                      }
                    },
                    child: Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
