import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdUnitConfigurationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> adUnits;
  final VoidCallback onRefresh;

  const AdUnitConfigurationWidget({
    super.key,
    required this.adUnits,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: adUnits.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader(context);
          }
          return _buildAdUnitCard(context, adUnits[index - 1]);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ad Unit Configuration',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Text(
          'Manage banner, interstitial, and rewarded ad units with size optimization',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildAdUnitCard(BuildContext context, Map<String, dynamic> adUnit) {
    final type = adUnit['type'] ?? '';
    final placement = adUnit['placement'] ?? '';
    final size = adUnit['size'] ?? '';
    final status = adUnit['status'] ?? '';
    final impressions = adUnit['impressions'] ?? 0;
    final clicks = adUnit['clicks'] ?? 0;
    final revenue = adUnit['revenue'] ?? 0.0;

    final ctr = impressions > 0 ? (clicks / impressions * 100) : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(type),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placement,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '$type • $size',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
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
                Expanded(
                  child: _buildMetric(
                    'Revenue',
                    '\$${revenue.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.edit, size: 16.sp),
                    label: Text('Edit', style: TextStyle(fontSize: 11.sp)),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.analytics, size: 16.sp),
                    label: Text('Analytics', style: TextStyle(fontSize: 11.sp)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
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
      child: Icon(icon, color: color, size: 24.sp),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10.sp, color: Colors.white),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
