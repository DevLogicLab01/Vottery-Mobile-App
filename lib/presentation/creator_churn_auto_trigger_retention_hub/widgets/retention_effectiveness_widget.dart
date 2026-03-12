import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RetentionEffectivenessWidget extends StatelessWidget {
  final Map<String, dynamic> effectivenessData;

  const RetentionEffectivenessWidget({
    super.key,
    required this.effectivenessData,
  });

  @override
  Widget build(BuildContext context) {
    final responseRate = (effectivenessData['response_rate'] as num?)?.toDouble() ?? 0.0;
    final resumptionRate = (effectivenessData['resumption_rate'] as num?)?.toDouble() ?? 0.0;
    final smsOpenRate = (effectivenessData['sms_open_rate'] as num?)?.toDouble() ?? 0.0;
    final emailOpenRate = (effectivenessData['email_open_rate'] as num?)?.toDouble() ?? 0.0;
    final abTestWinner = effectivenessData['ab_test_winner'] ?? 'Variant A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.teal.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Effectiveness Analytics',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBar(
                    'Response Rate',
                    responseRate,
                    Colors.teal,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildMetricBar(
                    'Resumption Rate',
                    resumptionRate,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBar(
                    'SMS Open Rate',
                    smsOpenRate,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildMetricBar(
                    'Email Open Rate',
                    emailOpenRate,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.amber.shade700, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A/B Test Winner',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          abTestWinner,
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
