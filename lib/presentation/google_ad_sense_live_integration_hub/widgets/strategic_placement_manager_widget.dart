import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StrategicPlacementManagerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> adUnits;
  final VoidCallback onRefresh;

  const StrategicPlacementManagerWidget({
    super.key,
    required this.adUnits,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Strategic Placement Manager',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Optimize ad placements across Jolts feed, election discovery, and dashboards',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildPlacementCard(
            'Jolts Feed',
            'Banner ads between video content',
            'Every 5 videos',
            Colors.blue,
            Icons.video_library,
            12450,
            187,
            45.32,
          ),
          SizedBox(height: 2.h),
          _buildPlacementCard(
            'Election Discovery',
            'Interstitial ads after browsing',
            'After 3 elections viewed',
            Colors.orange,
            Icons.how_to_vote,
            3420,
            98,
            78.50,
          ),
          SizedBox(height: 2.h),
          _buildPlacementCard(
            'User Dashboard',
            'Rewarded ads for VP bonuses',
            'User-initiated',
            Colors.green,
            Icons.dashboard,
            1850,
            245,
            125.75,
          ),
          SizedBox(height: 3.h),
          _buildABTestingSection(),
          SizedBox(height: 3.h),
          _buildHeatMapSection(),
        ],
      ),
    );
  }

  Widget _buildPlacementCard(
    String title,
    String description,
    String frequency,
    Color color,
    IconData icon,
    int impressions,
    int clicks,
    double revenue,
  ) {
    final ctr = impressions > 0 ? (clicks / impressions * 100) : 0.0;

    return Card(
      elevation: 2,
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
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        description,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 16.sp, color: Colors.grey[700]),
                  SizedBox(width: 2.w),
                  Text(
                    'Frequency: $frequency',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetric('Impressions', impressions.toString()),
                ),
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
          ],
        ),
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

  Widget _buildABTestingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, size: 20.sp, color: Colors.purple),
                SizedBox(width: 2.w),
                Text(
                  'A/B Testing',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Test different ad placements to optimize revenue',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.add, size: 16.sp),
                    label: Text(
                      'Create Test',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.analytics, size: 16.sp),
                    label: Text(
                      'View Results',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatMapSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, size: 20.sp, color: Colors.red),
                SizedBox(width: 2.w),
                Text(
                  'Engagement Heat Map',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Optimal placement zones based on user engagement',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withAlpha(51),
                    Colors.yellow.withAlpha(51),
                    Colors.red.withAlpha(51),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  'Heat Map Visualization',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
