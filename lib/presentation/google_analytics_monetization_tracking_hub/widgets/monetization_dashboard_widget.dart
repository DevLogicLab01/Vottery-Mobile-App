import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MonetizationDashboardWidget extends StatefulWidget {
  const MonetizationDashboardWidget({super.key});

  @override
  State<MonetizationDashboardWidget> createState() =>
      _MonetizationDashboardWidgetState();
}

class _MonetizationDashboardWidgetState
    extends State<MonetizationDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildKeyMetrics(),
        SizedBox(height: 2.h),
        _buildPerformanceIndicators(),
        SizedBox(height: 2.h),
        _buildExportOptions(),
      ],
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Revenue',
                '\$125,430',
                '+12.4%',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Active Creators',
                '1,247',
                '+8.2%',
                Icons.people,
                Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Payout',
                '\$450',
                '+5.1%',
                Icons.payment,
                Colors.purple,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '96.7%',
                '+2.3%',
                Icons.check_circle,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.5.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    change,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
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
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicators() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Indicators',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildIndicatorRow('Earnings View Rate', 0.89, Colors.blue),
            _buildIndicatorRow('Withdrawal Conversion', 0.745, Colors.green),
            _buildIndicatorRow('KYC Completion', 0.823, Colors.purple),
            _buildIndicatorRow('Settlement Success', 0.967, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12.sp)),
              Text(
                '${(value * 100).toStringAsFixed(1)}%',
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
            value: value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Reports',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exporting comprehensive report...'),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Export Monetization Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 5.h),
              ),
            ),
            SizedBox(height: 1.h),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Generating executive summary...'),
                  ),
                );
              },
              icon: const Icon(Icons.summarize),
              label: const Text('Generate Executive Summary'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentLight,
                minimumSize: Size(double.infinity, 5.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
