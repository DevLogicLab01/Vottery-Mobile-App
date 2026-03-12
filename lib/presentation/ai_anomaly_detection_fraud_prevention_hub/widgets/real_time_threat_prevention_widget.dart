import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RealTimeThreatPreventionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const RealTimeThreatPreventionWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final activeThreats = alerts.where((a) => !a['is_resolved']).length;
    final autoInterventions = alerts
        .where((a) => a['recommended_action'] == 'suspend')
        .length;

    return Card(
      elevation: 2.0,
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.shield,
                    color: Colors.red.shade700,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real-Time Threat Prevention',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Automated Intervention System',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Active Threats',
                    activeThreats.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatusCard(
                    'Auto Interventions',
                    autoInterventions.toString(),
                    Icons.auto_fix_high,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Automated Countermeasures',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            _buildCountermeasure(
              'Account Suspension',
              'High-risk accounts automatically suspended',
              Icons.person_off,
              Colors.red,
            ),
            SizedBox(height: 1.h),
            _buildCountermeasure(
              'Vote Invalidation',
              'Suspicious votes flagged and removed',
              Icons.how_to_vote,
              Colors.orange,
            ),
            SizedBox(height: 1.h),
            _buildCountermeasure(
              'Payment Holds',
              'Fraudulent transactions frozen',
              Icons.payment,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
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
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCountermeasure(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
        ],
      ),
    );
  }
}
