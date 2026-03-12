import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ParticipationPercentageWidget extends StatelessWidget {
  final double percentage;

  const ParticipationPercentageWidget({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 50
        ? AppTheme.accentLight
        : percentage >= 25
        ? AppTheme.warningLight
        : AppTheme.textSecondaryLight;

    return Row(
      children: [
        Icon(Icons.people, size: 3.w, color: color),
        SizedBox(width: 1.w),
        Text(
          '${percentage.toStringAsFixed(0)}% of your friends',
          style: TextStyle(fontSize: 10.sp, color: color),
        ),
      ],
    );
  }
}
