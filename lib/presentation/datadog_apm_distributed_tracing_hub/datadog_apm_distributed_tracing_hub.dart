import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/error_boundary_wrapper.dart';

class DatadogApmDistributedTracingHub extends StatefulWidget {
  const DatadogApmDistributedTracingHub({super.key});

  @override
  State<DatadogApmDistributedTracingHub> createState() =>
      _DatadogApmDistributedTracingHubState();
}

class _DatadogApmDistributedTracingHubState
    extends State<DatadogApmDistributedTracingHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Supabase Queries',
      'health': 'healthy',
      'p50': '45ms',
      'p95': '120ms',
      'p99': '280ms',
      'errorRate': '0.2%',
    },
    {
      'name': 'Stripe Payments',
      'health': 'healthy',
      'p50': '180ms',
      'p95': '450ms',
      'p99': '890ms',
      'errorRate': '0.5%',
    },
    {
      'name': 'AI Services',
      'health': 'warning',
      'p50': '1200ms',
      'p95': '3500ms',
      'p99': '8200ms',
      'errorRate': '1.2%',
    },
    {
      'name': 'Edge Functions',
      'health': 'healthy',
      'p50': '95ms',
      'p95': '220ms',
      'p99': '450ms',
      'errorRate': '0.3%',
    },
  ];

  final List<Map<String, dynamic>> _slowQueries = [
    {
      'query': 'SELECT * FROM elections WHERE...',
      'duration': '1250ms',
      'timestamp': '2 minutes ago',
      'severity': 'warning',
    },
    {
      'query': 'UPDATE user_profiles SET...',
      'duration': '1580ms',
      'timestamp': '15 minutes ago',
      'severity': 'critical',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'DatadogApmDistributedTracingHub',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF632CA6),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datadog APM Distributed Tracing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Production Monitoring & Performance',
                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Service Map'),
              Tab(text: 'Performance'),
              Tab(text: 'Traces'),
              Tab(text: 'Alerts'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildAPMStatusOverview(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildServiceMapTab(),
                        _buildPerformanceTab(),
                        _buildTracesTab(),
                        _buildAlertsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAPMStatusOverview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: const BoxDecoration(
        color: Color(0xFF632CA6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              'Service Health',
              '98.5%',
              Icons.health_and_safety,
              Colors.green,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatusCard(
              'Trace Volume',
              '1.2K/min',
              Icons.show_chart,
              Colors.blue,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatusCard(
              'Alerts',
              '3',
              Icons.warning_amber,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceMapTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Dependency Map',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildDependencyVisualization(),
          SizedBox(height: 2.h),
          Text(
            'Service Health',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          ..._services.map((service) => _buildServiceHealthCard(service)),
        ],
      ),
    );
  }

  Widget _buildDependencyVisualization() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDependencyNode('Flutter App', Colors.blue),
          SizedBox(height: 1.h),
          Icon(Icons.arrow_downward, color: Colors.grey[400]),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDependencyNode('Supabase', Colors.green),
              _buildDependencyNode('Stripe', Colors.purple),
              _buildDependencyNode('AI Services', Colors.orange),
            ],
          ),
          SizedBox(height: 1.h),
          Icon(Icons.arrow_downward, color: Colors.grey[400]),
          SizedBox(height: 1.h),
          _buildDependencyNode('Edge Functions', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildDependencyNode(String name, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildServiceHealthCard(Map<String, dynamic> service) {
    final healthColor = service['health'] == 'healthy'
        ? Colors.green
        : service['health'] == 'warning'
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
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
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(
                  color: healthColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  service['name'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: healthColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  service['health'],
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: healthColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricChip('P50: ${service['p50']}', Colors.blue),
              _buildMetricChip('P95: ${service['p95']}', Colors.orange),
              _buildMetricChip('P99: ${service['p99']}', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics Dashboard',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildPerformanceMetricsGrid(),
          SizedBox(height: 2.h),
          Text(
            'Slow Queries (>1000ms)',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          ..._slowQueries.map((query) => _buildSlowQueryCard(query)),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPerformanceMetricCard(
                'Avg Response Time',
                '245ms',
                Icons.speed,
                Colors.blue,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPerformanceMetricCard(
                'Throughput',
                '1.2K req/min',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: _buildPerformanceMetricCard(
                'Error Rate',
                '0.5%',
                Icons.error_outline,
                Colors.orange,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPerformanceMetricCard(
                'Apdex Score',
                '0.95',
                Icons.star_outline,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSlowQueryCard(Map<String, dynamic> query) {
    final severityColor = query['severity'] == 'critical'
        ? Colors.red
        : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: severityColor, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  query['query'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  query['duration'],
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: severityColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                query['timestamp'],
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTracesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distributed Trace Viewer',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildFlameGraphPlaceholder(),
          SizedBox(height: 2.h),
          Text(
            'Recent Traces',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          _buildTraceCard(
            'POST /api/elections/vote',
            '245ms',
            '8 spans',
            Colors.green,
          ),
          _buildTraceCard(
            'GET /api/user/profile',
            '89ms',
            '4 spans',
            Colors.green,
          ),
          _buildTraceCard(
            'POST /api/payments/create',
            '1250ms',
            '12 spans',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFlameGraphPlaceholder() {
    return Container(
      height: 30.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 40.sp, color: Colors.grey[400]),
            SizedBox(height: 1.h),
            Text(
              'Flame Graph Visualization',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            Text(
              'Touch-based exploration of trace spans',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraceCard(
    String operation,
    String duration,
    String spans,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 1.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(Icons.timer, size: 12.sp, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Icon(Icons.layers, size: 12.sp, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Text(
                      spans,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Alerts',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildAlertCard(
            'Slow Query Detection',
            'P95 latency > 2000ms for 5 minutes',
            'Platform team',
            Colors.orange,
          ),
          _buildAlertCard(
            'AI Service Degradation',
            'Error rate > 5% for 3 minutes',
            'On-call engineer',
            Colors.red,
          ),
          _buildAlertCard(
            'High Latency Alert',
            'P99 > 5000ms',
            'Performance team',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(
    String title,
    String description,
    String team,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: color, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.group, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                'Escalated to: $team',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
