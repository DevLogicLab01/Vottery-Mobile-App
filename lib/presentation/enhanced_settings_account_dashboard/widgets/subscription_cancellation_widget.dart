import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SubscriptionCancellationWidget extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final VoidCallback onCancel;

  const SubscriptionCancellationWidget({
    super.key,
    required this.subscription,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: AppTheme.errorLight, size: 6.w),
              SizedBox(width: 3.w),
              Text(
                'Cancel Subscription',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Cancelling will end your subscription at the end of the current billing period. You will lose access to premium features.',
            style: TextStyle(fontSize: 12.sp, color: AppTheme.textPrimaryLight),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCancellationDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorLight,
                side: BorderSide(color: AppTheme.errorLight),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: const Text('Cancel Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancellationDialog(BuildContext context) {
    String feedback = '';
    String reason = 'Too expensive';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you cancelling?'),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Reason',
                ),
                items:
                    [
                          'Too expensive',
                          'Not using enough',
                          'Missing features',
                          'Found alternative',
                          'Other',
                        ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (value) => reason = value ?? reason,
              ),
              SizedBox(height: 2.h),
              TextField(
                onChanged: (value) => feedback = value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Additional feedback (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorLight),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }
}
