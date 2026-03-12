import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class PushNotificationIntelligenceHub extends StatefulWidget {
  const PushNotificationIntelligenceHub({super.key});

  @override
  State<PushNotificationIntelligenceHub> createState() =>
      _PushNotificationIntelligenceHubState();
}

class _PushNotificationIntelligenceHubState
    extends State<PushNotificationIntelligenceHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Timer? _refreshTimer;

  final Map<String, dynamic> _timingEngineStats = {
    'optimal_windows_detected': 847,
    'avg_engagement_lift': 34.2,
    'prediction_accuracy': 87.6,
    'active_users_analyzed': 12450,
  };

  final List<Map<String, dynamic>> _activityPatterns = [];

  final List<Map<String, dynamic>> _abTestResults = [
    {
      'test_name': 'Morning vs Evening Delivery',
      'variant_a': 'Morning (7-9 AM)',
      'variant_b': 'Evening (7-9 PM)',
      'open_rate_a': 42.3,
      'open_rate_b': 38.7,
      'click_rate_a': 18.9,
      'click_rate_b': 15.2,
      'sample_size': 5420,
      'confidence': 94.2,
      'winner': 'A',
      'status': 'completed',
    },
    {
      'test_name': 'Personalized vs Fixed Windows',
      'variant_a': 'ML-Personalized',
      'variant_b': 'Fixed 10 AM',
      'open_rate_a': 51.8,
      'open_rate_b': 35.4,
      'click_rate_a': 24.1,
      'click_rate_b': 14.8,
      'sample_size': 8930,
      'confidence': 99.1,
      'winner': 'A',
      'status': 'completed',
    },
    {
      'test_name': 'Quiet Hours Respect vs Aggressive',
      'variant_a': 'Respect Quiet Hours',
      'variant_b': 'Send Anytime',
      'open_rate_a': 48.6,
      'open_rate_b': 29.3,
      'click_rate_a': 21.4,
      'click_rate_b': 11.7,
      'sample_size': 3210,
      'confidence': 97.8,
      'winner': 'A',
      'status': 'completed',
    },
    {
      'test_name': 'Weekday vs Weekend Timing',
      'variant_a': 'Weekday Optimized',
      'variant_b': 'Weekend Optimized',
      'open_rate_a': 44.1,
      'open_rate_b': 41.9,
      'click_rate_a': 19.3,
      'click_rate_b': 18.7,
      'sample_size': 2840,
      'confidence': 61.3,
      'winner': null,
      'status': 'running',
    },
  ];

  final List<Map<String, dynamic>> _deviceStateData = [
    {
      'state': 'Active Screen',
      'icon': 'phone_android',
      'percentage': 28.4,
      'avg_open_rate': 67.2,
      'color': Colors.green,
    },
    {
      'state': 'Background App',
      'icon': 'layers',
      'percentage': 34.1,
      'avg_open_rate': 52.8,
      'color': Colors.blue,
    },
    {
      'state': 'Screen Off',
      'icon': 'phone_locked',
      'percentage': 31.7,
      'avg_open_rate': 38.4,
      'color': Colors.orange,
    },
    {
      'state': 'Low Battery (<20%)',
      'icon': 'battery_alert',
      'percentage': 5.8,
      'avg_open_rate': 22.1,
      'color': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _engagementCohorts = [
    {
      'cohort': 'Power Users',
      'size': 2340,
      'optimal_window': '8-10 AM',
      'avg_open_rate': 72.4,
      'avg_click_rate': 34.8,
      'preferred_frequency': 'Daily',
      'churn_risk': 'Low',
    },
    {
      'cohort': 'Regular Voters',
      'size': 5670,
      'optimal_window': '7-9 PM',
      'avg_open_rate': 54.2,
      'avg_click_rate': 22.1,
      'preferred_frequency': '3x/week',
      'churn_risk': 'Low',
    },
    {
      'cohort': 'Casual Users',
      'size': 3210,
      'optimal_window': '12-2 PM',
      'avg_open_rate': 38.7,
      'avg_click_rate': 14.3,
      'preferred_frequency': 'Weekly',
      'churn_risk': 'Medium',
    },
    {
      'cohort': 'At-Risk Users',
      'size': 1230,
      'optimal_window': 'Weekend AM',
      'avg_open_rate': 21.4,
      'avg_click_rate': 7.8,
      'preferred_frequency': 'Bi-weekly',
      'churn_risk': 'High',
    },
  ];

  final List<Map<String, dynamic>> _timingRules = [
    {
      'rule': 'Respect Quiet Hours',
      'description': 'No notifications between 10 PM - 7 AM local time',
      'enabled': true,
      'impact': '+18.3% open rate',
    },
    {
      'rule': 'Activity-Based Delivery',
      'description': 'Deliver when user was active in last 2 hours',
      'enabled': true,
      'impact': '+34.2% engagement',
    },
    {
      'rule': 'Battery State Awareness',
      'description': 'Defer non-critical notifications when battery < 15%',
      'enabled': true,
      'impact': '-12% uninstall rate',
    },
    {
      'rule': 'Frequency Capping',
      'description': 'Max 3 notifications per day per user',
      'enabled': true,
      'impact': '-28% opt-out rate',
    },
    {
      'rule': 'Engagement Score Weighting',
      'description':
          'Prioritize high-engagement users for time-sensitive alerts',
      'enabled': false,
      'impact': '+22.1% CTR',
    },
    {
      'rule': 'Network Quality Check',
      'description': 'Retry delivery when user on WiFi vs cellular',
      'enabled': true,
      'impact': '+8.7% delivery rate',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateActivityPatterns();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _generateActivityPatterns() {
    final random = Random(42);
    for (int hour = 0; hour < 24; hour++) {
      double baseActivity;
      if (hour >= 7 && hour <= 9) {
        baseActivity = 0.7 + random.nextDouble() * 0.3;
      } else if (hour >= 12 && hour <= 14) {
        baseActivity = 0.5 + random.nextDouble() * 0.3;
      } else if (hour >= 19 && hour <= 22) {
        baseActivity = 0.8 + random.nextDouble() * 0.2;
      } else if (hour >= 0 && hour <= 6) {
        baseActivity = 0.05 + random.nextDouble() * 0.1;
      } else {
        baseActivity = 0.3 + random.nextDouble() * 0.3;
      }
      _activityPatterns.add({
        'hour': hour,
        'activity_score': baseActivity,
        'open_rate': (baseActivity * 60 + random.nextDouble() * 10).clamp(
          0,
          100,
        ),
        'label': '${hour.toString().padLeft(2, '0')}:00',
      });
    }
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isLoading = false);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _timingEngineStats['optimal_windows_detected'] =
              (_timingEngineStats['optimal_windows_detected'] as int) +
              Random().nextInt(5);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: 'Push Notification Intelligence',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(38),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.green.withAlpha(102)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 1.5.w),
                  Text(
                    'Engine Active',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildEngineStatsHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivityPatternsTab(),
                      _buildABTestingTab(),
                      _buildDeviceStateTab(),
                      _buildEngagementCohortsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEngineStatsHeader() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withAlpha(38),
            Colors.purple.withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'psychology',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              SizedBox(width: 2.w),
              Text(
                'Behavioral Timing Engine',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Optimal Windows',
                  '${_timingEngineStats['optimal_windows_detected']}',
                  'detected today',
                  Colors.blue,
                  'schedule',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Engagement Lift',
                  '+${_timingEngineStats['avg_engagement_lift']}%',
                  'vs baseline',
                  Colors.green,
                  'trending_up',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Prediction Accuracy',
                  '${_timingEngineStats['prediction_accuracy']}%',
                  'ML model',
                  Colors.purple,
                  'auto_awesome',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    String icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(iconName: icon, size: 5.w, color: color),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceLight,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Activity Patterns'),
          Tab(text: 'A/B Testing'),
          Tab(text: 'Device State'),
          Tab(text: 'Cohorts'),
        ],
      ),
    );
  }

  Widget _buildActivityPatternsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Activity Heatmap (24h)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Optimal notification windows based on historical engagement patterns',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 25.h,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final pattern = _activityPatterns[group.x.toInt()];
                      return BarTooltipItem(
                        '${pattern['label']}\n${(pattern['activity_score'] * 100).toStringAsFixed(0)}% active',
                        TextStyle(color: Colors.white, fontSize: 10.sp),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 4 == 0) {
                          return Text(
                            '${value.toInt()}h',
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _activityPatterns.asMap().entries.map((entry) {
                  final pattern = entry.value;
                  final score = pattern['activity_score'] as double;
                  Color barColor;
                  if (score > 0.7) {
                    barColor = Colors.green;
                  } else if (score > 0.4) {
                    barColor = Colors.orange;
                  } else {
                    barColor = Colors.red.withAlpha(153);
                  }
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: score,
                        color: barColor,
                        width: 3.w,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildLegendItem('Optimal (>70%)', Colors.green),
              SizedBox(width: 4.w),
              _buildLegendItem('Moderate (40-70%)', Colors.orange),
              SizedBox(width: 4.w),
              _buildLegendItem('Low (<40%)', Colors.red.withAlpha(153)),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Timing Optimization Rules',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          ..._timingRules.map((rule) => _buildTimingRuleCard(rule)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildTimingRuleCard(Map<String, dynamic> rule) {
    final isEnabled = rule['enabled'] as bool;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryLight.withAlpha(77)
              : AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule['rule'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  rule['description'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    rule['impact'] as String,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (val) => setState(() => rule['enabled'] = val),
            activeThumbColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildABTestingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notification Window A/B Tests',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New A/B test created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: CustomIconWidget(
                  iconName: 'add',
                  size: 4.w,
                  color: Colors.white,
                ),
                label: Text('New Test', style: TextStyle(fontSize: 11.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ..._abTestResults.map((test) => _buildABTestCard(test)),
        ],
      ),
    );
  }

  Widget _buildABTestCard(Map<String, dynamic> test) {
    final isRunning = test['status'] == 'running';
    final winner = test['winner'] as String?;
    final confidence = test['confidence'] as double;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isRunning
              ? Colors.blue.withAlpha(102)
              : Colors.green.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  test['test_name'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: isRunning
                      ? Colors.blue.withAlpha(38)
                      : Colors.green.withAlpha(38),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  isRunning ? '🔄 Running' : '✅ Completed',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isRunning ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildVariantColumn(
                  'Variant A',
                  test['variant_a'] as String,
                  test['open_rate_a'] as double,
                  test['click_rate_a'] as double,
                  winner == 'A',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildVariantColumn(
                  'Variant B',
                  test['variant_b'] as String,
                  test['open_rate_b'] as double,
                  test['click_rate_b'] as double,
                  winner == 'B',
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sample: ${test['sample_size']} users',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: confidence >= 95
                      ? Colors.green.withAlpha(26)
                      : Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Confidence: ${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: confidence >= 95 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantColumn(
    String label,
    String name,
    double openRate,
    double clickRate,
    bool isWinner,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isWinner ? color.withAlpha(26) : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isWinner ? color.withAlpha(102) : Colors.grey.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (isWinner) ...[
                SizedBox(width: 1.w),
                Text('🏆', style: TextStyle(fontSize: 10.sp)),
              ],
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            name,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          SizedBox(height: 1.h),
          Text(
            'Open: ${openRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            'Click: ${clickRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStateTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device State Awareness',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Notification delivery optimization based on device state at send time',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._deviceStateData.map((state) => _buildDeviceStateCard(state)),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Strategy by Device State',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 1.5.h),
                _buildStrategyRow(
                  'Active Screen',
                  'Send immediately — highest engagement window',
                  Colors.green,
                ),
                _buildStrategyRow(
                  'Background App',
                  'Send with high-priority flag for banner display',
                  Colors.blue,
                ),
                _buildStrategyRow(
                  'Screen Off',
                  'Queue for next active session (within 2h)',
                  Colors.orange,
                ),
                _buildStrategyRow(
                  'Low Battery',
                  'Defer non-critical; send critical only',
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStateCard(Map<String, dynamic> state) {
    final color = state['color'] as Color;
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: state['icon'] as String,
                size: 6.w,
                color: color,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state['state'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${state['percentage']}% of deliveries',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state['avg_open_rate']}%',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'open rate',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyRow(String state, String strategy, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2.5.w,
            height: 2.5.w,
            margin: EdgeInsets.only(top: 0.5.h),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  strategy,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCohortsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement History Cohorts',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Personalized delivery windows based on historical engagement patterns per cohort',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ..._engagementCohorts.map((cohort) => _buildCohortCard(cohort)),
        ],
      ),
    );
  }

  Widget _buildCohortCard(Map<String, dynamic> cohort) {
    final churnRisk = cohort['churn_risk'] as String;
    Color churnColor;
    if (churnRisk == 'Low') {
      churnColor = Colors.green;
    } else if (churnRisk == 'Medium') {
      churnColor = Colors.orange;
    } else {
      churnColor = Colors.red;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cohort['cohort'] as String,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: churnColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '$churnRisk Churn Risk',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: churnColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            '${cohort['size']} users · ${cohort['preferred_frequency']} preferred',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildCohortMetric(
                  'Optimal Window',
                  cohort['optimal_window'] as String,
                  'schedule',
                  AppTheme.primaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildCohortMetric(
                  'Open Rate',
                  '${cohort['avg_open_rate']}%',
                  'mail',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildCohortMetric(
                  'Click Rate',
                  '${cohort['avg_click_rate']}%',
                  'touch_app',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCohortMetric(
    String label,
    String value,
    String icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: icon, size: 4.w, color: color),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}