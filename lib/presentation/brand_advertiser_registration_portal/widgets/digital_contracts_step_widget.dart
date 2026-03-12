import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/advertiser_registration_service.dart';

class DigitalContractsStepWidget extends StatefulWidget {
  final Map<String, dynamic>? registration;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const DigitalContractsStepWidget({
    super.key,
    this.registration,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  State<DigitalContractsStepWidget> createState() =>
      _DigitalContractsStepWidgetState();
}

class _DigitalContractsStepWidgetState
    extends State<DigitalContractsStepWidget> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _advertisingPolicyAccepted = false;

  @override
  void initState() {
    super.initState();
    _termsAccepted = widget.registration?['terms_accepted'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allAccepted =
        _termsAccepted && _privacyAccepted && _advertisingPolicyAccepted;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Digital Contracts', style: theme.textTheme.titleMedium),
          SizedBox(height: 2.h),
          Text(
            'Review and accept the terms and policies',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          _buildContractCard(
            theme,
            'Terms of Service',
            'Review our terms and conditions for advertiser services',
            _termsAccepted,
            (value) => setState(() => _termsAccepted = value),
          ),
          SizedBox(height: 2.h),
          _buildContractCard(
            theme,
            'Privacy Policy',
            'Understand how we handle your data and privacy',
            _privacyAccepted,
            (value) => setState(() => _privacyAccepted = value),
          ),
          SizedBox(height: 2.h),
          _buildContractCard(
            theme,
            'Advertising Policies',
            'Comply with our advertising standards and guidelines',
            _advertisingPolicyAccepted,
            (value) => setState(() => _advertisingPolicyAccepted = value),
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
                      Text('E-Signature', style: theme.textTheme.titleSmall),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'By accepting these agreements, you are providing a legally binding electronic signature.',
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
                  onPressed: allAccepted
                      ? () async {
                          if (widget.registration != null) {
                            await AdvertiserRegistrationService.instance
                                .acceptTerms(widget.registration!['id']);
                          }
                          widget.onSubmit();
                        }
                      : null,
                  child: Text('Submit Registration'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(
    ThemeData theme,
    String title,
    String description,
    bool isAccepted,
    Function(bool) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      SizedBox(height: 0.5.h),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showContractDialog(title),
                  child: Text('View'),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            CheckboxListTile(
              value: isAccepted,
              onChanged: (value) => onChanged(value ?? false),
              title: Text(
                'I have read and accept the $title',
                style: theme.textTheme.bodySmall,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showContractDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            'This is a placeholder for the $title document. In production, this would display the full legal document with proper formatting and sections.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
