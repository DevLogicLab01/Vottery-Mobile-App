import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class KycAnalyticsWidget extends StatefulWidget {
  const KycAnalyticsWidget({super.key});

  @override
  State<KycAnalyticsWidget> createState() => _KycAnalyticsWidgetState();
}

class _KycAnalyticsWidgetState extends State<KycAnalyticsWidget> {
  final List<Map<String, dynamic>> _kycSteps = [
    {'step': 'Step 1: Personal Info', 'completion': 0.95, 'dropoff': 0.05},
    {'step': 'Step 2: Identity Document', 'completion': 0.88, 'dropoff': 0.07},
    {'step': 'Step 3: Bank Account', 'completion': 0.91, 'dropoff': 0.03},
    {'step': 'Step 4: Tax Documentation', 'completion': 0.85, 'dropoff': 0.06},
    {
      'step': 'Step 5: Compliance Screening',
      'completion': 0.92,
      'dropoff': 0.08,
    },
  ];

  final Map<String, int> _rejectionReasons = {
    'Document Quality': 245,
    'Information Mismatch': 189,
    'Incomplete Data': 156,
    'Compliance Flags': 98,
    'Other': 67,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildKycOverview(),
        SizedBox(height: 2.h),
        _buildStepCompletion(),
        SizedBox(height: 2.h),
        _buildRejectionAnalysis(),
      ],
    );
  }

  Widget _buildKycOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KYC Completion Overview',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewMetric('Started', '7,450', Colors.blue),
                _buildOverviewMetric('Approved', '6,130', Colors.green),
                _buildOverviewMetric('Rejected', '755', Colors.red),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: 0.823,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentLight),
              minHeight: 8,
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Overall Completion Rate: 82.3%',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStepCompletion() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step-by-Step Completion Rates',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ..._kycSteps.map((step) => _buildStepRow(step)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(Map<String, dynamic> step) {
    final completion = step['completion'] as double;
    final dropoff = step['dropoff'] as double;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  step['step'],
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(completion * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: completion,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 6,
          ),
          SizedBox(height: 0.3.h),
          Text(
            'Drop-off: ${(dropoff * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rejection Reasons',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ..._rejectionReasons.entries.map(
              (entry) => _buildRejectionRow(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionRow(String reason, int count) {
    final total = _rejectionReasons.values.reduce((a, b) => a + b);
    final percentage = count / total;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(reason, style: GoogleFonts.inter(fontSize: 12.sp)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              minHeight: 6,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
