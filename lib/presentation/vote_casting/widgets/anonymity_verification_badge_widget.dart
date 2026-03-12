import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnonymityVerificationBadgeWidget extends StatelessWidget {
  final bool isAnonymous;
  final String? anonymousVoterCode;

  const AnonymityVerificationBadgeWidget({
    super.key,
    required this.isAnonymous,
    this.anonymousVoterCode,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAnonymous) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      margin: EdgeInsets.symmetric(vertical: 2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(77),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.white, size: 24.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  '🔒 Anonymous Election',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(Icons.verified_user, color: Colors.white, size: 20.sp),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your vote is completely anonymous',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Your identity is protected using cryptographic hashing. The election creator cannot see who voted.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                if (anonymousVoterCode != null) ...[
                  SizedBox(height: 1.h),
                  Divider(color: Colors.white.withAlpha(77)),
                  SizedBox(height: 1.h),
                  Text(
                    'Your Anonymous Voter Code:',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            anonymousVoterCode!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: Colors.green.shade700,
                            size: 18.sp,
                          ),
                          onPressed: () {
                            // TODO: Copy to clipboard
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Save this code to verify your vote later',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white.withAlpha(204),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
