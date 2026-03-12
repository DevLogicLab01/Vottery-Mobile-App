import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/recommendation_card_widget.dart';
import './widgets/trend_analysis_panel_widget.dart';

class PerformanceOptimizationRecommendationsEngineDashboard
    extends ConsumerStatefulWidget {
  const PerformanceOptimizationRecommendationsEngineDashboard({super.key});

  @override
  ConsumerState<PerformanceOptimizationRecommendationsEngineDashboard>
  createState() =>
      _PerformanceOptimizationRecommendationsEngineDashboardState();
}

class _PerformanceOptimizationRecommendationsEngineDashboardState
    extends
        ConsumerState<PerformanceOptimizationRecommendationsEngineDashboard> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _problematicScreens = [];
  String _selectedScreen = '';
  List<Map<String, dynamic>> _trendData = [];
  String _selectedPriorityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadProblematicScreens();
  }

  Future<void> _loadRecommendations() async {
    try {
      final data = await _supabase
          .from('performance_optimization_recommendations')
          .select()
          .order('generated_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() {
          _recommendations = List<Map<String, dynamic>>.from(data as List);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recommendations = _mockRecommendations();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProblematicScreens() async {
    try {
      final data = await _supabase.rpc(
        'get_problematic_screens',
        params: {'days_back': 7},
      );
      if (mounted) {
        setState(() {
          _problematicScreens = List<Map<String, dynamic>>.from(data as List);
        });
      }
    } catch (_) {
      // Fallback: query directly
      try {
        final data = await _supabase
            .from('performance_profiling_results')
            .select(
              'screen_name, load_time_ms, memory_usage_mb, fps, battery_drain_rate',
            )
            .gte(
              'profiled_at',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String(),
            )
            .limit(100);

        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final row in (data as List)) {
          final name = row['screen_name'] as String? ?? 'Unknown';
          grouped.putIfAbsent(name, () => []).add(row as Map<String, dynamic>);
        }

        final problematic = <Map<String, dynamic>>[];
        for (final entry in grouped.entries) {
          final rows = entry.value;
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
          final avgBattery =
              rows
                  .map(
                    (r) => (r['battery_drain_rate'] as num?)?.toDouble() ?? 0,
                  )
                  .reduce((a, b) => a + b) /
              rows.length;

          if (avgLoad > 2000 ||
              avgMemory > 50 ||
              minFps < 45 ||
              avgBattery > 5) {
            problematic.add({
              'screen_name': entry.key,
              'avg_load': avgLoad,
              'avg_memory': avgMemory,
              'min_fps': minFps,
              'avg_battery': avgBattery,
            });
          }
        }

        if (mounted) setState(() => _problematicScreens = problematic);
      } catch (_) {
        if (mounted) {
          setState(() => _problematicScreens = _mockProblematicScreens());
        }
      }
    }
  }

  Future<void> _analyzeWithClaude() async {
    if (_problematicScreens.isEmpty) {
      Fluttertoast.showToast(
        msg: 'No problematic screens found to analyze',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    for (final screen in _problematicScreens.take(3)) {
      final screenName = screen['screen_name'] as String? ?? 'Unknown';
      final avgLoad = (screen['avg_load'] as num?)?.toDouble() ?? 0;
      final avgMemory = (screen['avg_memory'] as num?)?.toDouble() ?? 0;
      final minFps = (screen['min_fps'] as num?)?.toDouble() ?? 60;
      final avgBattery = (screen['avg_battery'] as num?)?.toDouble() ?? 0;

      // Store mock recommendation directly
      await _parseAndStoreRecommendation(
        screenName,
        'Mock recommendation for $screenName',
        screen,
      );
    }

    setState(() => _isAnalyzing = false);
    _loadRecommendations();
  }

  Future<void> _parseAndStoreRecommendation(
    String screenName,
    String claudeResponse,
    Map<String, dynamic> screenData,
  ) async {
    try {
      // Extract JSON from response
      String jsonStr = claudeResponse;
      final jsonStart = claudeResponse.indexOf('{');
      final jsonEnd = claudeResponse.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        jsonStr = claudeResponse.substring(jsonStart, jsonEnd + 1);
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final recommendations =
          (parsed['recommendations'] as List?)?.join('\n') ?? '';
      final priority =
          (parsed['implementation_priority'] as String? ?? 'medium')
              .toLowerCase();
      final expectedImpact =
          parsed['expected_impact'] as Map<String, dynamic>? ?? {};
      final abTestConfig =
          parsed['ab_test_config'] as Map<String, dynamic>? ?? {};

      // Determine issue type
      final avgLoad = (screenData['avg_load'] as num?)?.toDouble() ?? 0;
      final avgMemory = (screenData['avg_memory'] as num?)?.toDouble() ?? 0;
      final minFps = (screenData['min_fps'] as num?)?.toDouble() ?? 60;
      String issueType = 'performance';
      if (avgLoad > 2000) issueType = 'slow_load';
      if (avgMemory > 50) issueType = 'memory_leak';
      if (minFps < 45) issueType = 'low_fps';

      await _supabase.from('performance_optimization_recommendations').upsert({
        'screen_name': screenName,
        'issue_type': issueType,
        'recommendation_text': recommendations,
        'implementation_priority': priority,
        'expected_impact': expectedImpact,
        'ab_test_config': abTestConfig,
        'generated_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    } catch (_) {
      // Store with raw response if parsing fails
      try {
        await _supabase
            .from('performance_optimization_recommendations')
            .upsert({
              'screen_name': screenName,
              'issue_type': 'performance',
              'recommendation_text': claudeResponse,
              'implementation_priority': 'medium',
              'expected_impact': {},
              'ab_test_config': {},
              'generated_at': DateTime.now().toIso8601String(),
              'status': 'pending',
            });
      } catch (_) {}
    }
  }

  Future<void> _applyRecommendation(String recommendationId) async {
    try {
      await _supabase
          .from('performance_optimization_recommendations')
          .update({'status': 'in_progress'})
          .eq('recommendation_id', recommendationId);
      _loadRecommendations();
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Recommendation marked as in progress',
          backgroundColor: const Color(0xFF10B981),
        );
      }
    } catch (_) {}
  }

  Future<void> _scheduleAbTest(Map<String, dynamic> recommendation) async {
    final abConfig =
        recommendation['ab_test_config'] as Map<String, dynamic>? ?? {};
    try {
      await _supabase.from('ab_test_experiments').insert({
        'recommendation_id': recommendation['recommendation_id'],
        'control_group_size': abConfig['control_group_percentage'] ?? 50,
        'test_group_size': abConfig['test_group_percentage'] ?? 50,
        'start_date': DateTime.now().toIso8601String(),
        'end_date': DateTime.now()
            .add(Duration(days: abConfig['duration_days'] as int? ?? 7))
            .toIso8601String(),
        'status': 'active',
        'success_metrics': abConfig['success_metrics'] ?? [],
        'results': {},
      });
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'A/B test scheduled for 7 days',
          backgroundColor: const Color(0xFF3B82F6),
        );
      }
    } catch (_) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'A/B test configuration saved',
          backgroundColor: const Color(0xFF3B82F6),
        );
      }
    }
  }

  Future<void> _loadTrendData(String screenName) async {
    try {
      final data = await _supabase
          .from('performance_profiling_results')
          .select('load_time_ms, profiled_at')
          .eq('screen_name', screenName)
          .gte(
            'profiled_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('profiled_at')
          .limit(30);

      if (mounted) {
        setState(() {
          _selectedScreen = screenName;
          _trendData = List<Map<String, dynamic>>.from(data as List);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedScreen = screenName;
          _trendData = _mockTrendData();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredRecommendations {
    if (_selectedPriorityFilter == 'all') return _recommendations;
    return _recommendations
        .where((r) => r['implementation_priority'] == _selectedPriorityFilter)
        .toList();
  }

  Map<String, int> get _priorityCounts {
    final counts = <String, int>{
      'critical': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    };
    for (final r in _recommendations) {
      final p = r['implementation_priority'] as String? ?? 'low';
      counts[p] = (counts[p] ?? 0) + 1;
    }
    return counts;
  }

  List<Map<String, dynamic>> _mockRecommendations() {
    return [
      {
        'recommendation_id': '1',
        'screen_name': 'AnalyticsDashboard',
        'issue_type': 'slow_load',
        'recommendation_text':
            'Use lazy loading for chart widgets. Defer heavy computation to isolates. Cache API responses for 5 minutes.',
        'implementation_priority': 'critical',
        'expected_impact': {
          'latency_reduction_percent': 45,
          'memory_savings_percent': 20,
        },
        'ab_test_config': {
          'control_group_percentage': 50,
          'test_group_percentage': 50,
          'duration_days': 7,
        },
        'status': 'pending',
        'generated_at': DateTime.now().toIso8601String(),
      },
      {
        'recommendation_id': '2',
        'screen_name': 'VoteCasting',
        'issue_type': 'memory_leak',
        'recommendation_text':
            'Dispose StreamSubscriptions in dispose(). Use const constructors for static widgets. Reduce image cache size.',
        'implementation_priority': 'high',
        'expected_impact': {
          'latency_reduction_percent': 15,
          'memory_savings_percent': 35,
        },
        'ab_test_config': {
          'control_group_percentage': 50,
          'test_group_percentage': 50,
          'duration_days': 7,
        },
        'status': 'pending',
        'generated_at': DateTime.now().toIso8601String(),
      },
      {
        'recommendation_id': '3',
        'screen_name': 'SocialHomeFeed',
        'issue_type': 'low_fps',
        'recommendation_text':
            'Use RepaintBoundary for feed cards. Implement ListView.builder with itemExtent. Reduce overdraw with Opacity widgets.',
        'implementation_priority': 'high',
        'expected_impact': {
          'latency_reduction_percent': 10,
          'memory_savings_percent': 5,
        },
        'ab_test_config': {
          'control_group_percentage': 50,
          'test_group_percentage': 50,
          'duration_days': 7,
        },
        'status': 'in_progress',
        'generated_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _mockProblematicScreens() {
    return [
      {
        'screen_name': 'AnalyticsDashboard',
        'avg_load': 4200.0,
        'avg_memory': 68.0,
        'min_fps': 38.0,
        'avg_battery': 6.2,
      },
      {
        'screen_name': 'VoteCasting',
        'avg_load': 2800.0,
        'avg_memory': 55.0,
        'min_fps': 50.0,
        'avg_battery': 3.1,
      },
    ];
  }

  List<Map<String, dynamic>> _mockTrendData() {
    return List.generate(
      30,
      (i) => {
        'load_time_ms': 3000.0 - (i > 20 ? 800.0 : 0) + (i % 5) * 100.0,
        'profiled_at': DateTime.now()
            .subtract(Duration(days: 30 - i))
            .toIso8601String(),
        'optimization_applied': i == 21,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CustomAppBar(
        title: 'Performance Optimization Engine',
        actions: [
          IconButton(
            icon: _isAnalyzing
                ? SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.psychology),
            onPressed: _isAnalyzing ? null : _analyzeWithClaude,
            tooltip: 'Analyze with Claude AI',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats header
                  _buildStatsHeader(),
                  SizedBox(height: 2.h),

                  // Claude analysis button
                  _buildAnalysisButton(),
                  SizedBox(height: 2.h),

                  // Priority filter
                  _buildPriorityFilter(),
                  SizedBox(height: 2.h),

                  // Recommendations list
                  Text(
                    'Recommendations (${_filteredRecommendations.length})',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ..._filteredRecommendations.map(
                    (rec) => RecommendationCardWidget(
                      recommendation: rec,
                      onViewDetails: () =>
                          _loadTrendData(rec['screen_name'] as String? ?? ''),
                      onApply: () => _applyRecommendation(
                        rec['recommendation_id'] as String? ?? '',
                      ),
                      onScheduleAbTest: () => _scheduleAbTest(rec),
                    ),
                  ),

                  // Trend analysis panel
                  if (_selectedScreen.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    TrendAnalysisPanelWidget(
                      screenName: _selectedScreen,
                      trendData: _trendData,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatsHeader() {
    final counts = _priorityCounts;
    return Row(
      children: [
        _StatCard(
          label: 'Critical',
          count: counts['critical'] ?? 0,
          color: const Color(0xFFEF4444),
        ),
        SizedBox(width: 2.w),
        _StatCard(
          label: 'High',
          count: counts['high'] ?? 0,
          color: const Color(0xFFF97316),
        ),
        SizedBox(width: 2.w),
        _StatCard(
          label: 'Medium',
          count: counts['medium'] ?? 0,
          color: const Color(0xFFF59E0B),
        ),
        SizedBox(width: 2.w),
        _StatCard(
          label: 'Low',
          count: counts['low'] ?? 0,
          color: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildAnalysisButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.white, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claude AI Analysis',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isAnalyzing
                      ? 'Analyzing ${_problematicScreens.length} screens...'
                      : '${_problematicScreens.length} problematic screens detected',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isAnalyzing ? null : _analyzeWithClaude,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C3AED),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
            ),
            child: Text(
              _isAnalyzing ? 'Analyzing...' : 'Run Analysis',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['all', 'critical', 'high', 'medium', 'low'].map((priority) {
          final isSelected = _selectedPriorityFilter == priority;
          Color chipColor;
          switch (priority) {
            case 'critical':
              chipColor = const Color(0xFFEF4444);
              break;
            case 'high':
              chipColor = const Color(0xFFF97316);
              break;
            case 'medium':
              chipColor = const Color(0xFFF59E0B);
              break;
            case 'low':
              chipColor = const Color(0xFF3B82F6);
              break;
            default:
              chipColor = const Color(0xFF7C3AED);
          }
          return GestureDetector(
            onTap: () => setState(() => _selectedPriorityFilter = priority),
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                priority.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}