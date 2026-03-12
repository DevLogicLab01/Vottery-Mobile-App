import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ABTestPerformanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> metrics;

  const ABTestPerformanceWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final groupedMetrics = _groupMetricsByTestGroup();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A/B Test Performance',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          ...groupedMetrics.entries.map(
            (entry) => _buildGroupCard(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, double>> _groupMetricsByTestGroup() {
    final grouped = <String, Map<String, double>>{};

    for (final metric in metrics) {
      final group = metric['test_group'] ?? 'unknown';
      if (!grouped.containsKey(group)) {
        grouped[group] = {
          'ctr': 0.0,
          'engagement_rate': 0.0,
          'avg_time_spent': 0.0,
          'conversion_rate': 0.0,
          'count': 0.0,
        };
      }

      grouped[group]!['ctr'] = grouped[group]!['ctr']! + (metric['ctr'] ?? 0.0);
      grouped[group]!['engagement_rate'] =
          grouped[group]!['engagement_rate']! +
          (metric['engagement_rate'] ?? 0.0);
      grouped[group]!['avg_time_spent'] =
          grouped[group]!['avg_time_spent']! +
          (metric['avg_time_spent_seconds'] ?? 0.0);
      grouped[group]!['conversion_rate'] =
          grouped[group]!['conversion_rate']! +
          (metric['conversion_rate'] ?? 0.0);
      grouped[group]!['count'] = grouped[group]!['count']! + 1;
    }

    // Calculate averages
    for (final group in grouped.keys) {
      final count = grouped[group]!['count']!;
      if (count > 0) {
        grouped[group]!['ctr'] = grouped[group]!['ctr']! / count;
        grouped[group]!['engagement_rate'] =
            grouped[group]!['engagement_rate']! / count;
        grouped[group]!['avg_time_spent'] =
            grouped[group]!['avg_time_spent']! / count;
        grouped[group]!['conversion_rate'] =
            grouped[group]!['conversion_rate']! / count;
      }
    }

    return grouped;
  }

  Widget _buildGroupCard(String group, Map<String, double> metrics) {
    final groupColor = _getGroupColor(group);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: groupColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: groupColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: groupColor,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                'CTR',
                '${(metrics['ctr']! * 100).toStringAsFixed(1)}%',
              ),
              _buildMetricItem(
                'Engagement',
                '${(metrics['engagement_rate']! * 100).toStringAsFixed(1)}%',
              ),
              _buildMetricItem(
                'Avg Time',
                '${metrics['avg_time_spent']!.toStringAsFixed(0)}s',
              ),
              _buildMetricItem(
                'Conversion',
                '${(metrics['conversion_rate']! * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case 'control':
        return Colors.grey;
      case 'algorithm_v1':
        return Colors.blue;
      case 'algorithm_v2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
