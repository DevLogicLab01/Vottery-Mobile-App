import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import './heatmap_visualization_widget.dart';

class QueryAnalysisPanelWidget extends StatefulWidget {
  const QueryAnalysisPanelWidget({super.key});

  @override
  State<QueryAnalysisPanelWidget> createState() =>
      _QueryAnalysisPanelWidgetState();
}

class _QueryAnalysisPanelWidgetState extends State<QueryAnalysisPanelWidget> {
  final _supabase = SupabaseService.instance.client;
  List<Map<String, dynamic>> _slowQueries = [];
  bool _isLoading = true;
  final String _sortBy = 'latency';

  @override
  void initState() {
    super.initState();
    _loadSlowQueries();
  }

  Future<void> _loadSlowQueries() async {
    try {
      final data = await _supabase
          .from('datadog_trace_metadata')
          .select()
          .eq('operation_type', 'database_query')
          .order('latency_ms', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _slowQueries = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Slow queries error: $e');
      if (mounted) setState(() => _isLoading = false);
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
                    'Slow Query Analysis',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadSlowQueries,
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _slowQueries.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No slow queries detected'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _slowQueries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final q = _slowQueries[i];
                        final latency = q['latency_ms'] as int;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _latencyColor(latency).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${latency}ms',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _latencyColor(latency),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          title: Text(
                            q['operation_name'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${q['system_name']} • ${q['call_count'] ?? 1} calls',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => QueryDrillDownModal(
                                operationName: q['operation_name'] as String,
                                systemName: q['system_name'] as String,
                                traceData: q,
                              ),
                            );
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
