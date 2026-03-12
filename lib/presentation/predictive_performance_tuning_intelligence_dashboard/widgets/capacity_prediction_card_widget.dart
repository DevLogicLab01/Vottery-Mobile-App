import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/predictive_performance_tuning_service.dart';

class CapacityPredictionCard extends StatelessWidget {
  final CapacityPrediction prediction;
  final int currentMaxConnections;

  const CapacityPredictionCard({
    super.key,
    required this.prediction,
    this.currentMaxConnections = 50,
  });

  @override
  Widget build(BuildContext context) {
    final needsScaling =
        prediction.predictedDatabaseConnections > currentMaxConnections;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: needsScaling ? Colors.orange.shade300 : Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${prediction.horizon} Forecast',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Confidence',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.people,
                    label: 'Users',
                    value: _formatNumber(prediction.predictedUsers),
                    color: Colors.blue.shade600,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.storage,
                    label: 'DB Connections',
                    value: prediction.predictedDatabaseConnections.toString(),
                    color: needsScaling
                        ? Colors.orange.shade600
                        : Colors.teal.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.memory,
                    label: 'Memory',
                    value:
                        '${prediction.predictedMemoryGb.toStringAsFixed(1)} GB',
                    color: Colors.purple.shade600,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.attach_money,
                    label: 'Est. Cost',
                    value:
                        '\$${prediction.predictedCostUsd.toStringAsFixed(2)}',
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.show_chart, size: 14, color: Colors.grey.shade500),
                SizedBox(width: 1.w),
                Text(
                  'Range: ${_formatNumber(prediction.lowerBound)} – ${_formatNumber(prediction.upperBound)} users',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (needsScaling) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        'Scale DB connections to ${(prediction.predictedDatabaseConnections * 1.2).ceil()} before ${prediction.horizon}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(height: 0.3.h),
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
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
