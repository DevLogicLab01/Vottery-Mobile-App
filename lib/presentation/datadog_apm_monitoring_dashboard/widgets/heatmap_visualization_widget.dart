import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';
import '../../../services/claude_service.dart';

class HeatmapVisualizationWidget extends StatefulWidget {
  const HeatmapVisualizationWidget({super.key});

  @override
  State<HeatmapVisualizationWidget> createState() =>
      _HeatmapVisualizationWidgetState();
}

class _HeatmapVisualizationWidgetState
    extends State<HeatmapVisualizationWidget> {
  final _supabase = SupabaseService.instance.client;
  List<Map<String, dynamic>> _traceData = [];
  List<String> _systems = [];
  List<String> _operations = [];
  Map<String, int> _latencyMap = {};
  bool _isLoading = true;
  StreamSubscription? _realtimeSubscription;
  Timer? _refreshTimer;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Cache with 5-minute TTL
  DateTime? _lastFetch;
  static const _cacheTTL = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToRealtime();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_lastFetch == null ||
          DateTime.now().difference(_lastFetch!) > _cacheTTL) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _supabase
          .from('datadog_trace_metadata')
          .select(
            'operation_name, system_name, latency_ms, latency_p50, latency_p95, latency_p99, affected_users_estimate, operation_type, query_text',
          )
          .order('recorded_at', ascending: false)
          .limit(500);

      final Map<String, List<int>> latencyGroups = {};
      final systemSet = <String>{};
      final operationSet = <String>{};

      for (final row in data) {
        final key = '${row['operation_name']}|${row['system_name']}';
        latencyGroups.putIfAbsent(key, () => []).add(row['latency_ms'] as int);
        systemSet.add(row['system_name'] as String);
        operationSet.add(row['operation_name'] as String);
      }

      final Map<String, int> avgLatency = {};
      latencyGroups.forEach((key, values) {
        avgLatency[key] = values.reduce((a, b) => a + b) ~/ values.length;
      });

      if (mounted) {
        setState(() {
          _traceData = List<Map<String, dynamic>>.from(data);
          _systems = systemSet.toList()..sort();
          _operations = operationSet.toList()..sort();
          _latencyMap = avgLatency;
          _isLoading = false;
          _lastFetch = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Heatmap load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToRealtime() {
    try {
      _realtimeSubscription = _supabase
          .from('datadog_trace_metadata')
          .stream(primaryKey: ['trace_id'])
          .order('recorded_at', ascending: false)
          .limit(10)
          .listen((data) {
            if (mounted && data.isNotEmpty) {
              // Incremental update
              for (final row in data) {
                final key = '${row['operation_name']}|${row['system_name']}';
                _latencyMap[key] = row['latency_ms'] as int;
              }
              setState(() {});
            }
          });
    } catch (e) {
      debugPrint('Realtime subscription error: $e');
    }
  }

  Color _latencyColor(int latencyMs) {
    if (latencyMs > 1000) return const Color(0xFFE53935); // Red
    if (latencyMs > 500) return const Color(0xFFFF6F00); // Orange
    if (latencyMs > 200) return const Color(0xFFFFD600); // Yellow
    return const Color(0xFF43A047); // Green
  }

  void _onCellTap(String operation, String system) {
    final key = '$operation|$system';
    final latency = _latencyMap[key] ?? 0;
    final traceRow = _traceData.firstWhere(
      (r) => r['operation_name'] == operation && r['system_name'] == system,
      orElse: () => {},
    );
    showDialog(
      context: context,
      builder: (_) => BottleneckDetailDialog(
        operationName: operation,
        systemName: system,
        latencyMs: latency,
        traceData: traceRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bottleneck Heatmap',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _buildLegendDot(const Color(0xFF43A047), '<200ms'),
                      _buildLegendDot(const Color(0xFFFFD600), '<500ms'),
                      _buildLegendDot(const Color(0xFFFF6F00), '<1000ms'),
                      _buildLegendDot(const Color(0xFFE53935), '>1000ms'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              // Zoom controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () =>
                        setState(() => _scale = min(_scale + 0.2, 3.0)),
                    tooltip: 'Zoom In',
                  ),
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: () =>
                        setState(() => _scale = max(_scale - 0.2, 0.5)),
                    tooltip: 'Zoom Out',
                  ),
                  IconButton(
                    icon: const Icon(Icons.center_focus_strong),
                    onPressed: () => setState(() {
                      _scale = 1.0;
                      _offset = Offset.zero;
                    }),
                    tooltip: 'Reset',
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _systems.isEmpty
                  ? const Center(child: Text('No trace data available'))
                  : _buildHeatmapGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.5, 3.0);
          _offset += details.focalPointDelta;
        });
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Transform(
            transform: Matrix4.identity()
              ..scale(_scale)
              ..translate(_offset.dx / _scale, _offset.dy / _scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with system names
                Row(
                  children: [
                    SizedBox(width: 30.w),
                    ..._systems.map(
                      (sys) => Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          sys.length > 10 ? sys.substring(0, 10) : sys,
                          style: TextStyle(
                            fontSize: 10.sp,
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
                // Data rows
                ..._operations.map((op) => _buildRow(op)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String operation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              operation,
              style: TextStyle(fontSize: 10.sp),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ..._systems.map((sys) {
            final key = '$operation|$sys';
            final latency = _latencyMap[key];
            return GestureDetector(
              onTap: latency != null ? () => _onCellTap(operation, sys) : null,
              child: Container(
                width: 80,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: latency != null
                      ? _latencyColor(latency)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    latency != null ? '${latency}ms' : '-',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: latency != null ? Colors.white : Colors.grey,
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
  }
}

// ============================================================
// BOTTLENECK DETAIL DIALOG
// ============================================================

class BottleneckDetailDialog extends StatefulWidget {
  final String operationName;
  final String systemName;
  final int latencyMs;
  final Map<String, dynamic> traceData;

  const BottleneckDetailDialog({
    super.key,
    required this.operationName,
    required this.systemName,
    required this.latencyMs,
    required this.traceData,
  });

  @override
  State<BottleneckDetailDialog> createState() => _BottleneckDetailDialogState();
}

class _BottleneckDetailDialogState extends State<BottleneckDetailDialog> {
  final _claudeService = ClaudeService.instance;
  String _aiSuggestions = '';
  bool _loadingAI = false;

  @override
  void initState() {
    super.initState();
    _loadAISuggestions();
  }

  Future<void> _loadAISuggestions() async {
    setState(() => _loadingAI = true);
    try {
      final p95 = widget.traceData['latency_p95'] ?? widget.latencyMs;
      final response = await _claudeService.callClaudeAPI(
        'Analyze this bottleneck: ${widget.operationName} latency ${p95}ms on ${widget.systemName}. Suggest 3 specific optimizations.',
      );
      if (mounted) setState(() => _aiSuggestions = response);
    } catch (e) {
      if (mounted) setState(() => _aiSuggestions = 'AI analysis unavailable');
    } finally {
      if (mounted) setState(() => _loadingAI = false);
    }
  }

  Color _latencyColor(int ms) {
    if (ms > 1000) return Colors.red;
    if (ms > 500) return Colors.orange;
    if (ms > 200) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final p50 =
        widget.traceData['latency_p50'] ?? (widget.latencyMs * 0.6).toInt();
    final p95 =
        widget.traceData['latency_p95'] ?? (widget.latencyMs * 1.3).toInt();
    final p99 =
        widget.traceData['latency_p99'] ?? (widget.latencyMs * 1.8).toInt();
    final affectedUsers = widget.traceData['affected_users_estimate'] ?? 0;
    final isDbOp = widget.traceData['operation_type'] == 'database_query';
    final queryText = widget.traceData['query_text'] as String?;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h, maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: _latencyColor(widget.latencyMs),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.thermostat, color: Colors.white),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.operationName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.systemName,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affected users
                    _buildInfoRow('Affected Users', '$affectedUsers estimated'),
                    SizedBox(height: 2.h),
                    // Percentile gauges
                    Text(
                      'Latency Percentiles',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildPercentileGauge('P50', p50),
                    _buildPercentileGauge('P95', p95),
                    _buildPercentileGauge('P99', p99),
                    SizedBox(height: 2.h),
                    // Query details if DB operation
                    if (isDbOp && queryText != null) ...[
                      Text(
                        'Query Details',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          queryText,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (_) => QueryDrillDownModal(
                                    operationName: widget.operationName,
                                    systemName: widget.systemName,
                                    traceData: widget.traceData,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Drill Down'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                    ],
                    // AI Suggestions
                    Text(
                      'AI Optimization Suggestions',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _loadingAI
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _aiSuggestions.isEmpty
                                        ? 'Loading AI analysis...'
                                        : _aiSuggestions,
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                    SizedBox(height: 2.h),
                    // Flame graph button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening Flame Graph...'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.local_fire_department),
                        label: const Text('View Flame Graph'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPercentileGauge(String label, int ms) {
    final maxMs = 2000;
    final fraction = (ms / maxMs).clamp(0.0, 1.0);
    Color barColor;
    if (ms > 1000) {
      barColor = Colors.red;
    } else if (ms > 500)
      barColor = Colors.orange;
    else if (ms > 200)
      barColor = Colors.amber;
    else
      barColor = Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 8.w,
            child: Text(
              label,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 12,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '${ms}ms',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUERY DRILL DOWN MODAL
// ============================================================

class QueryDrillDownModal extends StatefulWidget {
  final String operationName;
  final String systemName;
  final Map<String, dynamic> traceData;

  const QueryDrillDownModal({
    super.key,
    required this.operationName,
    required this.systemName,
    required this.traceData,
  });

  @override
  State<QueryDrillDownModal> createState() => _QueryDrillDownModalState();
}

class _QueryDrillDownModalState extends State<QueryDrillDownModal>
    with SingleTickerProviderStateMixin {
  final _claudeService = ClaudeService.instance;
  final _supabase = SupabaseService.instance.client;
  late TabController _tabController;
  String _aiRecommendation = '';
  bool _loadingAI = false;
  List<Map<String, dynamic>> _similarQueries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAIRecommendation();
    _loadSimilarQueries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAIRecommendation() async {
    setState(() => _loadingAI = true);
    try {
      final queryText = widget.traceData['query_text'] ?? widget.operationName;
      final p95 = widget.traceData['latency_p95'] ?? 500;
      final response = await _claudeService.callClaudeAPI(
        'Analyze this database query: "$queryText" with P95 latency ${p95}ms. Suggest specific optimizations including index recommendations with CREATE INDEX statements.',
      );
      if (mounted) setState(() => _aiRecommendation = response);
    } catch (e) {
      if (mounted) {
        setState(() => _aiRecommendation = 'AI analysis unavailable');
      }
    } finally {
      if (mounted) setState(() => _loadingAI = false);
    }
  }

  Future<void> _loadSimilarQueries() async {
    try {
      final data = await _supabase
          .from('datadog_trace_metadata')
          .select()
          .eq('operation_type', 'database_query')
          .neq('operation_name', widget.operationName)
          .order('latency_ms', ascending: false)
          .limit(5);
      if (mounted) {
        setState(() => _similarQueries = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('Similar queries error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryText =
        widget.traceData['query_text'] as String? ??
        'SELECT * FROM ${widget.operationName}';
    final executionTime = widget.traceData['latency_ms'] ?? 0;
    final callCount = widget.traceData['call_count'] ?? 1;
    final affectedTables =
        (widget.traceData['affected_tables'] as List?)?.cast<String>() ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 85.h, maxWidth: 95.w),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storage, color: Colors.white),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Query Drill-Down: ${widget.operationName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1565C0),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Query'),
                Tab(text: 'Metrics'),
                Tab(text: 'Similar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Query tab
                  SingleChildScrollView(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Query Text',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            queryText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.sp,
                              color: const Color(0xFF4FC3F7),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        if (affectedTables.isNotEmpty) ...[
                          Text(
                            'Affected Tables',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Wrap(
                            spacing: 8,
                            children: affectedTables
                                .map(
                                  (t) => Chip(
                                    label: Text(t),
                                    backgroundColor: Colors.blue[50],
                                  ),
                                )
                                .toList(),
                          ),
                          SizedBox(height: 2.h),
                        ],
                        Text(
                          'AI Optimization',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        _loadingAI
                            ? const Center(child: CircularProgressIndicator())
                            : Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  _aiRecommendation.isEmpty
                                      ? 'Analyzing...'
                                      : _aiRecommendation,
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                      ],
                    ),
                  ),
                  // Metrics tab
                  SingleChildScrollView(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      children: [
                        _buildMetricCard(
                          'Avg Execution Time',
                          '${executionTime}ms',
                          Icons.timer,
                        ),
                        _buildMetricCard(
                          'Call Count',
                          '$callCount calls',
                          Icons.repeat,
                        ),
                        _buildMetricCard(
                          'Total Time',
                          '${(executionTime * callCount / 1000).toStringAsFixed(1)}s',
                          Icons.access_time,
                        ),
                        _buildMetricCard(
                          'P95 Latency',
                          '${widget.traceData['latency_p95'] ?? executionTime}ms',
                          Icons.speed,
                        ),
                        _buildMetricCard(
                          'P99 Latency',
                          '${widget.traceData['latency_p99'] ?? executionTime}ms',
                          Icons.warning_amber,
                        ),
                      ],
                    ),
                  ),
                  // Similar queries tab
                  _similarQueries.isEmpty
                      ? const Center(child: Text('No similar queries found'))
                      : ListView.builder(
                          padding: EdgeInsets.all(2.w),
                          itemCount: _similarQueries.length,
                          itemBuilder: (ctx, i) {
                            final q = _similarQueries[i];
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.storage,
                                  color: (q['latency_ms'] as int) > 500
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                title: Text(
                                  q['operation_name'] as String,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('${q['latency_ms']}ms avg'),
                                trailing: Text(q['system_name'] as String),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
