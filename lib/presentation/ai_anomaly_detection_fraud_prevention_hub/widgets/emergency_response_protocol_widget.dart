import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmergencyResponseProtocolWidget extends StatelessWidget {
  final Function(String action) onEmergencyAction;

  const EmergencyResponseProtocolWidget({
    super.key,
    required this.onEmergencyAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.red.shade300, width: 2.0),
      ),
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
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Response Protocols',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade900,
                        ),
                      ),
                      Text(
                        'Critical Security Actions',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade900, size: 16.sp),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Use these actions only for severe security threats',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            _buildEmergencyAction(
              'Platform Lockdown',
              'Immediately freeze all voting and transactions',
              Icons.lock,
              () => onEmergencyAction('platform_lockdown'),
            ),
            SizedBox(height: 1.h),
            _buildEmergencyAction(
              'Freeze Suspicious Activity',
              'Suspend all flagged accounts and votes',
              Icons.pause_circle,
              () => onEmergencyAction('freeze_suspicious'),
            ),
            SizedBox(height: 1.h),
            _buildEmergencyAction(
              'Law Enforcement Report',
              'Generate and submit automated incident report',
              Icons.policy,
              () => onEmergencyAction('law_enforcement_report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyAction(
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: Colors.red.shade700, size: 18.sp),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade600),
        ),
        trailing: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          ),
          child: Text('Execute', style: TextStyle(fontSize: 10.sp)),
        ),
      ),
    );
  }
}
