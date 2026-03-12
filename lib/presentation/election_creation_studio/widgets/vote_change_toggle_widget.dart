import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VoteChangeToggleWidget extends StatelessWidget {
  final bool allowVoteChanges;
  final ValueChanged<bool> onChanged;

  const VoteChangeToggleWidget({
    super.key,
    required this.allowVoteChanges,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: allowVoteChanges ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: allowVoteChanges ? Colors.blue.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit,
                color: allowVoteChanges ? Colors.blue : Colors.grey,
                size: 24.sp,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Allow Vote Changes',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: allowVoteChanges,
                onChanged: onChanged,
                activeThumbColor: Colors.blue,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'When enabled, voters can request to change their vote. Changes require your approval and are tracked in the audit log.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          if (allowVoteChanges) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue.shade700,
                        size: 16.sp,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Vote change approval workflow:',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Voter submits change request',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '• You receive notification',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '• Approve or reject within 24 hours',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '• Auto-approved if no response',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange.shade700,
                    size: 16.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Voters attempting to change votes will be flagged for audit',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
