import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/predictive_performance_tuning_service.dart';

class CostOptimizationCard extends StatelessWidget {
  final CostOptimization optimization;

  const CostOptimizationCard({super.key, required this.optimization});

  @override
  Widget build(BuildContext context) {
    final effortColor = _effortColor(optimization.implementationEffort);
    final impactColor = _impactColor(optimization.impact);
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.savings, color: Colors.green.shade600, size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    optimization.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '\$${optimization.monthlySavings.toStringAsFixed(0)}/mo',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              optimization.description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                _Badge(
                  label:
                      'Effort: ${optimization.implementationEffort.toUpperCase()}',
                  color: effortColor,
                ),
                SizedBox(width: 2.w),
                _Badge(
                  label: 'Impact: ${optimization.impact.toUpperCase()}',
                  color: impactColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _effortColor(String effort) {
    switch (effort.toLowerCase()) {
      case 'low':
        return Colors.green.shade600;
      case 'high':
        return Colors.red.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  Color _impactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return Colors.blue.shade700;
      case 'low':
        return Colors.grey.shade600;
      default:
        return Colors.purple.shade600;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
