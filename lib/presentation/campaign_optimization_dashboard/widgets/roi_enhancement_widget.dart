import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RoiEnhancementWidget extends StatelessWidget {
  final List<Map<String, dynamic>> enhancements;

  const RoiEnhancementWidget({super.key, required this.enhancements});

  @override
  Widget build(BuildContext context) {
    if (enhancements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 60.sp, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No ROI Enhancements',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'ROI optimization tracking will appear here',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: enhancements.length,
      itemBuilder: (context, index) {
        final enhancement = enhancements[index];
        return _buildEnhancementCard(context, enhancement);
      },
    );
  }

  Widget _buildEnhancementCard(
    BuildContext context,
    Map<String, dynamic> enhancement,
  ) {
    final enhancementType =
        enhancement['enhancement_type'] ?? 'conversion_optimization';
    final baselineRoi = (enhancement['baseline_roi'] ?? 0.0).toDouble();
    final currentRoi = (enhancement['current_roi'] ?? 0.0).toDouble();
    final roiImprovementPercent =
        (enhancement['roi_improvement_percent'] ?? 0.0).toDouble();
    final costSavings = (enhancement['cost_savings'] ?? 0.0).toDouble();
    final revenueIncrease = (enhancement['revenue_increase'] ?? 0.0).toDouble();
    final status = enhancement['status'] ?? 'active';
    final measurementPeriodDays = enhancement['measurement_period_days'] ?? 7;

    String typeLabel = _getEnhancementTypeLabel(enhancementType);
    IconData typeIcon = _getEnhancementTypeIcon(enhancementType);
    Color typeColor = _getEnhancementTypeColor(enhancementType);

    Color statusColor = Colors.green;
    if (status == 'completed') {
      statusColor = Colors.blue;
    } else if (status == 'reverted') {
      statusColor = Colors.red;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$measurementPeriodDays-day tracking',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Baseline ROI',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${baselineRoi.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey, size: 20.sp),
                  Column(
                    children: [
                      Text(
                        'Current ROI',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${currentRoi.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Text(
                    'ROI Improvement',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                  Text(
                    '+${roiImprovementPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildImpactBox(
                    'Cost Savings',
                    '\$${costSavings.toStringAsFixed(2)}',
                    Icons.savings,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildImpactBox(
                    'Revenue Increase',
                    '\$${revenueIncrease.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getEnhancementTypeLabel(String type) {
    switch (type) {
      case 'conversion_optimization':
        return 'Conversion Optimization';
      case 'bid_adjustment':
        return 'Bid Adjustment';
      case 'targeting_refinement':
        return 'Targeting Refinement';
      case 'creative_optimization':
        return 'Creative Optimization';
      case 'schedule_optimization':
        return 'Schedule Optimization';
      default:
        return 'ROI Enhancement';
    }
  }

  IconData _getEnhancementTypeIcon(String type) {
    switch (type) {
      case 'conversion_optimization':
        return Icons.check_circle;
      case 'bid_adjustment':
        return Icons.gavel;
      case 'targeting_refinement':
        return Icons.my_location;
      case 'creative_optimization':
        return Icons.palette;
      case 'schedule_optimization':
        return Icons.schedule;
      default:
        return Icons.show_chart;
    }
  }

  Color _getEnhancementTypeColor(String type) {
    switch (type) {
      case 'conversion_optimization':
        return Colors.green;
      case 'bid_adjustment':
        return Colors.orange;
      case 'targeting_refinement':
        return Colors.blue;
      case 'creative_optimization':
        return Colors.purple;
      case 'schedule_optimization':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
