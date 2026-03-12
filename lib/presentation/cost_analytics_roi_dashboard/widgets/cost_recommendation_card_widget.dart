import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/infrastructure_cost_tracking_service.dart';

class CostRecommendationCard extends StatelessWidget {
  final CostRecommendation recommendation;

  const CostRecommendationCard({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final rec = recommendation;
    final effortColor = _effortColor(rec.implementationEffort);
    final impactColor = _impactColor(rec.impact);
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
                Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    rec.optimizationType,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                    '\$${rec.annualSavings.toStringAsFixed(0)}/yr',
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
              rec.description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (rec.currentCost > 0 || rec.projectedCost > 0) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: _CostComparison(
                      label: 'Current',
                      value: '\$${rec.currentCost.toStringAsFixed(0)}/mo',
                      color: Colors.red.shade600,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                  Expanded(
                    child: _CostComparison(
                      label: 'Projected',
                      value: '\$${rec.projectedCost.toStringAsFixed(0)}/mo',
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 1.h),
            Row(
              children: [
                _Badge(
                  label: 'Effort: ${rec.implementationEffort.toUpperCase()}',
                  color: effortColor,
                ),
                SizedBox(width: 2.w),
                _Badge(
                  label: 'Impact: ${rec.impact.toUpperCase()}',
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

class _CostComparison extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CostComparison({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
        ),
      ],
    );
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
