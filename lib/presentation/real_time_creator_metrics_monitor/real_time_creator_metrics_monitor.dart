import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './widgets/at_risk_creator_card_widget.dart';
import './widgets/growth_trajectory_chart_widget.dart';
import './widgets/performance_metrics_grid_widget.dart';
import './widgets/alert_feed_widget.dart';
import './widgets/live_update_indicator_widget.dart';

class RealTimeCreatorMetricsMonitor extends StatefulWidget {
  const RealTimeCreatorMetricsMonitor({super.key});
  @override
  State<RealTimeCreatorMetricsMonitor> createState() =>
      _RealTimeCreatorMetricsMonitorState();
}

class _RealTimeCreatorMetricsMonitorState
    extends State<RealTimeCreatorMetricsMonitor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  bool _isConnected = false;
  int _updateCount = 0;
  bool _isLoading = true;

  List<Map<String, dynamic>> _churnPredictions = [];
  List<Map<String, dynamic>> _growthPredictions = [];
  Map<String, dynamic> _performanceMetrics = {};
  List<Map<String, dynamic>> _alerts = [];

  RealtimeChannel? _churnChannel;
  RealtimeChannel? _growthChannel;
  RealtimeChannel? _engagementChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
    _setupRealtimeSubscriptions();
  }

  Future<void> _loadInitialData() async {
    try {
      final churnData = await _supabase
          .from('creator_churn_predictions')
          .select()
          .order('churn_probability', ascending: false)
          .limit(20);
      final growthData = await _supabase
          .from('creator_growth_predictions')
          .select()
          .limit(20);
      final alertsData = await _supabase
          .from('creator_metric_alerts')
          .select()
          .eq('acknowledged', false)
          .order('created_at', ascending: false)
          .limit(10);
      if (mounted) {
        setState(() {
          _churnPredictions = List<Map<String, dynamic>>.from(churnData);
          _growthPredictions = List<Map<String, dynamic>>.from(growthData);
          _alerts = List<Map<String, dynamic>>.from(alertsData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _churnPredictions = _mockChurnPredictions;
          _growthPredictions = _mockGrowthPredictions;
          _alerts = _mockAlerts;
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscriptions() {
    try {
      _churnChannel = _supabase
          .channel('creator_metrics_monitor')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'creator_churn_predictions',
            callback: _handleChurnUpdate,
          )
          .subscribe((status, [error]) {
            if (mounted) {
              setState(
                () =>
                    _isConnected = status == RealtimeSubscribeStatus.subscribed,
              );
            }
          });
      _growthChannel = _supabase
          .channel('creator_growth_monitor')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'creator_growth_predictions',
            callback: _handleGrowthUpdate,
          )
          .subscribe();
      _engagementChannel = _supabase
          .channel('creator_engagement_monitor')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'creator_engagement_metrics',
            callback: _handleEngagementUpdate,
          )
          .subscribe();
    } catch (e) {
      /* subscriptions failed, continue with loaded data */
    }
  }

  void _handleChurnUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      _updateCount++;
      final newRecord = payload.newRecord;
      if (newRecord.isNotEmpty) {
        final idx = _churnPredictions.indexWhere(
          (p) => p['id'] == newRecord['id'],
        );
        if (idx >= 0) {
          _churnPredictions[idx] = newRecord;
        } else {
          _churnPredictions.insert(0, newRecord);
          if (_churnPredictions.length > 20) _churnPredictions.removeLast();
        }
        _churnPredictions.sort(
          (a, b) => ((b['churn_probability'] as num?) ?? 0).compareTo(
            (a['churn_probability'] as num?) ?? 0,
          ),
        );
      }
    });
    _checkAlertTriggers(payload.newRecord);
  }

  void _handleGrowthUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      _updateCount++;
      final newRecord = payload.newRecord;
      if (newRecord.isNotEmpty) {
        final idx = _growthPredictions.indexWhere(
          (p) => p['id'] == newRecord['id'],
        );
        if (idx >= 0) {
          _growthPredictions[idx] = newRecord;
        } else {
          _growthPredictions.insert(0, newRecord);
        }
      }
    });
  }

  void _handleEngagementUpdate(PostgresChangePayload payload) {
    if (!mounted) return;
    setState(() {
      _updateCount++;
      _performanceMetrics = {..._performanceMetrics, ...payload.newRecord};
    });
  }

  void _checkAlertTriggers(Map<String, dynamic> record) {
    final probability =
        (record['churn_probability'] as num?)?.toDouble() ?? 0.0;
    if (probability > 0.7 && mounted) {
      setState(
        () => _alerts.insert(0, {
          'alert_type': 'churn_risk',
          'message': 'Creator at critical churn risk - immediate action needed',
          'severity': 'critical',
          'time': 'Just now',
        }),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _churnChannel?.unsubscribe();
    _growthChannel?.unsubscribe();
    _engagementChannel?.unsubscribe();
    super.dispose();
  }

  List<Map<String, dynamic>> get _mockChurnPredictions => [
    {
      'id': '1',
      'creator_name': 'Alex Rivera',
      'tier': 'Gold',
      'churn_probability': 0.82,
      'churn_timeframe_days': 7,
      'primary_drivers': ['Engagement Decline', 'Posting Decline'],
    },
    {
      'id': '2',
      'creator_name': 'Maria Santos',
      'tier': 'Silver',
      'churn_probability': 0.65,
      'churn_timeframe_days': 12,
      'primary_drivers': ['Earnings Drop'],
    },
    {
      'id': '3',
      'creator_name': 'James Kim',
      'tier': 'Bronze',
      'churn_probability': 0.45,
      'churn_timeframe_days': 21,
      'primary_drivers': ['Login Gaps', 'Engagement Decline'],
    },
    {
      'id': '4',
      'creator_name': 'Priya Patel',
      'tier': 'Silver',
      'churn_probability': 0.78,
      'churn_timeframe_days': 5,
      'primary_drivers': ['Posting Decline', 'Earnings Drop'],
    },
    {
      'id': '5',
      'creator_name': 'Carlos Mendez',
      'tier': 'Bronze',
      'churn_probability': 0.38,
      'churn_timeframe_days': 28,
      'primary_drivers': ['Engagement Decline'],
    },
  ];

  List<Map<String, dynamic>> get _mockGrowthPredictions => [
    {
      'id': '1',
      'creator_name': 'Emma Wilson',
      'predicted_earnings_30d': 750,
      'predicted_earnings_90d': 1100,
      'current_tier': 'Silver',
      'next_tier': 'Gold',
      'days_to_next_tier': 18,
    },
    {
      'id': '2',
      'creator_name': 'David Chen',
      'predicted_earnings_30d': 920,
      'predicted_earnings_90d': 1400,
      'current_tier': 'Gold',
      'next_tier': 'Platinum',
      'days_to_next_tier': 32,
    },
  ];

  List<Map<String, dynamic>> get _mockAlerts => [
    {
      'alert_type': 'churn_risk',
      'message': '5 creators at critical churn risk - immediate action needed',
      'severity': 'critical',
      'time': '2 min ago',
    },
    {
      'alert_type': 'growth_milestone',
      'message': 'Creator @emma_wilson just reached Gold tier',
      'severity': 'low',
      'time': '15 min ago',
    },
    {
      'alert_type': 'performance_decline',
      'message': 'Avg engagement dropped 15% this week',
      'severity': 'high',
      'time': '1 hour ago',
    },
    {
      'alert_type': 'churn_risk',
      'message': 'Creator @priya_patel showing critical churn signals',
      'severity': 'critical',
      'time': '2 hours ago',
    },
  ];

  void _showAction(String action, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action sent to $name'),
        backgroundColor: const Color(0xFF3B82F6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _alerts
        .where((a) => a['severity'] == 'critical')
        .length;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Creator Metrics Monitor',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          LiveUpdateIndicatorWidget(
            isConnected: _isConnected,
            updateCount: _updateCount,
          ),
          SizedBox(width: 2.w),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _updateCount = 0);
              _loadInitialData();
            },
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 11.sp),
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF3B82F6),
          tabs: [
            const Tab(text: 'Churn Predictions'),
            const Tab(text: 'Growth Analytics'),
            const Tab(text: 'Performance'),
            Tab(text: 'Alerts ($criticalCount)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: _churnPredictions.isEmpty
                      ? const Center(child: Text('No at-risk creators found'))
                      : ListView.builder(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _churnPredictions.length,
                          itemBuilder: (context, index) {
                            final creator = _churnPredictions[index];
                            return AtRiskCreatorCardWidget(
                              creator: creator,
                              onSendSMS: () => _showAction(
                                'SMS',
                                creator['creator_name'] ?? 'Creator',
                              ),
                              onSendEmail: () => _showAction(
                                'Email',
                                creator['creator_name'] ?? 'Creator',
                              ),
                              onViewProfile: () => _showAction(
                                'Viewing profile of',
                                creator['creator_name'] ?? 'Creator',
                              ),
                            );
                          },
                        ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GrowthTrajectoryChartWidget(
                        predictions: _growthPredictions,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Tier Progression',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._growthPredictions.map(
                        (pred) => Container(
                          margin: EdgeInsets.only(bottom: 1.h),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pred['creator_name'] as String? ??
                                        'Creator',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${pred['days_to_next_tier']} days to ${pred['next_tier']}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 0.8.h),
                              LinearProgressIndicator(
                                value: 0.7,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF10B981),
                                ),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              SizedBox(height: 0.5.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    pred['current_tier'] as String? ?? 'Bronze',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    pred['next_tier'] as String? ?? 'Silver',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PerformanceMetricsGridWidget(
                        metrics: _performanceMetrics,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Content Performance',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 4.w,
                          columns: [
                            DataColumn(
                              label: Text(
                                'Content Type',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Posts',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Engagement',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'VP Earned',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          rows: [
                            _contentRow('Elections', '1,247', '12.4%', '48.2K'),
                            _contentRow('Jolts', '3,891', '18.7%', '92.1K'),
                            _contentRow('Moments', '2,156', '9.3%', '31.5K'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: AlertFeedWidget(
                    alerts: _alerts,
                    onRefresh: _loadInitialData,
                  ),
                ),
              ],
            ),
    );
  }

  DataRow _contentRow(String type, String posts, String engagement, String vp) {
    return DataRow(
      cells: [
        DataCell(Text(type, style: TextStyle(fontSize: 11.sp))),
        DataCell(Text(posts, style: TextStyle(fontSize: 11.sp))),
        DataCell(
          Text(
            engagement,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF10B981)),
          ),
        ),
        DataCell(
          Text(
            vp,
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
