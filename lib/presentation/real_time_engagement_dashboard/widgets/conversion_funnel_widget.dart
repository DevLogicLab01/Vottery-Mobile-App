import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ConversionFunnelWidget extends StatelessWidget {
  final Map<String, dynamic> funnels;

  const ConversionFunnelWidget({super.key, required this.funnels});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conversion Funnels',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        _buildFunnelCard(
          context,
          'KYC Funnel',
          funnels['kyc_funnel'] ?? {},
          Colors.blue,
        ),
        SizedBox(height: 1.h),
        _buildFunnelCard(
          context,
          'Voting Funnel',
          funnels['voting_funnel'] ?? {},
          Colors.purple,
        ),
        SizedBox(height: 1.h),
        _buildFunnelCard(
          context,
          'Creator Onboarding',
          funnels['creator_funnel'] ?? {},
          Colors.green,
        ),
        SizedBox(height: 1.h),
        _buildFunnelCard(
          context,
          'Subscription Funnel',
          funnels['subscription_funnel'] ?? {},
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildFunnelCard(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
    Color color,
  ) {
    final steps = data['steps'] as List? ?? [];
    final conversionRate = data['conversion_rate'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: color, size: 16.sp),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${conversionRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            if (steps.isNotEmpty) ...[
              SizedBox(height: 1.h),
              ...steps.map((step) => _buildFunnelStep(step, color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStep(Map<String, dynamic> step, Color color) {
    final name = step['name'] as String? ?? '';
    final count = step['count'] as int? ?? 0;
    final rate = step['completion_rate'] as double? ?? 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(name, style: TextStyle(fontSize: 11.sp)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '$count (${rate.toStringAsFixed(0)}%)',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
