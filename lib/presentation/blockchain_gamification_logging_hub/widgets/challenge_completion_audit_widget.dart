import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ChallengeCompletionAuditWidget extends StatelessWidget {
  final List<Map<String, dynamic>> challenges;
  final VoidCallback onRefresh;

  const ChallengeCompletionAuditWidget({
    super.key,
    required this.challenges,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt, size: 48.sp, color: Colors.grey.shade400),
              SizedBox(height: 2.h),
              Text(
                'No challenge completions logged yet',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          final blockNumber = challenge['block_number'] ?? 0;
          final timestamp = DateTime.parse(challenge['created_at']);
          final isVerified = challenge['verification_status'] == 'verified';

          return Card(
            margin: EdgeInsets.only(bottom: 2.h),
            elevation: 2,
            child: ListTile(
              leading: Icon(
                Icons.task_alt,
                color: Colors.green.shade700,
                size: 24.sp,
              ),
              title: Text(
                'Challenge Completed',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Block: #$blockNumber',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  Text(
                    'Time: ${timestamp.toString().substring(0, 19)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                isVerified ? Icons.verified : Icons.pending,
                color: isVerified ? Colors.green : Colors.orange,
              ),
            ),
          );
        },
      ),
    );
  }
}
