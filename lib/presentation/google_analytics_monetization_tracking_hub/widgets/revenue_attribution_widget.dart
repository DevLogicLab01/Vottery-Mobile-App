import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RevenueAttributionWidget extends StatefulWidget {
  const RevenueAttributionWidget({super.key});

  @override
  State<RevenueAttributionWidget> createState() =>
      _RevenueAttributionWidgetState();
}

class _RevenueAttributionWidgetState extends State<RevenueAttributionWidget> {
  final Map<String, double> _revenueBySource = {
    'Election Fees': 68450.30,
    'Subscriptions': 42380.20,
    'Ads': 14600.00,
  };

  final List<Map<String, dynamic>> _campaignAttribution = [
    {'campaign': 'Spring Promo 2026', 'revenue': 28450.50, 'conversions': 1247},
    {'campaign': 'Creator Boost', 'revenue': 19230.80, 'conversions': 892},
    {'campaign': 'Organic', 'revenue': 45680.20, 'conversions': 2103},
    {'campaign': 'Referral Program', 'revenue': 15890.00, 'conversions': 678},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildRevenueSourceChart(),
        SizedBox(height: 2.h),
        _buildCampaignAttribution(),
        SizedBox(height: 2.h),
        _buildRevenueMetrics(),
      ],
    );
  }

  Widget _buildRevenueSourceChart() {
    final total = _revenueBySource.values.reduce((a, b) => a + b);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue by Source',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ..._revenueBySource.entries.map((entry) {
              final percentage = entry.value / total;
              return _buildRevenueSourceRow(entry.key, entry.value, percentage);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSourceRow(
    String source,
    double amount,
    double percentage,
  ) {
    Color color;
    switch (source) {
      case 'Election Fees':
        color = Colors.blue;
        break;
      case 'Subscriptions':
        color = Colors.green;
        break;
      case 'Ads':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                source,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              Container(
                height: 20,
                width: 85.w * percentage,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
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

  Widget _buildCampaignAttribution() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Attribution',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ..._campaignAttribution.map(
              (campaign) => _buildCampaignRow(campaign),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignRow(Map<String, dynamic> campaign) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campaign['campaign'],
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.green),
                    SizedBox(width: 1.w),
                    Text(
                      '\$${(campaign['revenue'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue),
                    SizedBox(width: 1.w),
                    Text(
                      '${campaign['conversions']} conversions',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetrics() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Metrics',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            _buildMetricRow(
              'Total Revenue',
              '\$125,430.50',
              Icons.attach_money,
            ),
            _buildMetricRow(
              'Avg Revenue per Creator',
              '\$100.58',
              Icons.person,
            ),
            _buildMetricRow(
              'Revenue Growth (MoM)',
              '+12.4%',
              Icons.trending_up,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
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
