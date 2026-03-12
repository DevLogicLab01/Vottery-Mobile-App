import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ai_feature_adoption_analytics_service.dart';
import '../../services/google_analytics_integration_service.dart';

class GoogleAnalyticsIntegrationDashboard extends StatefulWidget {
  const GoogleAnalyticsIntegrationDashboard({super.key});

  @override
  State<GoogleAnalyticsIntegrationDashboard> createState() =>
      _GoogleAnalyticsIntegrationDashboardState();
}

class _GoogleAnalyticsIntegrationDashboardState
    extends State<GoogleAnalyticsIntegrationDashboard> {
  final GoogleAnalyticsIntegrationService _analyticsService =
      GoogleAnalyticsIntegrationService();
  final AIFeatureAdoptionAnalyticsService _aiAdoptionService =
      AIFeatureAdoptionAnalyticsService.instance;

  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _aiFeatureStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _analyticsService.getAnalyticsOverview(),
      _aiAdoptionService.getAIFeatureAdoptionStats(),
    ]);
    setState(() {
      _analyticsData = results[0] as Map<String, dynamic>;
      _aiFeatureStats = results[1] as List<Map<String, dynamic>>;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Analytics Integration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  _buildStatusCard(),
                  SizedBox(height: 2.h),
                  _buildAIFeatureAdoptionPanel(),
                  SizedBox(height: 2.h),
                  _buildEventTrackingSection(),
                  SizedBox(height: 2.h),
                  _buildUserPropertiesSection(),
                  SizedBox(height: 2.h),
                  _buildConversionSection(),
                  SizedBox(height: 2.h),
                  _buildRealTimeSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final totalEvents = _analyticsData['total_events'] ?? 0;
    final syncedCount = _analyticsData['synced_count'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GA4 Status Overview',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Events', totalEvents.toString()),
                _buildStatItem('Synced to GA4', syncedCount.toString()),
                _buildStatItem(
                  'Tracking Health',
                  totalEvents > 0 ? 'Active' : 'Inactive',
                  color: totalEvents > 0 ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEventTrackingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Tracking Configuration',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildEventItem('Vote Submitted', 'voting', Icons.how_to_vote),
            _buildEventItem(
              'Election Created',
              'content_creation',
              Icons.add_box,
            ),
            _buildEventItem(
              'Quest Completed',
              'engagement',
              Icons.emoji_events,
            ),
            _buildEventItem(
              'Marketplace Purchase',
              'ecommerce',
              Icons.shopping_cart,
            ),
            _buildEventItem('Creator Payout', 'monetization', Icons.payments),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(String name, String category, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(name),
      subtitle: Text('Category: $category'),
      trailing: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  Widget _buildUserPropertiesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Property Management',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildPropertyItem('User ID', 'Tracked'),
            _buildPropertyItem('User Tier', 'Tracked'),
            _buildPropertyItem('Subscription Status', 'Tracked'),
            _buildPropertyItem('VP Balance', 'Tracked'),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyItem(String property, String status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(property, style: TextStyle(fontSize: 14.sp)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 12.sp, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion Tracking',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildConversionItem('First Vote', 'first_vote'),
            _buildConversionItem('First Purchase', 'first_purchase'),
            _buildConversionItem('Creator Signup', 'creator_signup'),
            _buildConversionItem('Tier Upgrade', 'tier_upgrade'),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionItem(String name, String eventName) {
    return ListTile(
      title: Text(name),
      subtitle: Text('Event: $eventName'),
      trailing: const Icon(Icons.trending_up, color: Colors.blue),
    );
  }

  Widget _buildRealTimeSection() {
    final recentEvents = _analyticsData['recent_events'] as List? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-Time Events',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (recentEvents.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Text(
                    'No recent events',
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ),
              )
            else
              ...recentEvents
                  .take(5)
                  .map(
                    (event) => ListTile(
                      leading: const Icon(Icons.analytics, size: 20),
                      title: Text(
                        event['event_name'] ?? 'Unknown Event',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      subtitle: Text(
                        _formatTimestamp(event['timestamp']),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      trailing: Icon(
                        event['synced_to_ga4'] == true
                            ? Icons.cloud_done
                            : Icons.cloud_queue,
                        size: 20,
                        color: event['synced_to_ga4'] == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIFeatureAdoptionPanel() {
    // Count events by type
    final eventCounts = <String, int>{};
    for (final stat in _aiFeatureStats) {
      final name = stat['event_name'] as String? ?? 'unknown';
      eventCounts[name] = (eventCounts[name] ?? 0) + 1;
    }

    final topFeatures = [
      MapEntry('AI Consensus', eventCounts['ai_consensus_used'] ?? 0),
      MapEntry('Quest Complete', eventCounts['quest_completed'] ?? 0),
      MapEntry('Content Mod', eventCounts['ai_content_moderation'] ?? 0),
      MapEntry('Quest Gen', eventCounts['ai_quest_generation'] ?? 0),
      MapEntry('VP Earned', eventCounts['vp_earned'] ?? 0),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🤖 AI Feature Adoption',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            // Top Features Bar Chart
            Text(
              'Top Features (Event Count)',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 20.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      topFeatures
                          .map((e) => e.value.toDouble())
                          .fold(1.0, (a, b) => a > b ? a : b) *
                      1.2,
                  barGroups: topFeatures.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          color: [
                            Colors.blue,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                          ][entry.key % 5],
                          width: 6.w,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < topFeatures.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                topFeatures[idx].key,
                                style: TextStyle(fontSize: 8.sp),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 8.sp),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            // 7-day trend line chart (mock data)
            Text(
              '7-Day Adoption Trend',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 15.h,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(7, (i) {
                        final base = topFeatures.fold(
                          0,
                          (sum, e) => sum + e.value,
                        );
                        return FlSpot(
                          i.toDouble(),
                          (base * (0.5 + i * 0.1)).clamp(0, double.infinity),
                        );
                      }),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(30),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun',
                          ];
                          final idx = value.toInt();
                          return Text(
                            idx < days.length ? days[idx] : '',
                            style: TextStyle(fontSize: 8.sp),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            // User Segments Pie Chart
            Text(
              'User Segments by Feature Usage',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 18.h,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 40,
                            title: 'Power\nUsers',
                            color: Colors.blue,
                            radius: 8.w,
                            titleStyle: TextStyle(
                              fontSize: 8.sp,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 35,
                            title: 'New\nUsers',
                            color: Colors.green,
                            radius: 8.w,
                            titleStyle: TextStyle(
                              fontSize: 8.sp,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 25,
                            title: 'Creators',
                            color: Colors.orange,
                            radius: 8.w,
                            titleStyle: TextStyle(
                              fontSize: 8.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        centerSpaceRadius: 5.w,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(Colors.blue, 'Power Users', '40%'),
                      SizedBox(height: 1.h),
                      _buildLegendItem(Colors.green, 'New Users', '35%'),
                      SizedBox(height: 1.h),
                      _buildLegendItem(Colors.orange, 'Creators', '25%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Row(
      children: [
        Container(width: 3.w, height: 3.w, color: color),
        SizedBox(width: 1.w),
        Text('$label: $value', style: TextStyle(fontSize: 10.sp)),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }
}
