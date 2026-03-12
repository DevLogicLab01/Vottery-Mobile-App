import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/datadog_tracing_service.dart';
import '../../widgets/error_boundary_wrapper.dart';

class DatadogApmPerformanceMonitoringHub extends StatefulWidget {
  const DatadogApmPerformanceMonitoringHub({super.key});

  @override
  State<DatadogApmPerformanceMonitoringHub> createState() =>
      _DatadogApmPerformanceMonitoringHubState();
}

class _DatadogApmPerformanceMonitoringHubState
    extends State<DatadogApmPerformanceMonitoringHub> {
  final DatadogTracingService _tracingService = DatadogTracingService.instance;
  bool _isLoading = true;
  Map<String, dynamic> _perplexityMetrics = {};
  Map<String, dynamic> _claudeMetrics = {};
  Map<String, dynamic> _consensusMetrics = {};
  List<Map<String, dynamic>> _regressions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        Future.value({
          'avg_latency_ms': 0,
          'p95_latency_ms': 0,
          'error_rate': 0,
          'total_requests': 0,
        }),
        Future.value({
          'avg_latency_ms': 0,
          'p95_latency_ms': 0,
          'error_rate': 0,
          'total_requests': 0,
        }),
        Future.value({
          'avg_latency_ms': 0,
          'p95_latency_ms': 0,
          'error_rate': 0,
          'total_requests': 0,
        }),
        Future.value(<Map<String, dynamic>>[]),
      ]);

      setState(() {
        _perplexityMetrics = results[0] as Map<String, dynamic>;
        _claudeMetrics = results[1] as Map<String, dynamic>;
        _consensusMetrics = results[2] as Map<String, dynamic>;
        _regressions = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'DatadogApmPerformanceMonitoringHub',
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
                'Datadog APM Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'AI Operations Performance',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading ? _buildLoadingState() : _buildContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: 3,
      itemBuilder: (context, index) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          height: 20.h,
          width: double.infinity,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          _buildMetricsCard(
            'Perplexity API Performance',
            _perplexityMetrics,
            Icons.search,
            Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildMetricsCard(
            'Claude Rule Generation',
            _claudeMetrics,
            Icons.security,
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          _buildMetricsCard(
            'Multi-AI Consensus Scoring',
            _consensusMetrics,
            Icons.group_work,
            Colors.green,
          ),
          SizedBox(height: 2.h),
          if (_regressions.isNotEmpty) _buildRegressionsSection(),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(
    String title,
    Map<String, dynamic> metrics,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                  child: Icon(icon, color: color, size: 6.w),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Avg Latency',
                    '${metrics['avg_latency_ms']} ms',
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'P95',
                    '${metrics['p95_latency_ms']} ms',
                    Icons.show_chart,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Error Rate',
                    '${metrics['error_rate']}%',
                    Icons.error_outline,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Requests',
                    '${metrics['total_requests']}',
                    Icons.api,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16.0, color: Colors.grey[600]),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildRegressionsSection() {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 6.w),
                SizedBox(width: 2.w),
                Text(
                  'Performance Regressions Detected',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ..._regressions.map(
              (r) => Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  '${r['operation_type']}: ${r['current_p95']}ms (${r['exceeded_by']}% over threshold)',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
