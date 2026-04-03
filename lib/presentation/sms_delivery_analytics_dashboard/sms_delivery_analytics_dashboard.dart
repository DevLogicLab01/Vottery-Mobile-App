import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:csv/csv.dart';
import '../../core/app_export.dart';
import '../../services/sms_alerts_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/delivery_metrics_overview_widget.dart';
import './widgets/provider_comparison_widget.dart';
import './widgets/delivery_performance_chart_widget.dart';
import './widgets/bounce_analysis_widget.dart';
import './widgets/failover_history_widget.dart';
import './widgets/latency_analysis_widget.dart';

/// SMS Delivery Analytics Dashboard
/// Comprehensive SMS performance tracking with provider comparison and delivery optimization
class SmsDeliveryAnalyticsDashboard extends StatefulWidget {
  const SmsDeliveryAnalyticsDashboard({super.key});

  @override
  State<SmsDeliveryAnalyticsDashboard> createState() =>
      _SmsDeliveryAnalyticsDashboardState();
}

class _SmsDeliveryAnalyticsDashboardState
    extends State<SmsDeliveryAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _smsAlertsService = SmsAlertsService.instance;
  final _supabase = SupabaseService.instance.client;

  Map<String, dynamic> _overviewMetrics = {};
  Map<String, dynamic> _providerComparison = {};
  List<Map<String, dynamic>> _deliveryPerformance = [];
  List<Map<String, dynamic>> _bounceAnalysis = [];
  List<Map<String, dynamic>> _failoverHistory = [];
  Map<String, dynamic> _latencyMetrics = {};
  bool _isLoading = true;
  String _selectedTimeRange = '24h';
  StreamSubscription? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
    _subscribeToRealtimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final hours = _getHoursFromTimeRange(_selectedTimeRange);

      final results = await Future.wait([
        _loadOverviewMetrics(hours),
        _loadProviderComparison(hours),
        _loadDeliveryPerformance(hours),
        _loadBounceAnalysis(),
        _loadFailoverHistory(hours),
        _loadLatencyMetrics(hours),
      ]);

      if (mounted) {
        setState(() {
          _overviewMetrics = results[0] as Map<String, dynamic>;
          _providerComparison = results[1] as Map<String, dynamic>;
          _deliveryPerformance = results[2] as List<Map<String, dynamic>>;
          _bounceAnalysis = results[3] as List<Map<String, dynamic>>;
          _failoverHistory = results[4] as List<Map<String, dynamic>>;
          _latencyMetrics = results[5] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load analytics error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getHoursFromTimeRange(String range) {
    switch (range) {
      case '1h':
        return 1;
      case '6h':
        return 6;
      case '24h':
        return 24;
      case '7d':
        return 168;
      case '30d':
        return 720;
      default:
        return 24;
    }
  }

  Future<Map<String, dynamic>> _loadOverviewMetrics(int hours) async {
    try {
      final startDate = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('sms_delivery_log')
          .select('delivery_status, provider_used, sent_at, delivered_at')
          .gte('sent_at', startDate.toIso8601String());

      final logs = List<Map<String, dynamic>>.from(response);

      final totalSent = logs.length;
      final delivered = logs
          .where((l) => l['delivery_status'] == 'delivered')
          .length;
      final failed = logs.where((l) => l['delivery_status'] == 'failed').length;
      final bounced = logs
          .where((l) => l['delivery_status'] == 'bounced')
          .length;

      final deliveryRate = totalSent > 0 ? (delivered / totalSent * 100) : 0.0;
      final bounceRate = totalSent > 0 ? (bounced / totalSent * 100) : 0.0;

      // Get failover count
      final failoverResponse = await _supabase
          .from('provider_failover_log')
          .select('failover_id')
          .gte('failed_at', startDate.toIso8601String());

      final failoverCount = failoverResponse.length;

      return {
        'total_sent': totalSent,
        'delivered': delivered,
        'failed': failed,
        'bounced': bounced,
        'delivery_rate': deliveryRate,
        'bounce_rate': bounceRate,
        'failover_count': failoverCount,
      };
    } catch (e) {
      debugPrint('Load overview metrics error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _loadProviderComparison(int hours) async {
    try {
      final startDate = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('sms_delivery_log')
          .select('provider_used, delivery_status, sent_at, delivered_at')
          .gte('sent_at', startDate.toIso8601String());

      final logs = List<Map<String, dynamic>>.from(response);

      final telnyxLogs = logs
          .where((l) => l['provider_used'] == 'telnyx')
          .toList();
      final twilioLogs = logs
          .where((l) => l['provider_used'] == 'twilio')
          .toList();

      return {
        'telnyx': _calculateProviderMetrics(telnyxLogs),
        'twilio': _calculateProviderMetrics(twilioLogs),
      };
    } catch (e) {
      debugPrint('Load provider comparison error: $e');
      return {};
    }
  }

  Map<String, dynamic> _calculateProviderMetrics(
    List<Map<String, dynamic>> logs,
  ) {
    final totalSent = logs.length;
    final delivered = logs
        .where((l) => l['delivery_status'] == 'delivered')
        .length;
    final failed = logs.where((l) => l['delivery_status'] == 'failed').length;
    final bounced = logs.where((l) => l['delivery_status'] == 'bounced').length;

    final deliveryRate = totalSent > 0 ? (delivered / totalSent * 100) : 0.0;

    // Calculate average latency
    final deliveredLogs = logs.where(
      (l) =>
          l['delivery_status'] == 'delivered' &&
          l['sent_at'] != null &&
          l['delivered_at'] != null,
    );

    int totalLatency = 0;
    for (final log in deliveredLogs) {
      final sentAt = DateTime.parse(log['sent_at'] as String);
      final deliveredAt = DateTime.parse(log['delivered_at'] as String);
      totalLatency += deliveredAt.difference(sentAt).inMilliseconds;
    }

    final avgLatency = deliveredLogs.isNotEmpty
        ? totalLatency ~/ deliveredLogs.length
        : 0;

    return {
      'sent': totalSent,
      'delivered': delivered,
      'failed': failed,
      'bounced': bounced,
      'delivery_rate': deliveryRate,
      'avg_latency_ms': avgLatency,
    };
  }

  Future<List<Map<String, dynamic>>> _loadDeliveryPerformance(int hours) async {
    try {
      final startDate = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('sms_delivery_log')
          .select('provider_used, delivery_status, sent_at')
          .gte('sent_at', startDate.toIso8601String())
          .order('sent_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load delivery performance error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadBounceAnalysis() async {
    try {
      final response = await _supabase
          .from('sms_bounce_list')
          .select()
          .order('bounce_count', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load bounce analysis error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadFailoverHistory(int hours) async {
    try {
      final startDate = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('provider_failover_log')
          .select()
          .gte('failed_at', startDate.toIso8601String())
          .order('failed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load failover history error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _loadLatencyMetrics(int hours) async {
    try {
      final startDate = DateTime.now().subtract(Duration(hours: hours));

      final response = await _supabase
          .from('sms_delivery_log')
          .select('provider_used, sent_at, delivered_at')
          .eq('delivery_status', 'delivered')
          .gte('sent_at', startDate.toIso8601String());

      final logs = List<Map<String, dynamic>>.from(response);

      final latencies = <int>[];
      for (final log in logs) {
        if (log['sent_at'] != null && log['delivered_at'] != null) {
          final sentAt = DateTime.parse(log['sent_at'] as String);
          final deliveredAt = DateTime.parse(log['delivered_at'] as String);
          latencies.add(deliveredAt.difference(sentAt).inMilliseconds);
        }
      }

      if (latencies.isEmpty) {
        return {'p50': 0, 'p95': 0, 'p99': 0};
      }

      latencies.sort();
      final p50Index = (latencies.length * 0.5).floor();
      final p95Index = (latencies.length * 0.95).floor();
      final p99Index = (latencies.length * 0.99).floor();

      return {
        'p50': latencies[p50Index],
        'p95': latencies[p95Index],
        'p99': latencies[p99Index],
        'distribution': _calculateLatencyDistribution(latencies),
      };
    } catch (e) {
      debugPrint('Load latency metrics error: $e');
      return {};
    }
  }

  Map<String, int> _calculateLatencyDistribution(List<int> latencies) {
    final distribution = {'0-5s': 0, '5-10s': 0, '10-30s': 0, '>30s': 0};

    for (final latency in latencies) {
      final seconds = latency / 1000;
      if (seconds <= 5) {
        distribution['0-5s'] = distribution['0-5s']! + 1;
      } else if (seconds <= 10) {
        distribution['5-10s'] = distribution['5-10s']! + 1;
      } else if (seconds <= 30) {
        distribution['10-30s'] = distribution['10-30s']! + 1;
      } else {
        distribution['>30s'] = distribution['>30s']! + 1;
      }
    }

    return distribution;
  }

  void _subscribeToRealtimeUpdates() {
    _realtimeSubscription = _supabase
        .from('sms_delivery_log')
        .stream(primaryKey: ['delivery_id'])
        .listen((data) {
          if (mounted) {
            _loadAnalytics();
          }
        });
  }

  Future<void> _exportToCSV() async {
    try {
      final rows = <List<dynamic>>[
        [
          'Provider',
          'Sent',
          'Delivered',
          'Failed',
          'Bounced',
          'Delivery Rate',
          'Avg Latency (ms)',
        ],
      ];

      if (_providerComparison.containsKey('telnyx')) {
        final telnyx = _providerComparison['telnyx'] as Map<String, dynamic>;
        rows.add([
          'Telnyx',
          telnyx['sent'],
          telnyx['delivered'],
          telnyx['failed'],
          telnyx['bounced'],
          '${telnyx['delivery_rate'].toStringAsFixed(2)}%',
          telnyx['avg_latency_ms'],
        ]);
      }

      if (_providerComparison.containsKey('twilio')) {
        final twilio = _providerComparison['twilio'] as Map<String, dynamic>;
        rows.add([
          'Twilio',
          twilio['sent'],
          twilio['delivered'],
          twilio['failed'],
          twilio['bounced'],
          '${twilio['delivery_rate'].toStringAsFixed(2)}%',
          twilio['avg_latency_ms'],
        ]);
      }

      final csv = ListToCsvConverter().convert(rows);
      debugPrint('CSV Export:\n$csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV export generated (check console)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('CSV export error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CustomAppBar(
        title: 'SMS Delivery Analytics',
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToCSV,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTimeRangeSelector(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildProviderComparisonTab(),
                      _buildBounceAnalysisTab(),
                      _buildFailoverHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          Text(
            'Time Range:',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['1h', '6h', '24h', '7d', '30d']
                    .map(
                      (range) => Padding(
                        padding: EdgeInsets.only(right: 2.w),
                        child: ChoiceChip(
                          label: Text(range),
                          selected: _selectedTimeRange == range,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedTimeRange = range);
                              _loadAnalytics();
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceDark,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondaryDark,
        indicatorColor: AppTheme.primaryColor,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Providers'),
          Tab(text: 'Bounces'),
          Tab(text: 'Failovers'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeliveryMetricsOverviewWidget(metrics: _overviewMetrics),
            SizedBox(height: 3.h),
            DeliveryPerformanceChartWidget(
              performanceData: _deliveryPerformance,
            ),
            SizedBox(height: 3.h),
            LatencyAnalysisWidget(latencyMetrics: _latencyMetrics),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderComparisonTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: ProviderComparisonWidget(
          providerComparison: _providerComparison,
        ),
      ),
    );
  }

  Widget _buildBounceAnalysisTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: BounceAnalysisWidget(bounceData: _bounceAnalysis),
      ),
    );
  }

  Widget _buildFailoverHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: FailoverHistoryWidget(failoverHistory: _failoverHistory),
      ),
    );
  }
}
