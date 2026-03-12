import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class RecommendationHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const RecommendationHistoryWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Colors.grey, size: 48.sp),
            SizedBox(height: 2.h),
            Text(
              'No history yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final action = item['action'] ?? 'unknown';
    final type = item['recommendation_type'] ?? 'general';
    final timestamp = item['created_at'] != null
        ? DateTime.parse(item['created_at'])
        : DateTime.now();
    final confidenceScore = item['confidence_score'] ?? 0;
    final successMetrics = item['success_metrics'] as Map<String, dynamic>?;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Padding(
        padding: EdgeInsets.all(2.5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildActionIcon(action),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActionLabel(action),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(timestamp),
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    type.toUpperCase(),
                    style: TextStyle(fontSize: 9.sp),
                  ),
                  backgroundColor: Colors.grey.shade200,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (successMetrics != null && action == 'approved') ...[
              SizedBox(height: 1.5.h),
              _buildSuccessMetrics(successMetrics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(String action) {
    IconData icon;
    Color color;

    switch (action) {
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'undone':
        icon = Icons.undo;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20.sp);
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'approved':
        return 'Applied Recommendation';
      case 'rejected':
        return 'Dismissed Recommendation';
      case 'undone':
        return 'Undone Action';
      default:
        return 'Unknown Action';
    }
  }

  Widget _buildSuccessMetrics(Map<String, dynamic> metrics) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact Metrics',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 1.h),
          ...metrics.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatMetricKey(entry.key),
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  Text(
                    _formatMetricValue(entry.value),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatMetricKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatMetricValue(dynamic value) {
    if (value is num) {
      if (value >= 0) {
        return '+${value.toStringAsFixed(1)}%';
      } else {
        return '${value.toStringAsFixed(1)}%';
      }
    }
    return value.toString();
  }
}
