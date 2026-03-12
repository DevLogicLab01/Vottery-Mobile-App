import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/advertiser_registration_service.dart';

class PaymentSetupStepWidget extends StatefulWidget {
  final Map<String, dynamic>? registration;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const PaymentSetupStepWidget({
    super.key,
    this.registration,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PaymentSetupStepWidget> createState() => _PaymentSetupStepWidgetState();
}

class _PaymentSetupStepWidgetState extends State<PaymentSetupStepWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressLine1Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  String _country = 'US';
  bool _paymentConfigured = false;

  @override
  void initState() {
    super.initState();
    _addressLine1Controller = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postalCodeController = TextEditingController();
    _paymentConfigured =
        widget.registration?['payment_method_configured'] ?? false;
    _loadBillingInfo();
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadBillingInfo() async {
    if (widget.registration != null) {
      final billingInfo = await AdvertiserRegistrationService.instance
          .getBillingInfo(widget.registration!['id']);

      if (billingInfo != null && mounted) {
        setState(() {
          _addressLine1Controller.text =
              billingInfo['billing_address_line1'] ?? '';
          _cityController.text = billingInfo['billing_city'] ?? '';
          _stateController.text = billingInfo['billing_state'] ?? '';
          _postalCodeController.text = billingInfo['billing_postal_code'] ?? '';
          _country = billingInfo['billing_country'] ?? 'US';
        });
      }
    }
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
            Text('Payment Setup', style: theme.textTheme.titleMedium),
            SizedBox(height: 2.h),
            Text(
              'Configure your billing information and payment method',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            Text('Billing Address', style: theme.textTheme.titleSmall),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: InputDecoration(
                labelText: 'Address Line 1 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: InputDecoration(
                      labelText: 'Postal Code *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _country,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'US',
                        child: Text('United States'),
                      ),
                      DropdownMenuItem(value: 'CA', child: Text('Canada')),
                      DropdownMenuItem(
                        value: 'GB',
                        child: Text('United Kingdom'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _country = value!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Card(
              color: _paymentConfigured
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(
                      _paymentConfigured ? Icons.check_circle : Icons.payment,
                      size: 32.sp,
                      color: _paymentConfigured ? Colors.green : Colors.orange,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _paymentConfigured
                          ? 'Payment Method Configured'
                          : 'Stripe Integration',
                      style: theme.textTheme.titleSmall,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _paymentConfigured
                          ? 'Your payment method is ready'
                          : 'Payment method will be configured via Stripe',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (!_paymentConfigured) ...[
                      SizedBox(height: 2.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _paymentConfigured = true);
                        },
                        icon: Icon(Icons.credit_card),
                        label: Text('Configure Payment'),
                      ),
                    ],
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
                    onPressed: _paymentConfigured
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              if (widget.registration != null) {
                                await AdvertiserRegistrationService.instance
                                    .updateBillingInfo(
                                      registrationId:
                                          widget.registration!['id'],
                                      addressLine1:
                                          _addressLine1Controller.text,
                                      city: _cityController.text,
                                      state: _stateController.text,
                                      postalCode: _postalCodeController.text,
                                      country: _country,
                                    );
                              }
                              widget.onNext({});
                            }
                          }
                        : null,
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
