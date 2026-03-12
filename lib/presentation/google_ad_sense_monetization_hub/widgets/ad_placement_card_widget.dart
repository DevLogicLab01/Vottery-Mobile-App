import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdPlacementCardWidget extends StatelessWidget {
  final Map<String, dynamic> placement;
  final VoidCallback onUpdate;

  const AdPlacementCardWidget({
    super.key,
    required this.placement,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final placementName = placement['placement'] ?? 'Unknown';
    final adType = placement['ad_type'] ?? 'banner';
    final impressions = placement['impressions'] ?? 0;
    final clicks = placement['clicks'] ?? 0;
    final revenue = placement['revenue'] ?? 0.0;
    final ctr = impressions > 0 ? (clicks / impressions * 100) : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAdTypeIcon(adType),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placementName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        adType.toUpperCase(),
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${revenue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetric('Impressions', impressions.toString()),
                ),
                Expanded(child: _buildMetric('Clicks', clicks.toString())),
                Expanded(
                  child: _buildMetric('CTR', '${ctr.toStringAsFixed(2)}%'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdTypeIcon(String adType) {
    IconData icon;
    Color color;

    switch (adType) {
      case 'banner':
        icon = Icons.view_carousel;
        color = Colors.blue;
        break;
      case 'interstitial':
        icon = Icons.fullscreen;
        color = Colors.orange;
        break;
      case 'rewarded':
        icon = Icons.card_giftcard;
        color = Colors.purple;
        break;
      case 'native':
        icon = Icons.article;
        color = Colors.green;
        break;
      default:
        icon = Icons.ad_units;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, color: color, size: 20.sp),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
