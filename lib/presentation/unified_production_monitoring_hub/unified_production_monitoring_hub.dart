import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/ad_slot_metrics_panel_widget.dart';
import './widgets/alert_card_widget.dart';
import './widgets/datadog_apm_panel_widget.dart';
import './widgets/performance_profiling_panel_widget.dart';
import './widgets/quick_metrics_grid_widget.dart';
import './widgets/system_health_card_widget.dart';

class UnifiedProductionMonitoringHub extends StatefulWidget {
  const UnifiedProductionMonitoringHub({super.key});

  @override
  State<UnifiedProductionMonitoringHub> createState() =>
      _UnifiedProductionMonitoringHubState();
}

class _UnifiedProductionMonitoringHubState
    extends State<UnifiedProductionMonitoringHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  Timer? _pollingTimer;
  RealtimeChannel? _alertsChannel;

  // State
  bool _isLoading = true;
  String _overallStatus = 'healthy';
  final double _uptimePercentage = 99.95;
  int _activeIncidents = 0;
  int _compositeScore = 92;
  final double _apiLatencyP95 = 87.0;
  final int _dbConnectionsCurrent = 45;
  final int _dbConnectionsMax = 100;
  final double _cacheHitRate = 87.0;
  double _adFillRate = 73.0;
  final double _errorRate = 0.3;
  final int _activeRequests = 142;
  List<Map<String, dynamic>> _latencyData = [];
  List<Map<String, dynamic>> _screenMetrics = [];
  List<Map<String, dynamic>> _slotMetrics = [];
  List<Map<String, dynamic>> _alerts = [];
  String _alertSeverityFilter = 'all';
  final double _totalRevenueToday = 1247.50;
  final double _trendVsYesterday = 8.3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
    _startPolling();
    _subscribeToAlerts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollingTimer?.cancel();
    _alertsChannel?.unsubscribe();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadAllData();
    });
  }

  void _subscribeToAlerts() {
    _alertsChannel = _supabase
        .channel('unified_alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'unified_alerts',
          callback: (payload) {
            _loadAlerts();
            final newAlert = payload.newRecord;
            if (newAlert['severity'] == 'critical' && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'CRITICAL: ${newAlert['message'] ?? 'New alert'}',
                          style: GoogleFonts.inter(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFEF4444),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDatadogMetrics(),
      _loadPerformanceProfiling(),
      _loadAdMetrics(),
      _loadAlerts(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadDatadogMetrics() async {
    try {
      // Use mock metrics since DatadogTracingService doesn't expose query metrics directly
      if (mounted) {
        setState(() {
          _latencyData = _generateLatencyData();
          _compositeScore = _calculateCompositeScore();
          _overallStatus = _compositeScore >= 80
              ? 'healthy'
              : _compositeScore >= 60
              ? 'degraded'
              : 'critical';
        });
      }
    } catch (_) {
      _latencyData = _generateLatencyData();
    }
  }

  Future<void> _loadPerformanceProfiling() async {
    try {
      final data = await _supabase
          .from('performance_profiling_results')
          .select(
            'screen_name, load_time_ms, memory_usage_mb, fps, battery_drain_rate',
          )
          .gte(
            'profiled_at',
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          )
          .order('load_time_ms', ascending: false)
          .limit(10);

      // Aggregate by screen
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in (data as List)) {
        final name = row['screen_name'] as String? ?? 'Unknown';
        grouped.putIfAbsent(name, () => []).add(row as Map<String, dynamic>);
      }

      final aggregated = grouped.entries.map((e) {
        final rows = e.value;
        final avgLoad =
            rows
                .map((r) => (r['load_time_ms'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            rows.length;
        final avgMemory =
            rows
                .map((r) => (r['memory_usage_mb'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            rows.length;
        final minFps = rows
            .map((r) => (r['fps'] as num?)?.toDouble() ?? 60)
            .reduce((a, b) => a < b ? a : b);
        return {
          'screen_name': e.key,
          'avg_load': avgLoad,
          'avg_memory': avgMemory,
          'min_fps': minFps,
        };
      }).toList();

      if (mounted) setState(() => _screenMetrics = aggregated);
    } catch (_) {
      if (mounted) setState(() => _screenMetrics = _mockScreenMetrics());
    }
  }

  Future<void> _loadAdMetrics() async {
    try {
      final impressions = await _supabase
          .from('ad_impressions')
          .select('slot_id, count')
          .limit(20);
      final clicks = await _supabase
          .from('ad_clicks')
          .select('slot_id, count')
          .limit(20);

      final slotMap = <String, Map<String, dynamic>>{};
      for (final imp in (impressions as List)) {
        final slotId = imp['slot_id'] as String? ?? '';
        slotMap[slotId] = {
          'slot_id': slotId,
          'impressions': imp['count'] ?? 0,
          'clicks': 0,
          'fill_rate': 0.0,
          'revenue': 0.0,
        };
      }
      for (final click in (clicks as List)) {
        final slotId = click['slot_id'] as String? ?? '';
        if (slotMap.containsKey(slotId)) {
          final imp = slotMap[slotId]!['impressions'] as int;
          final clk = click['count'] as int? ?? 0;
          slotMap[slotId]!['clicks'] = clk;
          slotMap[slotId]!['fill_rate'] = imp > 0 ? (clk / imp * 100) : 0.0;
          slotMap[slotId]!['revenue'] = clk * 0.15;
        }
      }

      if (mounted) {
        setState(() {
          _slotMetrics = slotMap.values.toList();
          if (_slotMetrics.isNotEmpty) {
            _adFillRate =
                _slotMetrics
                    .map((s) => (s['fill_rate'] as num?)?.toDouble() ?? 0)
                    .reduce((a, b) => a + b) /
                _slotMetrics.length;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _slotMetrics = _mockSlotMetrics());
    }
  }

  Future<void> _loadAlerts() async {
    try {
      var query = _supabase
          .from('unified_alerts')
          .select()
          .eq('resolved', false)
          .order('created_at', ascending: false)
          .limit(50);

      final data = await query;
      if (mounted) {
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(data as List);
          _activeIncidents = _alerts
              .where((a) => (a['severity'] as String? ?? '') == 'critical')
              .length;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _alerts = _mockAlerts());
    }
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      await _supabase
          .from('unified_alerts')
          .update({'acknowledged': true})
          .eq('alert_id', alertId);
      _loadAlerts();
    } catch (_) {}
  }

  Future<void> _escalateAlert(Map<String, dynamic> alert) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alert escalated: ${alert['message'] ?? ''}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFF97316),
        ),
      );
    }
  }

  int _calculateCompositeScore() {
    int score = 100;
    if (_apiLatencyP95 > 100) score -= 15;
    if (_errorRate > 0.5) score -= 20;
    if (_dbConnectionsCurrent > _dbConnectionsMax * 0.8) score -= 10;
    if (_cacheHitRate < 80) score -= 10;
    if (_adFillRate < 70) score -= 5;
    return score.clamp(0, 100);
  }

  List<Map<String, dynamic>> _generateLatencyData() {
    return List.generate(
      20,
      (i) => {
        'p50': 30.0 + (i % 5) * 5,
        'p95': 80.0 + (i % 7) * 8,
        'p99': 150.0 + (i % 9) * 12,
      },
    );
  }

  List<Map<String, dynamic>> _mockScreenMetrics() {
    return [
      {
        'screen_name': 'Home',
        'avg_load': 1200.0,
        'avg_memory': 32.0,
        'min_fps': 58.0,
      },
      {
        'screen_name': 'Vote',
        'avg_load': 2800.0,
        'avg_memory': 48.0,
        'min_fps': 52.0,
      },
      {
        'screen_name': 'Profile',
        'avg_load': 1800.0,
        'avg_memory': 28.0,
        'min_fps': 60.0,
      },
      {
        'screen_name': 'Analytics',
        'avg_load': 4200.0,
        'avg_memory': 65.0,
        'min_fps': 42.0,
      },
      {
        'screen_name': 'Wallet',
        'avg_load': 1500.0,
        'avg_memory': 22.0,
        'min_fps': 60.0,
      },
    ];
  }

  List<Map<String, dynamic>> _mockSlotMetrics() {
    return [
      {
        'slot_id': 'home_feed_1',
        'impressions': 1240,
        'clicks': 93,
        'fill_rate': 75.0,
        'revenue': 13.95,
      },
      {
        'slot_id': 'home_feed_2',
        'impressions': 980,
        'clicks': 68,
        'fill_rate': 69.4,
        'revenue': 10.20,
      },
      {
        'slot_id': 'profile_top',
        'impressions': 560,
        'clicks': 42,
        'fill_rate': 75.0,
        'revenue': 6.30,
      },
      {
        'slot_id': 'election_detail',
        'impressions': 820,
        'clicks': 57,
        'fill_rate': 69.5,
        'revenue': 8.55,
      },
    ];
  }

  List<Map<String, dynamic>> _mockAlerts() {
    return [
      {
        'alert_id': '1',
        'source': 'datadog',
        'severity': 'high',
        'message': 'API latency p95 exceeded 200ms threshold',
        'affected_component': 'api-gateway',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        'acknowledged': false,
        'resolved': false,
      },
      {
        'alert_id': '2',
        'source': 'supabase',
        'severity': 'medium',
        'message': 'Connection pool utilization at 78%',
        'affected_component': 'database',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 12))
            .toIso8601String(),
        'acknowledged': false,
        'resolved': false,
      },
      {
        'alert_id': '3',
        'source': 'performance',
        'severity': 'low',
        'message': 'Analytics screen load time increased to 4.2s',
        'affected_component': 'analytics-screen',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 25))
            .toIso8601String(),
        'acknowledged': true,
        'resolved': false,
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    if (_alertSeverityFilter == 'all') return _alerts;
    return _alerts.where((a) => a['severity'] == _alertSeverityFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CustomAppBar(
        title: 'Production Monitoring Hub',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelStyle: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 10.sp),
              labelColor: const Color(0xFF7C3AED),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF7C3AED),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Infrastructure'),
                Tab(text: 'Application'),
                Tab(text: 'Business'),
                Tab(text: 'Alerts'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildInfrastructureTab(),
                      _buildApplicationTab(),
                      _buildBusinessTab(),
                      _buildAlertsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SystemHealthCardWidget(
            overallStatus: _overallStatus,
            uptimePercentage: _uptimePercentage,
            activeIncidents: _activeIncidents,
            compositeScore: _compositeScore,
          ),
          SizedBox(height: 2.h),
          Text(
            'Quick Metrics',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 1.h),
          QuickMetricsGridWidget(
            apiLatencyP95: _apiLatencyP95,
            dbConnectionsCurrent: _dbConnectionsCurrent,
            dbConnectionsMax: _dbConnectionsMax,
            cacheHitRate: _cacheHitRate,
            adFillRate: _adFillRate,
          ),
          SizedBox(height: 2.h),
          Text(
            'Recent Alerts',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 1.h),
          ..._alerts
              .take(3)
              .map(
                (alert) => AlertCardWidget(
                  alert: alert,
                  onAcknowledge: () =>
                      _acknowledgeAlert(alert['alert_id'] as String? ?? ''),
                  onEscalate: () => _escalateAlert(alert),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          DatadogApmPanelWidget(
            latencyData: _latencyData,
            errorRate: _errorRate,
            activeRequests: _activeRequests,
          ),
          SizedBox(height: 2.h),
          _buildSupabaseHealthPanel(),
        ],
      ),
    );
  }

  Widget _buildSupabaseHealthPanel() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: const Color(0xFF10B981), size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Supabase Health',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildConnectionPoolGauge(),
          SizedBox(height: 2.h),
          Text(
            'Slow Queries',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: 1.h),
          _buildSlowQueriesTable(),
        ],
      ),
    );
  }

  Widget _buildConnectionPoolGauge() {
    final utilization = _dbConnectionsCurrent / _dbConnectionsMax;
    final color = utilization < 0.7
        ? const Color(0xFF22C55E)
        : utilization < 0.9
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Connection Pool',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF374151),
              ),
            ),
            Text(
              '$_dbConnectionsCurrent / $_dbConnectionsMax',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: utilization,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.h,
          ),
        ),
      ],
    );
  }

  Widget _buildSlowQueriesTable() {
    final mockQueries = [
      {
        'query': 'SELECT * FROM elections WHERE...',
        'time': '245ms',
        'rec': 'Add index on created_at',
      },
      {
        'query': 'SELECT * FROM user_vp_transactions...',
        'time': '189ms',
        'rec': 'Use pagination',
      },
      {
        'query': 'SELECT COUNT(*) FROM ad_impressions...',
        'time': '312ms',
        'rec': 'Materialize view',
      },
    ];
    return Column(
      children: mockQueries
          .map(
            (q) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          q['query']!,
                          style: GoogleFonts.robotoMono(
                            fontSize: 9.sp,
                            color: const Color(0xFF374151),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        q['time']!,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    '💡 ${q['rec']}',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildApplicationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: PerformanceProfilingPanelWidget(screenMetrics: _screenMetrics),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: AdSlotMetricsPanelWidget(
        slotMetrics: _slotMetrics,
        totalRevenueToday: _totalRevenueToday,
        trendVsYesterday: _trendVsYesterday,
      ),
    );
  }

  Widget _buildAlertsTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['all', 'critical', 'high', 'medium', 'low'].map((
                severity,
              ) {
                final isSelected = _alertSeverityFilter == severity;
                return GestureDetector(
                  onTap: () => setState(() => _alertSeverityFilter = severity),
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _filteredAlerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 12.w,
                        color: const Color(0xFF22C55E),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'No alerts',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = _filteredAlerts[index];
                    return AlertCardWidget(
                      alert: alert,
                      onAcknowledge: () =>
                          _acknowledgeAlert(alert['alert_id'] as String? ?? ''),
                      onEscalate: () => _escalateAlert(alert),
                    );
                  },
                ),
        ),
      ],
    );
  }
}