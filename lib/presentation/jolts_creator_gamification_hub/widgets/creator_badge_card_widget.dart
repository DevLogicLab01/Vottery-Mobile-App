import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CreatorBadgeCardWidget extends StatelessWidget {
  final Map<String, dynamic> badge;
  final VoidCallback onShare;
  final VoidCallback onShowQR;

  const CreatorBadgeCardWidget({
    super.key,
    required this.badge,
    required this.onShare,
    required this.onShowQR,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEarned = badge['is_earned'] as bool? ?? false;
    final progress = badge['progress_percentage'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: isEarned
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEarned ? Icons.verified : Icons.lock,
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge['badge_name'] as String,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        badge['badge_description'] as String,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${badge['vp_reward']} VP',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (!isEarned) ...[
              SizedBox(height: 2.h),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
              SizedBox(height: 1.h),
              Text(
                'Progress: ${badge['current_progress']}/${badge['requirement_threshold']} ($progress%)',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              ),
            ],
            if (isEarned) ...[
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onShowQR,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('QR Code'),
                  ),
                  TextButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
