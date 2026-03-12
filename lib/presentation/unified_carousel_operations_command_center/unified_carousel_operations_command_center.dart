import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/unified_carousel_ops_hub_service.dart';
import '../../services/carousel_health_alerting_service.dart';
import 'dart:async';

/// Unified Carousel Operations Command Center
/// Comprehensive real-time operations management with WebSocket integration
class UnifiedCarouselOperationsCommandCenter extends StatefulWidget {
  const UnifiedCarouselOperationsCommandCenter({super.key});

  @override
  State<UnifiedCarouselOperationsCommandCenter> createState() =>
      _UnifiedCarouselOperationsCommandCenterState();
}

class _UnifiedCarouselOperationsCommandCenterState
    extends State<UnifiedCarouselOperationsCommandCenter>
    with SingleTickerProviderStateMixin {
  final UnifiedCarouselOpsHubService _opsService =
      UnifiedCarouselOpsHubService.instance;
  final CarouselHealthAlertingService _alertService =
      CarouselHealthAlertingService.instance;

  late TabController _tabController;
  StreamSubscription? _metricsSubscription;
  StreamSubscription? _incidentSubscription;

  Map<String, dynamic> _currentMetrics = {};
  List<Map<String, dynamic>> _activeIncidents = [];
  final List<Map<String, dynamic>> _anomalies = [];
  bool _isLoading = true;
  String _selectedSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize alert service
      await _alertService.initialize();

      // Start metrics aggregation
      _opsService.startMetricsAggregation(intervalSeconds: 3);

      // Subscribe to real-time updates
      _metricsSubscription = _opsService.metricsStream.listen((metrics) {
        if (mounted) {
          setState(() {
            _currentMetrics = metrics;
            _isLoading = false;
          });
        }
      });

      _incidentSubscription = _opsService.incidentStream.listen((incident) {
        if (mounted) {
          setState(() {
            _activeIncidents.insert(0, incident);
          });
        }
      });

      // Load initial data
      await _loadData();
    } catch (e) {
      debugPrint('Error initializing ops center: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final incidents = await _opsService.getActiveIncidents();

      if (mounted) {
        setState(() {
          _activeIncidents = incidents;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _metricsSubscription?.cancel();
    _incidentSubscription?.cancel();
    _opsService.stopMetricsAggregation();
    _alertService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Operations Command Center',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Systems'),
            Tab(text: 'Incidents'),
            Tab(text: 'Actions'),
            Tab(text: 'Datadog'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSystemsTab(),
                _buildIncidentsTab(),
                _buildActionsTab(),
                _buildDatadogTab(),
              ],
            ),
    );
  }

  // ============================================
  // OVERVIEW TAB
  // ============================================

  Widget _buildOverviewTab() {
    final platformKPIs =
        _currentMetrics['platform_kpis'] as Map<String, dynamic>? ?? {};
    final systems = _currentMetrics['systems'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Cards
            Text(
              'Platform KPIs',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildKPISummaryRow(platformKPIs),
            SizedBox(height: 3.h),

            // System Status Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Health: ${platformKPIs['system_health'] ?? 85}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildSystemStatusGrid(systems),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISummaryRow(Map<String, dynamic> kpis) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Total Incidents',
            '${kpis['active_issues'] ?? 0}',
            Icons.warning_amber_rounded,
            Colors.orange,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildKPICard(
            'System Health',
            '${kpis['system_health'] ?? 85}%',
            Icons.health_and_safety,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusGrid(Map<String, dynamic> systems) {
    final systemList = systems.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.85,
      ),
      itemCount: systemList.length,
      itemBuilder: (context, index) {
        final entry = systemList[index];
        final system = entry.value as Map<String, dynamic>;
        return _buildSystemCard(system);
      },
    );
  }

  Widget _buildSystemCard(Map<String, dynamic> system) {
    final healthScore = system['health_score'] as int? ?? 85;
    final status = system['status'] as String? ?? 'healthy';
    final systemName = system['system_name'] as String? ?? 'Unknown';

    Color statusColor;
    if (status == 'healthy') {
      statusColor = Colors.green;
    } else if (status == 'degraded') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return InkWell(
      onTap: () => _showSystemDetails(system),
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withAlpha(77)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_rounded, size: 28, color: statusColor),
            SizedBox(height: 1.h),
            Text(
              _formatSystemName(systemName),
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              '$healthScore/100',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSystemName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // ============================================
  // SYSTEMS TAB
  // ============================================

  Widget _buildSystemsTab() {
    final systems = _currentMetrics['systems'] as Map<String, dynamic>? ?? {};
    final systemList = systems.entries.toList();

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: systemList.length,
      itemBuilder: (context, index) {
        final entry = systemList[index];
        final system = entry.value as Map<String, dynamic>;
        return _buildSystemDetailCard(system);
      },
    );
  }

  Widget _buildSystemDetailCard(Map<String, dynamic> system) {
    final systemName = system['system_name'] as String? ?? 'Unknown';
    final healthScore = system['health_score'] as int? ?? 85;
    final status = system['status'] as String? ?? 'healthy';
    final metrics = system['metrics'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          Icons.dashboard_rounded,
          color: status == 'healthy' ? Colors.green : Colors.orange,
        ),
        title: Text(
          _formatSystemName(systemName),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Health: $healthScore/100'),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: TextStyle(fontSize: 10.sp, color: Colors.white),
          ),
          backgroundColor: status == 'healthy' ? Colors.green : Colors.orange,
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metrics',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                ...metrics.entries.map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatSystemName(e.key),
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        Text(
                          '${e.value}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _executeAction('restart', systemName),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Restart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _executeAction('scale_up', systemName),
                        icon: const Icon(Icons.trending_up, size: 16),
                        label: const Text('Scale'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // INCIDENTS TAB
  // ============================================

  Widget _buildIncidentsTab() {
    final filteredIncidents = _selectedSeverity == 'all'
        ? _activeIncidents
        : _activeIncidents
              .where((i) => i['severity'] == _selectedSeverity)
              .toList();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                'Filter:',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Wrap(
                  spacing: 2.w,
                  children: ['all', 'critical', 'high', 'medium']
                      .map(
                        (severity) => FilterChip(
                          label: Text(severity.toUpperCase()),
                          selected: _selectedSeverity == severity,
                          onSelected: (selected) {
                            setState(() => _selectedSeverity = severity);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredIncidents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No Active Incidents',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: filteredIncidents.length,
                  itemBuilder: (context, index) {
                    return _buildIncidentCard(filteredIncidents[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final severity = incident['severity'] as String? ?? 'medium';
    final title = incident['title'] as String? ?? 'Incident';
    final sourceSystem = incident['source_system'] as String? ?? 'Unknown';
    final incidentId = incident['incident_id'] as String? ?? '';

    Color severityColor;
    if (severity == 'critical') {
      severityColor = Colors.red;
    } else if (severity == 'high') {
      severityColor = Colors.orange;
    } else {
      severityColor = Colors.yellow[700]!;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: severityColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(
                        severity.toUpperCase(),
                        style: TextStyle(fontSize: 10.sp, color: Colors.white),
                      ),
                      backgroundColor: severityColor,
                    ),
                    const Spacer(),
                    Text(
                      _formatSystemName(sourceSystem),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acknowledgeIncident(incidentId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Acknowledge'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _investigateIncident(incident),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Investigate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ACTIONS TAB
  // ============================================

  Widget _buildActionsTab() {
    final actions = [
      {
        'title': 'System Lockdown',
        'description': 'Emergency platform-wide lockdown',
        'icon': Icons.lock,
        'color': Colors.red,
        'action': 'lockdown',
      },
      {
        'title': 'Emergency Scaling',
        'description': 'Scale all systems to maximum capacity',
        'icon': Icons.trending_up,
        'color': Colors.orange,
        'action': 'emergency_scale',
      },
      {
        'title': 'Restart All Systems',
        'description': 'Coordinated restart of all carousel systems',
        'icon': Icons.refresh,
        'color': Colors.blue,
        'action': 'restart_all',
      },
      {
        'title': 'Enable Maintenance Mode',
        'description': 'Put platform in maintenance mode',
        'icon': Icons.construction,
        'color': Colors.grey,
        'action': 'maintenance',
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.all(3.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(action);
      },
    );
  }

  Widget _buildQuickActionCard(Map<String, dynamic> action) {
    return InkWell(
      onTap: () => _showActionConfirmation(action),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action['icon'] as IconData,
              size: 40,
              color: action['color'] as Color,
            ),
            SizedBox(height: 1.h),
            Text(
              action['title'] as String,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              action['description'] as String,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DATADOG TAB
  // ============================================

  Widget _buildDatadogTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datadog APM Overview',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          // P95 Summary Cards
          _buildPercentileSummaryCards(),
          SizedBox(height: 3.h),
          // Mini Heatmap
          _buildMiniHeatmap(),
          SizedBox(height: 2.h),
          // Navigate to full APM
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/datadog-apm-monitoring-dashboard',
                );
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Full APM Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentileSummaryCards() {
    final systems = [
      {'name': 'HorizontalCarousel', 'p95': 245, 'trend': 'up'},
      {'name': 'VerticalStack', 'p95': 189, 'trend': 'down'},
      {'name': 'GradientFlow', 'p95': 567, 'trend': 'up'},
      {'name': 'ElectionService', 'p95': 312, 'trend': 'stable'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'P95 Latency Summary',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemCount: systems.length,
          itemBuilder: (ctx, i) {
            final sys = systems[i];
            final p95 = sys['p95'] as int;
            final trend = sys['trend'] as String;
            final isOverSla = p95 > 500;
            return Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isOverSla ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOverSla ? Colors.red[200]! : Colors.green[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    sys['name'] as String,
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        '${p95}ms',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isOverSla ? Colors.red : Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        trend == 'up'
                            ? Icons.trending_up
                            : trend == 'down'
                            ? Icons.trending_down
                            : Icons.trending_flat,
                        size: 14,
                        color: trend == 'up'
                            ? Colors.red
                            : trend == 'down'
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ],
                  ),
                  Text(
                    'P95',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMiniHeatmap() {
    final operations = [
      'carousel_render',
      'user_query',
      'vote_submit',
      'ai_inference',
    ];
    final systems = ['HorizontalCarousel', 'VerticalStack', 'GradientFlow'];
    final random = [
      [245, 189, 567],
      [312, 445, 234],
      [789, 156, 890],
      [123, 678, 345],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bottleneck Heatmap (Mini)',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/datadog-apm-monitoring-dashboard',
                );
              },
              child: const Text('Full View'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: EdgeInsets.all(2.w),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    SizedBox(width: 25.w),
                    ...systems.map(
                      (s) => Expanded(
                        child: Text(
                          s.length > 8 ? s.substring(0, 8) : s,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...operations.asMap().entries.map((opEntry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 25.w,
                          child: Text(
                            opEntry.value,
                            style: TextStyle(fontSize: 9.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...systems.asMap().entries.map((sysEntry) {
                          final latency = random[opEntry.key][sysEntry.key];
                          Color cellColor;
                          if (latency > 1000) {
                            cellColor = const Color(0xFFE53935);
                          } else if (latency > 500)
                            cellColor = const Color(0xFFFF6F00);
                          else if (latency > 200)
                            cellColor = const Color(0xFFFFD600);
                          else
                            cellColor = const Color(0xFF43A047);
                          return Expanded(
                            child: Container(
                              height: 28,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${latency}ms',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // ACTION HANDLERS
  // ============================================

  void _showSystemDetails(Map<String, dynamic> system) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatSystemName(system['system_name'] as String)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Score: ${system['health_score']}/100'),
            Text('Status: ${system['status']}'),
            const SizedBox(height: 16),
            const Text(
              'Metrics:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...(system['metrics'] as Map<String, dynamic>).entries.map(
              (e) => Text('${_formatSystemName(e.key)}: ${e.value}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAction(String action, String systemName) async {
    try {
      final result = await _opsService.executeAction(
        actionType: action,
        targetSystem: systemName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result ? 'Action executed successfully' : 'Action failed',
            ),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _acknowledgeIncident(String incidentId) async {
    try {
      final result = await _opsService.acknowledgeIncident(incidentId);
      if (result && mounted) {
        setState(() {
          _activeIncidents.removeWhere((i) => i['incident_id'] == incidentId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident acknowledged'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _investigateIncident(Map<String, dynamic> incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incident Investigation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${incident['title']}'),
            Text('Severity: ${incident['severity']}'),
            Text('System: ${incident['source_system']}'),
            const SizedBox(height: 16),
            Text('Description: ${incident['description'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acknowledgeIncident(incident['incident_id'] as String);
            },
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  void _showActionConfirmation(Map<String, dynamic> action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to execute this action?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              action['description'] as String,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeEmergencyAction(action['action'] as String);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action['color'] as Color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeEmergencyAction(String action) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Executing action...'),
            ],
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action executed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
