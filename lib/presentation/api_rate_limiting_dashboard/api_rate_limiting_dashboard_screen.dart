import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/api_rate_limiting_service.dart';
import '../../widgets/custom_app_bar.dart';

class ApiRateLimitingDashboardScreen extends StatefulWidget {
  const ApiRateLimitingDashboardScreen({super.key});

  @override
  State<ApiRateLimitingDashboardScreen> createState() =>
      _ApiRateLimitingDashboardScreenState();
}

class _ApiRateLimitingDashboardScreenState
    extends State<ApiRateLimitingDashboardScreen> {
  bool _loading = true;
  bool _refreshing = false;
  String _timeRange = '1h';
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _rateLimits = [];
  List<Map<String, dynamic>> _violations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiRateLimitingService.instance.getMetrics(),
        ApiRateLimitingService.instance.getAllRateLimits(),
        ApiRateLimitingService.instance.getViolations(_timeRange),
      ]);
      if (mounted) {
        setState(() {
          _metrics = results[0] as Map<String, dynamic>?;
          _rateLimits = results[1] as List<Map<String, dynamic>>;
          _violations = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _loadData();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'API Rate Limiting',
          variant: CustomAppBarVariant.withBack,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Real-time quota monitoring',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: _timeRange,
                              items: const [
                                DropdownMenuItem(value: '1h', child: Text('1 Hour')),
                                DropdownMenuItem(value: '24h', child: Text('24 Hours')),
                                DropdownMenuItem(value: '7d', child: Text('7 Days')),
                              ],
                              onChanged: (v) {
                                setState(() => _timeRange = v ?? '1h');
                                _loadData();
                              },
                            ),
                            IconButton(
                              icon: _refreshing
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh),
                              onPressed: _refreshing ? null : _refresh,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    if (_metrics != null) _buildMetricsGrid(),
                    SizedBox(height: 3.h),
                    Text(
                      'Endpoint Limits',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildRateLimitsList(),
                    SizedBox(height: 3.h),
                    Text(
                      'Recent Violations',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildViolationsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2.h,
      crossAxisSpacing: 2.w,
      childAspectRatio: 1.8,
      children: [
        _buildMetricCard(
          'Total Endpoints',
          '${_metrics!['totalEndpoints'] ?? 0}',
          Icons.api,
          Colors.blue,
        ),
        _buildMetricCard(
          'Throttled',
          '${_metrics!['throttledEndpoints'] ?? 0}',
          Icons.speed,
          Colors.orange,
        ),
        _buildMetricCard(
          'Violations',
          '${_metrics!['totalViolations'] ?? 0}',
          Icons.warning_amber,
          Colors.red,
        ),
        _buildMetricCard(
          'Quota Util %',
          '${_metrics!['avgQuotaUtilization'] ?? '0'}%',
          Icons.pie_chart,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateLimitsList() {
    if (_rateLimits.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'No rate limits configured',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _rateLimits.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = _rateLimits[i];
          return ListTile(
            title: Text(
              '${r['endpoint']} (${r['method']})',
              style: TextStyle(fontSize: 13.sp),
            ),
            subtitle: Text(
              '${r['quota_per_minute']}/min • Throttle: ${r['throttle_enabled'] == true ? 'On' : 'Off'}',
              style: TextStyle(fontSize: 11.sp),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViolationsList() {
    if (_violations.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'No violations in selected period',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _violations.length.clamp(0, 20),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final v = _violations[i];
          return ListTile(
            leading: Icon(
              v['blocked'] == true ? Icons.block : Icons.warning_amber,
              color: v['severity'] == 'high' ? Colors.red : Colors.orange,
              size: 20.sp,
            ),
            title: Text(
              '${v['endpoint']} (${v['method']})',
              style: TextStyle(fontSize: 13.sp),
            ),
            subtitle: Text(
              '${v['request_count']}/${v['quota_limit']} • ${v['violation_type']}',
              style: TextStyle(fontSize: 11.sp),
            ),
          );
        },
      ),
    );
  }
}
