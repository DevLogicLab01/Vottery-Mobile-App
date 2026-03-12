import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';

class VotteryDisplayAdCardWidget extends StatelessWidget {
  final Map<String, dynamic> creative;
  final String adType; // display/video
  final VoidCallback onClick;

  const VotteryDisplayAdCardWidget({
    super.key,
    required this.creative,
    required this.adType,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final headline =
        (creative['headline'] ?? creative['title'] ?? 'Sponsored').toString();
    final body = (creative['body'] ?? '').toString();
    final imageUrl = creative['image_url'] as String?;
    final videoUrl = creative['video_url'] as String?;
    final ctaLabel = (creative['cta_label'] ??
            creative['cta'] ??
            'Learn more')
        .toString();
    final ctaUrl = creative['cta_url']?.toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            child: Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Sponsored',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  adType == 'video' ? 'Video Ad' : 'Ad',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.network(
                imageUrl,
                height: 20.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (body.isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (videoUrl != null && videoUrl.isNotEmpty) ...[
                  SizedBox(height: 1.h),
                  Text(
                    'Video: $videoUrl',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 1.5.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      onClick();
                      if (ctaUrl != null && ctaUrl.isNotEmpty) {
                        final uri = Uri.tryParse(ctaUrl);
                        if (uri != null) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      ctaLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

