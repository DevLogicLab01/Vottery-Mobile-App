import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnonymousVotingToggleWidget extends StatelessWidget {
  final bool allowAnonymousVoting;
  final ValueChanged<bool> onChanged;

  const AnonymousVotingToggleWidget({
    super.key,
    required this.allowAnonymousVoting,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: allowAnonymousVoting
            ? Colors.green.shade50
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: allowAnonymousVoting
              ? Colors.green.shade300
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock,
                color: allowAnonymousVoting ? Colors.green : Colors.grey,
                size: 24.sp,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Anonymous Voting',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: allowAnonymousVoting,
                onChanged: onChanged,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'When enabled, voter identities are protected using cryptographic hashing. Votes remain verifiable without revealing who voted.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          if (allowAnonymousVoting) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.green.shade700,
                    size: 16.sp,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Voters will receive anonymous voter codes for verification',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green.shade700,
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
