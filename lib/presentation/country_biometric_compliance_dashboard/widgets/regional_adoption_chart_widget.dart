import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RegionalAdoptionChartWidget extends StatelessWidget {
  final Map<String, dynamic> regionalData;

  const RegionalAdoptionChartWidget({super.key, required this.regionalData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Biometric Adoption by Region',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 3.h),
          if (regionalData.isEmpty)
            Center(
              child: Text(
                'No regional data available',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
            )
          else
            ...regionalData.entries.map((entry) {
              final region = entry.key;
              final data = entry.value as Map<String, dynamic>;
              final total = data['total'] as int? ?? 0;
              final enabled = data['enabled'] as int? ?? 0;
              final rate = data['rate'] as String? ?? '0.0';

              return _buildRegionBar(region, total, enabled, rate);
            }),
        ],
      ),
    );
  }

  Widget _buildRegionBar(String region, int total, int enabled, String rate) {
    final percentage = total > 0 ? (enabled / total) : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                region,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                '$enabled/$total ($rate%)',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 2.h,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(percentage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.7) return Colors.green;
    if (percentage >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
