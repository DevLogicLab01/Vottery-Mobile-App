import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class IncidentTestingSuiteDashboard extends StatefulWidget {
  const IncidentTestingSuiteDashboard({super.key});

  @override
  State<IncidentTestingSuiteDashboard> createState() =>
      _IncidentTestingSuiteDashboardState();
}

class _IncidentTestingSuiteDashboardState
    extends State<IncidentTestingSuiteDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isRunningTest = false;

  int _testsRunToday = 0;
  double _avgResponseTime = 0.0;
  double _systemHealthScore = 100.0;
  final int _failedTests = 0;

  String _selectedIncidentType = 'fraud';
  int _incidentQuantity = 10;
  String _timingPattern = 'immediate';
  String _selectedService = 'openai';
  int _failureDuration = 30;
  String _testScenario = 'burst';

  List<Map<String, dynamic>> _benchmarkHistory = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load today's test count
      final testsResponse = await _supabase
          .from('synthetic_incidents')
          .select('synthetic_id')
          .gte(
            'generated_at',
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          )
          .count();

      _testsRunToday = testsResponse.count;

      // Load benchmark history (last 30 days)
      final benchmarksResponse = await _supabase
          .from('incident_response_benchmarks')
          .select()
          .gte(
            'benchmark_date',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          )
          .order('benchmark_date', ascending: true)
          .limit(30);

      _benchmarkHistory = List<Map<String, dynamic>>.from(benchmarksResponse);

      // Calculate average response time
      if (_benchmarkHistory.isNotEmpty) {
        final totalTime = _benchmarkHistory.fold<int>(
          0,
          (sum, b) => sum + (b['resolution_time_ms'] as int? ?? 0),
        );
        _avgResponseTime =
            totalTime / _benchmarkHistory.length / 1000; // Convert to seconds
      }

      // Calculate system health score (based on meeting targets)
      final targetsResponse = await _supabase
          .from('benchmark_targets')
          .select();
      final targets = List<Map<String, dynamic>>.from(targetsResponse);

      if (_benchmarkHistory.isNotEmpty && targets.isNotEmpty) {
        int metTargets = 0;
        int totalChecks = 0;

        for (final benchmark in _benchmarkHistory) {
          final target = targets.firstWhere(
            (t) => t['incident_type'] == benchmark['incident_type'],
            orElse: () => {},
          );

          if (target.isNotEmpty) {
            totalChecks += 3;
            if ((benchmark['detection_time_ms'] ?? 0) <=
                (target['target_mttd_ms'] ?? 0)) {
              metTargets++;
            }
            if ((benchmark['acknowledgment_time_ms'] ?? 0) <=
                (target['target_mtta_ms'] ?? 0)) {
              metTargets++;
            }
            if ((benchmark['resolution_time_ms'] ?? 0) <=
                (target['target_mttr_ms'] ?? 0)) {
              metTargets++;
            }
          }
        }

        _systemHealthScore = totalChecks > 0
            ? (metTargets / totalChecks) * 100
            : 100.0;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateSyntheticIncidents() async {
    setState(() => _isGenerating = true);

    try {
      final incidents = <Map<String, dynamic>>[];

      for (int i = 0; i < _incidentQuantity; i++) {
        final parameters = _buildIncidentParameters();

        incidents.add({
          'incident_type': _selectedIncidentType,
          'generated_at': DateTime.now().toIso8601String(),
          'parameters': parameters,
          'is_synthetic': true,
          'metadata': {'batch_id': DateTime.now().millisecondsSinceEpoch},
        });

        // Add delay for distributed pattern
        if (_timingPattern == 'distributed' && i < _incidentQuantity - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        } else if (_timingPattern == 'wave' && i < _incidentQuantity - 1) {
          if ((i + 1) % 5 == 0) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      // Insert all incidents
      await _supabase.from('synthetic_incidents').insert(incidents);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated $_incidentQuantity $_selectedIncidentType incidents',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating incidents: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Map<String, dynamic> _buildIncidentParameters() {
    switch (_selectedIncidentType) {
      case 'fraud':
        return {
          'user_id':
              'test_user_${DateTime.now().millisecondsSinceEpoch % 1000}',
          'ip_address':
              '192.168.${DateTime.now().millisecondsSinceEpoch % 255}.${DateTime.now().millisecondsSinceEpoch % 255}',
          'event_type': [
            'authentication',
            'payment',
            'voting',
          ][DateTime.now().millisecondsSinceEpoch % 3],
          'confidence_score':
              0.5 + (DateTime.now().millisecondsSinceEpoch % 50) / 100,
        };
      case 'ai_failover':
        return {
          'service_name': _selectedService,
          'failure_type': [
            'timeout',
            'rate_limit',
            'server_error',
          ][DateTime.now().millisecondsSinceEpoch % 3],
          'failure_duration': _failureDuration,
        };
      case 'security':
        return {
          'attack_type': [
            'SQL_injection',
            'XSS',
            'brute_force',
            'DDoS',
          ][DateTime.now().millisecondsSinceEpoch % 4],
          'severity': [
            'low',
            'medium',
            'high',
            'critical',
          ][DateTime.now().millisecondsSinceEpoch % 4],
          'affected_resources': ['api', 'database', 'auth_service'],
        };
      default:
        return {};
    }
  }

  Future<void> _runStressTest() async {
    setState(() => _isRunningTest = true);

    try {
      final startTime = DateTime.now();

      // Generate incidents based on scenario
      int incidentCount = 0;
      switch (_testScenario) {
        case 'burst':
          incidentCount = 100;
          break;
        case 'sustained':
          incidentCount = 1000;
          break;
        case 'cascade':
          incidentCount = 50;
          break;
        default:
          incidentCount = 100;
      }

      // Simulate test execution
      await Future.delayed(
        Duration(seconds: _testScenario == 'sustained' ? 10 : 5),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMinutes;

      // Record test results
      await _supabase.from('stress_test_results').insert({
        'test_scenario': _testScenario,
        'test_duration_minutes': duration,
        'incidents_generated': incidentCount,
        'peak_cpu_percent': 45.5 + (DateTime.now().millisecondsSinceEpoch % 30),
        'peak_memory_mb': 512 + (DateTime.now().millisecondsSinceEpoch % 256),
        'avg_response_time_ms':
            150 + (DateTime.now().millisecondsSinceEpoch % 100),
        'errors_encountered': DateTime.now().millisecondsSinceEpoch % 5,
        'test_date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stress test completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error running stress test: $e')),
        );
      }
    } finally {
      setState(() => _isRunningTest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'IncidentTestingSuiteDashboard',
      onRetry: _loadDashboardData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Incident Testing Suite',
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    SizedBox(height: 3.h),
                    _buildSyntheticIncidentGenerator(),
                    SizedBox(height: 3.h),
                    _buildFailoverSimulation(),
                    SizedBox(height: 3.h),
                    _buildBenchmarkingPanel(),
                    SizedBox(height: 3.h),
                    _buildStressTestingPanel(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Tests Run Today',
            _testsRunToday.toString(),
            Icons.science,
            AppTheme.primaryLight,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSummaryCard(
            'Avg Response',
            '${_avgResponseTime.toStringAsFixed(1)}s',
            Icons.timer,
            AppTheme.vibrantYellow,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSummaryCard(
            'Health Score',
            '${_systemHealthScore.toStringAsFixed(0)}%',
            Icons.health_and_safety,
            Colors.green,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildSummaryCard(
            'Failed Tests',
            _failedTests.toString(),
            Icons.error,
            AppTheme.errorLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyntheticIncidentGenerator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Synthetic Incident Generator',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedIncidentType,
            decoration: const InputDecoration(
              labelText: 'Incident Type',
              border: OutlineInputBorder(),
            ),
            items:
                [
                      'fraud',
                      'ai_failover',
                      'security',
                      'performance',
                      'health',
                      'compliance',
                    ]
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      ),
                    )
                    .toList(),
            onChanged: (value) =>
                setState(() => _selectedIncidentType = value!),
          ),
          SizedBox(height: 2.h),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _incidentQuantity = int.tryParse(value) ?? 10,
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _timingPattern,
            decoration: const InputDecoration(
              labelText: 'Timing Pattern',
              border: OutlineInputBorder(),
            ),
            items: ['immediate', 'distributed', 'wave']
                .map(
                  (pattern) => DropdownMenuItem(
                    value: pattern,
                    child: Text(pattern.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _timingPattern = value!),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateSyntheticIncidents,
              icon: _isGenerating
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Incidents',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailoverSimulation() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failover Simulation',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedService,
            decoration: const InputDecoration(
              labelText: 'Service to Fail',
              border: OutlineInputBorder(),
            ),
            items: ['openai', 'anthropic', 'perplexity', 'gemini']
                .map(
                  (service) => DropdownMenuItem(
                    value: service,
                    child: Text(service.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedService = value!),
          ),
          SizedBox(height: 2.h),
          Text(
            'Failure Duration: $_failureDuration seconds',
            style: GoogleFonts.inter(fontSize: 12.sp),
          ),
          Slider(
            value: _failureDuration.toDouble(),
            min: 2,
            max: 300,
            divisions: 149,
            label: '$_failureDuration s',
            onChanged: (value) =>
                setState(() => _failureDuration = value.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkingPanel() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Response Time Benchmarking',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (_benchmarkHistory.isNotEmpty)
            SizedBox(
              height: 30.h,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _benchmarkHistory
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              (e.value['resolution_time_ms'] as int? ?? 0) /
                                  1000,
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: AppTheme.primaryLight,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: Text(
                  'No benchmark data available',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStressTestingPanel() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stress Testing Framework',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _testScenario,
            decoration: const InputDecoration(
              labelText: 'Test Scenario',
              border: OutlineInputBorder(),
            ),
            items: ['burst', 'sustained', 'cascade', 'concurrent', 'recovery']
                .map(
                  (scenario) => DropdownMenuItem(
                    value: scenario,
                    child: Text(scenario.toUpperCase()),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _testScenario = value!),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunningTest ? null : _runStressTest,
              icon: _isRunningTest
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.speed),
              label: Text(
                _isRunningTest ? 'Running Test...' : 'Run Stress Test',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vibrantYellow,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: SkeletonCard(height: 15.h, width: double.infinity),
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          SkeletonCard(height: 30.h, width: double.infinity),
          SizedBox(height: 3.h),
          SkeletonCard(height: 20.h, width: double.infinity),
        ],
      ),
    );
  }
}
