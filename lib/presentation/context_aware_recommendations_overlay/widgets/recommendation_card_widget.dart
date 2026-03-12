import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RecommendationCardWidget extends StatelessWidget {
  final Map<String, dynamic> recommendation;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RecommendationCardWidget({
    super.key,
    required this.recommendation,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final type = recommendation['type'] ?? 'general';
    final title = recommendation['title'] ?? 'Recommendation';
    final description = recommendation['description'] ?? '';
    final confidenceScore = recommendation['confidence_score'] ?? 0;
    final impact = recommendation['impact'] ?? 'medium';

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
                _buildTypeIcon(type),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildConfidenceBadge(confidenceScore),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              description,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                _buildImpactChip(impact),
                SizedBox(width: 2.w),
                _buildCategoryChip(type),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, 4.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: Size(0, 4.5.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'performance':
        icon = Icons.speed;
        color = Colors.blue;
        break;
      case 'fraud':
        icon = Icons.security;
        color = Colors.red;
        break;
      case 'revenue':
        icon = Icons.attach_money;
        color = Colors.green;
        break;
      case 'engagement':
        icon = Icons.people;
        color = Colors.purple;
        break;
      default:
        icon = Icons.lightbulb;
        color = Colors.amber;
    }

    return Container(
      padding: EdgeInsets.all(1.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, color: color, size: 18.sp),
    );
  }

  Widget _buildConfidenceBadge(int score) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color),
      ),
      child: Text(
        '$score% confident',
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImpactChip(String impact) {
    Color color;
    String label;

    switch (impact) {
      case 'high':
        color = Colors.red;
        label = 'High Impact';
        break;
      case 'medium':
        color = Colors.orange;
        label = 'Medium Impact';
        break;
      case 'low':
        color = Colors.blue;
        label = 'Low Impact';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 10.sp)),
      backgroundColor: color.withAlpha(26),
      side: BorderSide(color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCategoryChip(String type) {
    return Chip(
      label: Text(
        type.toUpperCase(),
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.grey.shade200,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
