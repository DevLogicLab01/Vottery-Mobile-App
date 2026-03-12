import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../theme/app_theme.dart';

class TestHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> testHistory;
  final VoidCallback onRefresh;

  const TestHistoryWidget({
    super.key,
    required this.testHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Test History & Trends',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...testHistory.map((test) => _buildHistoryCard(test)),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> test) {
    final testType = test['test_type'] ?? 'Unknown';
    final status = test['status'] ?? 'pending';
    final timestamp = test['timestamp'] ?? DateTime.now().toIso8601String();
    final duration = test['duration'] ?? '0s';
    final coverage = test['coverage'] ?? 0.0;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'passed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  testType.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                timeago.format(DateTime.parse(timestamp)),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duration: $duration',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                'Coverage: ${coverage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
