import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ChurnDetectionPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> atRiskCreators;
  final Function(Map<String, dynamic>) onTriggerIntervention;

  const ChurnDetectionPanelWidget({
    super.key,
    required this.atRiskCreators,
    required this.onTriggerIntervention,
  });

  @override
  Widget build(BuildContext context) {
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
                Icon(Icons.radar, color: Colors.red.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Churn Detection Panel',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Live Monitoring',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 9.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                _buildThresholdBadge('≥0.7 Critical', Colors.red),
                SizedBox(width: 2.w),
                _buildThresholdBadge('≥0.5 High', Colors.orange),
              ],
            ),
            SizedBox(height: 1.5.h),
            atRiskCreators.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(
                        'No at-risk creators detected',
                        style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: atRiskCreators.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final creator = atRiskCreators[index];
                      return _buildCreatorRiskRow(context, creator);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCreatorRiskRow(BuildContext context, Map<String, dynamic> creator) {
    final probability = (creator['churn_probability'] as num?)?.toDouble() ?? 0.0;
    final isCritical = probability >= 0.7;
    final riskColor = isCritical ? Colors.red : Colors.orange;
    final name = creator['creator_name'] ?? 'Unknown';
    final daysSincePost = creator['days_since_last_post'] ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: riskColor.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: riskColor, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$daysSincePost days since last post',
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.2.h),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${(probability * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 0.3.h),
              Text(
                isCritical ? 'CRITICAL' : 'HIGH',
                style: TextStyle(color: riskColor, fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(width: 2.w),
          IconButton(
            onPressed: () => onTriggerIntervention(creator),
            icon: Icon(Icons.send, color: Colors.blue.shade700, size: 18),
            tooltip: 'Trigger Intervention',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
