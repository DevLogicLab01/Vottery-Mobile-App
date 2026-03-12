import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CreativePerformanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> creatives;
  final Function(String, String) onMarkWinner;

  const CreativePerformanceWidget({
    super.key,
    required this.creatives,
    required this.onMarkWinner,
  });

  @override
  Widget build(BuildContext context) {
    if (creatives.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 60.sp, color: Colors.purple),
            SizedBox(height: 2.h),
            Text(
              'No Creative Performance Data',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Creative A/B test results will appear here',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: creatives.length,
      itemBuilder: (context, index) {
        final creative = creatives[index];
        return _buildCreativeCard(context, creative);
      },
    );
  }

  Widget _buildCreativeCard(
    BuildContext context,
    Map<String, dynamic> creative,
  ) {
    final creativeVariant = creative['creative_variant'] ?? 'Variant A';
    final impressions = creative['impressions'] ?? 0;
    final clicks = creative['clicks'] ?? 0;
    final conversions = creative['conversions'] ?? 0;
    final ctr = (creative['ctr'] ?? 0.0).toDouble();
    final cvr = (creative['cvr'] ?? 0.0).toDouble();
    final roas = (creative['roas'] ?? 0.0).toDouble();
    final engagementScore = (creative['engagement_score'] ?? 0.0).toDouble();
    final isWinner = creative['is_winner'] ?? false;
    final statisticalSignificance =
        (creative['statistical_significance'] ?? 0.0).toDouble();
    final performanceTrend = creative['performance_trend'] ?? 'stable';

    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.trending_flat;
    if (performanceTrend == 'improving') {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else if (performanceTrend == 'declining') {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isWinner
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(Icons.palette, color: Colors.purple, size: 20.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creativeVariant,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(trendIcon, color: trendColor, size: 14.sp),
                          SizedBox(width: 1.w),
                          Text(
                            performanceTrend.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: trendColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isWinner)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Winner',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Impressions',
                    _formatNumber(impressions),
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn('Clicks', _formatNumber(clicks)),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Conversions',
                    conversions.toString(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceBox(
                    'CTR',
                    '${ctr.toStringAsFixed(2)}%',
                    Icons.touch_app,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildPerformanceBox(
                    'CVR',
                    '${cvr.toStringAsFixed(2)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceBox(
                    'ROAS',
                    '${roas.toStringAsFixed(2)}x',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildPerformanceBox(
                    'Engagement',
                    '${engagementScore.toStringAsFixed(1)}',
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
              ],
            ),
            if (statisticalSignificance >= 95)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 16.sp),
                      SizedBox(width: 2.w),
                      Text(
                        'Statistically Significant (${statisticalSignificance.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isWinner && statisticalSignificance >= 95)
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        onMarkWinner(creative['id'], creative['campaign_id']),
                    icon: const Icon(Icons.emoji_events, color: Colors.white),
                    label: Text(
                      'Promote as Winner',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPerformanceBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
