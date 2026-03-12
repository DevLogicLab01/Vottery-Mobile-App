import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VerificationStepIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final Map<String, bool> completedSteps;

  const VerificationStepIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.completedSteps,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'title': 'Personal Info', 'key': 'step1_personal_info'},
      {'title': 'Identity', 'key': 'step2_identity_document'},
      {'title': 'Bank Account', 'key': 'step3_bank_account'},
      {'title': 'Tax Docs', 'key': 'step4_tax_documentation'},
      {'title': 'Review', 'key': 'step5_submitted'},
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceLight,
      child: Row(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isCompleted = completedSteps[step['key']] ?? false;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color:
                              completedSteps[steps[index - 1]['key']] ?? false
                              ? AppTheme.accentLight
                              : AppTheme.borderLight,
                        ),
                      ),
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppTheme.accentLight
                            : isCurrent
                            ? AppTheme.primaryLight
                            : AppTheme.borderLight,
                      ),
                      child: Center(
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.white, size: 4.w)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? AppTheme.accentLight
                              : AppTheme.borderLight,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent
                        ? AppTheme.primaryLight
                        : AppTheme.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
