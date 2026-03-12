import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/ad_slot_orchestration_service.dart';

/// Sponsored Election Card Widget
/// Displays internal participatory ad with campaign info and Vote Now CTA
class SponsoredElectionCardWidget extends StatelessWidget {
  final String electionId;
  final String adId;
  final Map<String, dynamic> campaignData;
  final VoidCallback? onTap;

  const SponsoredElectionCardWidget({
    super.key,
    required this.electionId,
    required this.adId,
    required this.campaignData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = campaignData['image_url'] as String? ?? '';
    final campaignName =
        campaignData['campaign_name'] as String? ?? 'Sponsored Election';
    final description = campaignData['description'] as String? ?? '';
    final adFormatType =
        campaignData['ad_format_type'] as String? ?? 'market_research';

    return GestureDetector(
      onTap: () {
        AdSlotOrchestrationService.instance.recordAdClick(adId);
        onTap?.call();
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
            // Header with Sponsored badge
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
                    _getFormatLabel(adFormatType),
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Campaign image
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
                  semanticLabel: 'Sponsored election campaign: $campaignName',
                ),
              ),
            // Campaign info
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaignName,
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
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AdSlotOrchestrationService.instance.recordAdClick(adId);
                        onTap?.call();
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
