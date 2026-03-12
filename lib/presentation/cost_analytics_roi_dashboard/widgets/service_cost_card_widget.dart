import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/infrastructure_cost_tracking_service.dart';

class ServiceCostCard extends StatelessWidget {
  final ServiceCost serviceCost;
  final double totalCost;

  const ServiceCostCard({
    super.key,
    required this.serviceCost,
    required this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalCost > 0
        ? (serviceCost.monthlyCost / totalCost * 100)
        : 0.0;
    final color = _serviceColor(serviceCost.serviceName);
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
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  serviceCost.serviceName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${serviceCost.monthlyCost.toStringAsFixed(2)}/mo',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '${percentage.toStringAsFixed(1)}% of total infrastructure cost',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
            ),
            if (serviceCost.usageMetrics.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 0.5.h,
                children: serviceCost.usageMetrics.entries
                    .take(3)
                    .map(
                      (e) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.4.h,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (serviceCost.optimizationOpportunities.isNotEmpty) ...[
              SizedBox(height: 1.h),
              ...serviceCost.optimizationOpportunities
                  .take(2)
                  .map(
                    (opp) => Padding(
                      padding: EdgeInsets.only(bottom: 0.3.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 12,
                            color: Colors.amber.shade600,
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              opp,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.amber.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Color _serviceColor(String name) {
    switch (name.toLowerCase()) {
      case 'supabase':
        return Colors.green.shade600;
      case 'datadog':
        return Colors.purple.shade600;
      case 'redis':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}
