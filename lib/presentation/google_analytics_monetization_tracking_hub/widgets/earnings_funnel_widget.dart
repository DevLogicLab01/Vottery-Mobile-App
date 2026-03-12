import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EarningsFunnelWidget extends StatefulWidget {
  const EarningsFunnelWidget({super.key});

  @override
  State<EarningsFunnelWidget> createState() => _EarningsFunnelWidgetState();
}

class _EarningsFunnelWidgetState extends State<EarningsFunnelWidget> {
  final List<Map<String, dynamic>> _funnelStages = [
    {'stage': 'Earnings Viewed', 'count': 10000, 'conversion': 1.0},
    {'stage': 'Withdrawal Initiated', 'count': 7450, 'conversion': 0.745},
    {'stage': 'KYC Completed', 'count': 6130, 'conversion': 0.823},
    {'stage': 'Payout Completed', 'count': 5928, 'conversion': 0.967},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildFunnelVisualization(),
        SizedBox(height: 2.h),
        _buildConversionMetrics(),
        SizedBox(height: 2.h),
        _buildCohortAnalysis(),
      ],
    );
  }

  Widget _buildFunnelVisualization() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator Earnings Funnel',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ..._funnelStages.map((stage) => _buildFunnelStage(stage)),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStage(Map<String, dynamic> stage) {
    final conversion = stage['conversion'] as double;
    final count = stage['count'] as int;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage['stage'],
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(conversion * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Stack(
            children: [
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              Container(
                height: 30,
                width: 90.w * conversion,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentLight,
                      AppTheme.accentLight.withAlpha(179),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Text(
                  '$count creators',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stage-by-Stage Conversion',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildConversionRow('View → Initiate', 0.745, Colors.blue),
            _buildConversionRow('Initiate → KYC', 0.823, Colors.green),
            _buildConversionRow('KYC → Payout', 0.967, Colors.purple),
            _buildConversionRow('Overall Conversion', 0.593, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionRow(String label, double rate, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              '${(rate * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCohortAnalysis() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cohort Analysis',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildCohortMetric(
              'Creator Retention (30d)',
              '78.5%',
              Icons.people,
            ),
            _buildCohortMetric(
              'Avg Lifetime Value',
              '\$2,450',
              Icons.attach_money,
            ),
            _buildCohortMetric('Repeat Withdrawal Rate', '64.2%', Icons.repeat),
          ],
        ),
      ),
    );
  }

  Widget _buildCohortMetric(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.accentLight),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp)),
          ),
          Text(
            value,
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
