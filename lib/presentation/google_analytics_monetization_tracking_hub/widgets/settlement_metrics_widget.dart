import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SettlementMetricsWidget extends StatefulWidget {
  const SettlementMetricsWidget({super.key});

  @override
  State<SettlementMetricsWidget> createState() =>
      _SettlementMetricsWidgetState();
}

class _SettlementMetricsWidgetState extends State<SettlementMetricsWidget> {
  final Map<String, Map<String, dynamic>> _settlementStages = {
    'Requested': {'count': 6130, 'avg_time': 0},
    'Pending': {'count': 5985, 'avg_time': 2.5},
    'Completed': {'count': 5928, 'avg_time': 4.2},
    'Reconciled': {'count': 5890, 'avg_time': 5.8},
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildSettlementOverview(),
        SizedBox(height: 2.h),
        _buildProcessingTimeChart(),
        SizedBox(height: 2.h),
        _buildReconciliationMetrics(),
      ],
    );
  }

  Widget _buildSettlementOverview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settlement Pipeline',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ..._settlementStages.entries.map(
              (entry) => _buildStageRow(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageRow(String stage, Map<String, dynamic> data) {
    final count = data['count'] as int;
    final avgTime = data['avg_time'] as double;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stage,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (avgTime > 0)
                Text(
                  'Avg: ${avgTime.toStringAsFixed(1)} days',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: AppTheme.accentLight.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingTimeChart() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Processing Time by Method',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildProcessingTimeBar('PayPal', 0.1, Colors.blue),
            _buildProcessingTimeBar('Stripe', 4.5, Colors.purple),
            _buildProcessingTimeBar('Bank Transfer', 4.0, Colors.green),
            _buildProcessingTimeBar('Crypto', 0.8, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingTimeBar(String method, double days, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(method, style: GoogleFonts.inter(fontSize: 12.sp)),
              Text(
                '${days.toStringAsFixed(1)} days',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: days / 5.0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildReconciliationMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reconciliation Metrics',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildReconciliationRow(
              'Total Settlements',
              '5,928',
              Icons.payment,
            ),
            _buildReconciliationRow(
              'Reconciled',
              '5,890 (99.4%)',
              Icons.check_circle,
              color: Colors.green,
            ),
            _buildReconciliationRow(
              'Discrepancies',
              '38 (0.6%)',
              Icons.warning,
              color: Colors.orange,
            ),
            _buildReconciliationRow(
              'Avg Discrepancy',
              '\$2.45',
              Icons.attach_money,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.accentLight),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp)),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
