import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../vote_results/widgets/statistics_card_widget.dart';
import '../vote_results/widgets/timeline_graph_widget.dart';
import '../vote_results/widgets/demographic_filter_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class VoteAnalytics extends StatefulWidget {
  const VoteAnalytics({super.key});

  @override
  State<VoteAnalytics> createState() => _VoteAnalyticsState();
}

class _VoteAnalyticsState extends State<VoteAnalytics> {
  bool _showDemographics = false;
  String _selectedTimePeriod = 'All Time';
  bool _isLoading = false;
  final String _selectedMetric = 'participation';

  final Map<String, dynamic> _analyticsData = {
    'overview': {
      'total_votes_created': 47,
      'total_participants': 3842,
      'average_participation_rate': 76.3,
      'total_engagement_hours': 1247,
    },
    'participation_trends': [
      {'date': 'Jan 28', 'participants': 234},
      {'date': 'Jan 29', 'participants': 312},
      {'date': 'Jan 30', 'participants': 289},
      {'date': 'Jan 31', 'participants': 401},
      {'date': 'Feb 1', 'participants': 378},
      {'date': 'Feb 2', 'participants': 456},
      {'date': 'Feb 3', 'participants': 523},
      {'date': 'Feb 4', 'participants': 489},
    ],
    'engagement_heatmap': {
      'Monday': [
        12,
        23,
        45,
        67,
        89,
        123,
        156,
        134,
        98,
        76,
        54,
        32,
        21,
        34,
        56,
        78,
        98,
        145,
        167,
        189,
        156,
        123,
        89,
        45,
      ],
      'Tuesday': [
        15,
        28,
        52,
        74,
        96,
        134,
        167,
        145,
        112,
        89,
        67,
        45,
        28,
        41,
        63,
        85,
        107,
        156,
        178,
        201,
        178,
        145,
        112,
        67,
      ],
      'Wednesday': [
        18,
        31,
        58,
        81,
        103,
        145,
        178,
        156,
        123,
        98,
        76,
        54,
        35,
        48,
        70,
        92,
        114,
        167,
        189,
        212,
        189,
        156,
        123,
        78,
      ],
      'Thursday': [
        21,
        34,
        64,
        88,
        110,
        156,
        189,
        167,
        134,
        107,
        85,
        63,
        42,
        55,
        77,
        99,
        121,
        178,
        200,
        223,
        200,
        167,
        134,
        89,
      ],
      'Friday': [
        24,
        37,
        70,
        95,
        117,
        167,
        200,
        178,
        145,
        116,
        94,
        72,
        49,
        62,
        84,
        106,
        128,
        189,
        211,
        234,
        211,
        178,
        145,
        100,
      ],
      'Saturday': [
        10,
        19,
        38,
        57,
        76,
        95,
        114,
        133,
        152,
        171,
        190,
        209,
        228,
        247,
        266,
        285,
        304,
        323,
        342,
        361,
        342,
        323,
        304,
        285,
      ],
      'Sunday': [
        8,
        16,
        32,
        48,
        64,
        80,
        96,
        112,
        128,
        144,
        160,
        176,
        192,
        208,
        224,
        240,
        256,
        272,
        288,
        304,
        288,
        272,
        256,
        240,
      ],
    },
    'demographics': {
      'age_groups': {'18-30': 1234, '31-45': 1567, '46-60': 789, '60+': 252},
      'device_breakdown': {'mobile': 2847, 'tablet': 623, 'desktop': 372},
      'location': {'urban': 2456, 'suburban': 1123, 'rural': 263},
    },
    'performance_metrics': [
      {
        'vote_title': 'Community Park Renovation',
        'participants': 1247,
        'engagement_rate': 89.2,
        'avg_time': '2m 34s',
      },
      {
        'vote_title': 'Library Hours Extension',
        'participants': 892,
        'engagement_rate': 76.8,
        'avg_time': '1m 52s',
      },
      {
        'vote_title': 'School Budget Allocation',
        'participants': 1534,
        'engagement_rate': 92.1,
        'avg_time': '3m 12s',
      },
      {
        'vote_title': 'Traffic Light Installation',
        'participants': 567,
        'engagement_rate': 64.3,
        'avg_time': '1m 28s',
      },
      {
        'vote_title': 'Community Center Programs',
        'participants': 602,
        'engagement_rate': 71.5,
        'avg_time': '2m 05s',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'VoteAnalytics',
      onRetry: _refreshAnalytics,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Vote Analytics'),
          actions: [
            IconButton(
              icon: Icon(Icons.download),
              onPressed: _exportAnalytics,
              tooltip: 'Export Analytics',
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _analyticsData.isEmpty
            ? NoDataEmptyState(
                title: 'No Analytics Data',
                description:
                    'Vote analytics will appear once you participate in elections.',
                onRefresh: _refreshAnalytics,
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewSection(),
                    SizedBox(height: 3.h),
                    _buildFilterSection(),
                    SizedBox(height: 2.h),
                    _buildParticipationTrendsSection(),
                    SizedBox(height: 3.h),
                    _buildEngagementHeatmapSection(),
                    SizedBox(height: 3.h),
                    _buildDemographicsSection(),
                    SizedBox(height: 3.h),
                    _buildPerformanceMetricsSection(),
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final overview = _analyticsData['overview'] as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
          SizedBox(height: 2.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 3.w,
            crossAxisSpacing: 3.w,
            childAspectRatio: 1.3,
            children: [
              StatisticsCardWidget(
                title: 'Votes Created',
                value: overview['total_votes_created'].toString(),
                icon: 'how_to_vote',
                color: const Color(0xFF3B82F6),
              ),
              StatisticsCardWidget(
                title: 'Total Participants',
                value: overview['total_participants'].toString(),
                icon: 'people',
                color: const Color(0xFF10B981),
              ),
              StatisticsCardWidget(
                title: 'Avg Participation',
                value: '${overview['average_participation_rate']}%',
                icon: 'trending_up',
                color: const Color(0xFF8B5CF6),
              ),
              StatisticsCardWidget(
                title: 'Engagement Hours',
                value: overview['total_engagement_hours'].toString(),
                icon: 'schedule',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: DemographicFilterWidget(
        showDemographics: _showDemographics,
        selectedTimePeriod: _selectedTimePeriod,
        onDemographicsChanged: (value) {
          setState(() => _showDemographics = value);
        },
        onTimePeriodChanged: (value) {
          if (value != null) {
            setState(() => _selectedTimePeriod = value);
          }
        },
      ),
    );
  }

  Widget _buildParticipationTrendsSection() {
    final trends = _analyticsData['participation_trends'] as List;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participation Trends',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
          SizedBox(height: 2.h),
          TimelineGraphWidget(
            timelineData: trends
                .map((t) => {'hour': t['date'], 'votes': t['participants']})
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementHeatmapSection() {
    final heatmapData =
        _analyticsData['engagement_heatmap'] as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voter Engagement Heatmap',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
          SizedBox(height: 1.h),
          Text(
            'Peak engagement times throughout the week',
            style: TextStyle(color: Colors.black.withAlpha(153)),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withAlpha(51), width: 1),
            ),
            child: Column(
              children: heatmapData.entries.map((entry) {
                final day = entry.key;
                final hourlyData = entry.value as List;
                final maxValue = hourlyData.reduce((a, b) => a > b ? a : b);

                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: List.generate(24, (hour) {
                          final value = hourlyData[hour];
                          final intensity = value / maxValue;
                          return Expanded(
                            child: Container(
                              height: 3.h,
                              margin: EdgeInsets.only(right: 0.5.w),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(
                                  intensity * 0.8 + 0.2,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12 AM',
                style: TextStyle(color: Colors.black.withAlpha(153)),
              ),
              Text(
                '6 AM',
                style: TextStyle(color: Colors.black.withAlpha(153)),
              ),
              Text(
                '12 PM',
                style: TextStyle(color: Colors.black.withAlpha(153)),
              ),
              Text(
                '6 PM',
                style: TextStyle(color: Colors.black.withAlpha(153)),
              ),
              Text(
                '11 PM',
                style: TextStyle(color: Colors.black.withAlpha(153)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection() {
    if (!_showDemographics) return const SizedBox.shrink();

    final demographics = _analyticsData['demographics'] as Map<String, dynamic>;
    final ageGroups = demographics['age_groups'] as Map<String, dynamic>;
    final deviceBreakdown =
        demographics['device_breakdown'] as Map<String, dynamic>;
    final location = demographics['location'] as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demographic Breakdown',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
          SizedBox(height: 2.h),
          _buildDemographicCard('Age Groups', ageGroups, Icons.cake),
          SizedBox(height: 2.h),
          _buildDemographicCard('Device Usage', deviceBreakdown, Icons.devices),
          SizedBox(height: 2.h),
          _buildDemographicCard('Location', location, Icons.location_on),
        ],
      ),
    );
  }

  Widget _buildDemographicCard(
    String title,
    Map<String, dynamic> data,
    IconData icon,
  ) {
    final total = data.values.fold<int>(
      0,
      (sum, value) => sum + (value as int),
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withAlpha(51), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 20),
              SizedBox(width: 2.w),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...data.entries.map((entry) {
            final percentage = ((entry.value as int) / total * 100)
                .toStringAsFixed(1);
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: TextStyle(color: Colors.black)),
                      Text(
                        '${entry.value} ($percentage%)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  LinearProgressIndicator(
                    value: (entry.value as int) / total,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsSection() {
    final metrics = _analyticsData['performance_metrics'] as List;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
          SizedBox(height: 1.h),
          Text(
            'Top performing votes by engagement',
            style: TextStyle(color: Colors.black.withAlpha(153)),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withAlpha(51), width: 1),
            ),
            child: Column(
              children: metrics.map((metric) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric['vote_title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricItem(
                            'Participants',
                            metric['participants'].toString(),
                            Icons.people,
                          ),
                          _buildMetricItem(
                            'Engagement',
                            '${metric['engagement_rate']}%',
                            Icons.trending_up,
                          ),
                          _buildMetricItem(
                            'Avg Time',
                            metric['avg_time'],
                            Icons.schedule,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 16),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        Text(label, style: TextStyle(color: Colors.black.withAlpha(153))),
      ],
    );
  }

  Future<void> _refreshAnalytics() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _exportAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics exported successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
