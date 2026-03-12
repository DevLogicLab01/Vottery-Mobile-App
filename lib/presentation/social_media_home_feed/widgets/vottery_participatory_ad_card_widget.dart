import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VotteryParticipatoryAdCardWidget extends StatelessWidget {
  final String electionId;
  final String adId;
  final Map<String, dynamic> creative;
  final VoidCallback onTap;
  final VoidCallback onClick;

  const VotteryParticipatoryAdCardWidget({
    super.key,
    required this.electionId,
    required this.adId,
    required this.creative,
    required this.onTap,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = creative['image_url'] as String? ?? '';
    final headline =
        (creative['headline'] ?? creative['title'] ?? 'Sponsored Election')
            .toString();
    final description = (creative['body'] ?? '').toString();
    final formatType = (creative['format_type'] ?? 'market_research').toString();

    return GestureDetector(
      onTap: () {
        onClick();
        onTap();
      },
      child: Container(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.4.h,
                    ),
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
                    _getFormatLabel(formatType),
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  height: 20.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: 'Sponsored election: $headline',
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
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 1.5.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        onClick();
                        onTap();
                      },
                      icon: const Icon(Icons.how_to_vote, size: 16),
                      label: const Text('Vote Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatLabel(String type) {
    switch (type) {
      case 'market_research':
        return '📊 Market Research';
      case 'hype_prediction':
        return '🔥 Hype Prediction';
      case 'csr_vote':
        return '🌱 CSR Vote';
      default:
        return '🗳️ Election';
    }
  }
}

