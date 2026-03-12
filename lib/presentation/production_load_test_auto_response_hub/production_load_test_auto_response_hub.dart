import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/load_testing/production_load_test_auto_response_service.dart';
import '../../services/load_testing/production_load_test_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/circuit_breaker_status_widget.dart';
import './widgets/response_action_card_widget.dart';
import './widgets/scaling_dashboard_widget.dart';
import './widgets/threshold_status_card_widget.dart';

class ProductionLoadTestAutoResponseHub extends StatefulWidget {
  const ProductionLoadTestAutoResponseHub({super.key});

  @override
  State<ProductionLoadTestAutoResponseHub> createState() =>
      _ProductionLoadTestAutoResponseHubState();
}

class _ProductionLoadTestAutoResponseHubState
    extends State<ProductionLoadTestAutoResponseHub>
    with SingleTickerProviderStateMixin {
  final ProductionLoadTestAutoResponseService _autoResponseService =
      ProductionLoadTestAutoResponseService.instance;
  final ProductionLoadTestService _loadTestService =
      ProductionLoadTestService();

  late TabController _tabController;
  bool _isLoading = true;
  bool _isRunningTest = false;
  bool _isScaling = false;

  List<Map<String, dynamic>> _responseHistory = [];
  List<Map<String, dynamic>> _circuitBreakers = [];
  List<Map<String, dynamic>> _pausedElections = [];
  LoadTestAutoResponseResult? _lastResult;
  LoadTestReport? _lastReport;

  // Simulated current metrics for display
  double _currentWsSuccessRate = 92.5;
  int _currentBlockchainTps = 1250;
  int _currentRegressions = 0;
  int _selectedTierIndex = 4; // Default 500K

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _autoResponseService.getResponseHistory(),
        _autoResponseService.getCircuitBreakerStates(),
        _autoResponseService.getPausedElections(),
      ]);
      if (mounted) {
        setState(() {
          _responseHistory = results[0];
          _circuitBreakers = results[1];
          _pausedElections = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runLoadTestWithAutoResponse() async {
    setState(() => _isRunningTest = true);
    try {
      // Show progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Running load test for ${ProductionLoadTestService.formatTierLabel(_selectedTierIndex)}...',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Run the load test
      final report = await _loadTestService.runLoadTest(_selectedTierIndex);
      setState(() {
        _lastReport = report;
        _currentWsSuccessRate = report.websocketMetrics.connectionSuccessRate;
        _currentBlockchainTps = report.blockchainMetrics.avgTps;
        _currentRegressions = report.regressionsDetected
            .where((r) => r.severity == 'critical')
            .length;
        _isScaling = true;
      });

      // Trigger auto-response
      final result = await _autoResponseService.onLoadTestComplete(report);
      setState(() {
        _lastResult = result;
        _isScaling = false;
      });

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.triggered
                  ? '✅ Auto-response triggered: ${result.actions.join(", ")}'
                  : '✅ Load test complete - all thresholds OK',
            ),
            backgroundColor: result.triggered ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunningTest = false);
    }
  }

  Future<void> _rollbackAll() async {
    final testId = _lastReport?.testId ?? '';
    final success = await _autoResponseService.rollbackAllActions(testId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '✅ Rollback successful' : '❌ Rollback failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: 'Load Test Auto-Response Hub',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimaryLight),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const SkeletonDashboard()
          : Column(
              children: [
                _buildStatusOverview(),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
                  labelColor: AppTheme.primaryLight,
                  unselectedLabelColor: AppTheme.textSecondaryLight,
                  indicatorColor: AppTheme.primaryLight,
                  tabs: const [
                    Tab(text: 'Thresholds'),
                    Tab(text: 'Actions'),
                    Tab(text: 'Circuit Breakers'),
                    Tab(text: 'Scaling'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildThresholdsTab(),
                      _buildActionsTab(),
                      _buildCircuitBreakersTab(),
                      _buildScalingTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRunningTest ? null : _runLoadTestWithAutoResponse,
        backgroundColor: _isRunningTest ? Colors.grey : AppTheme.primaryLight,
        icon: _isRunningTest
            ? SizedBox(
                width: 5.w,
                height: 5.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow, color: Colors.white),
        label: Text(
          _isRunningTest ? 'Running...' : 'Run Test + Auto-Response',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverview() {
    final wsBreached = _currentWsSuccessRate < 85.0;
    final tpsBreached = _currentBlockchainTps < 1000;
    final regressionsBreached = _currentRegressions > 0;
    final activeActions = _lastResult?.actions.length ?? 0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withAlpha(200),
            AppTheme.primaryLight.withAlpha(150),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Auto-Response Status',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '500K+ Tier',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat(
                'WS Rate',
                '${_currentWsSuccessRate.toStringAsFixed(1)}%',
                wsBreached,
              ),
              _buildStatusStat(
                'Chain TPS',
                '$_currentBlockchainTps',
                tpsBreached,
              ),
              _buildStatusStat(
                'Regressions',
                '$_currentRegressions',
                regressionsBreached,
              ),
              _buildStatusStat('Actions', '$activeActions', false),
            ],
          ),
          if (_lastResult != null) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _lastResult!.message,
                style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusStat(String label, String value, bool isAlert) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: isAlert ? Colors.yellow : Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
    );
  }

  Widget _buildThresholdsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Load Test Tier',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<int>(
            initialValue: _selectedTierIndex,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.h,
              ),
            ),
            items: List.generate(
              ProductionLoadTestService.userLoadTiers.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  ProductionLoadTestService.formatTierLabel(i),
                  style: GoogleFonts.inter(fontSize: 11.sp),
                ),
              ),
            ),
            onChanged: (v) => setState(() => _selectedTierIndex = v ?? 4),
          ),
          SizedBox(height: 2.h),
          Text(
            'Threshold Monitoring',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ThresholdStatusCardWidget(
            title: 'WebSocket Success Rate',
            metric: 'Triggers: scaleSupabaseConnections',
            currentValue: _currentWsSuccessRate,
            threshold: 85.0,
            isBreached: _currentWsSuccessRate < 85.0,
            unit: '%',
            icon: Icons.wifi,
          ),
          SizedBox(height: 1.h),
          ThresholdStatusCardWidget(
            title: 'Blockchain TPS',
            metric: 'Triggers: pauseHighRiskElections',
            currentValue: _currentBlockchainTps.toDouble(),
            threshold: 1000,
            isBreached: _currentBlockchainTps < 1000,
            unit: ' TPS',
            icon: Icons.link,
          ),
          SizedBox(height: 1.h),
          ThresholdStatusCardWidget(
            title: 'Critical Regressions',
            metric: 'Triggers: activateCircuitBreakers',
            currentValue: _currentRegressions.toDouble(),
            threshold: 0,
            isBreached: _currentRegressions > 0,
            unit: '',
            icon: Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    final actions = _autoResponseService.responseLog;
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Response Actions',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Actions triggered automatically when thresholds are breached',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ResponseActionCardWidget(
            actionName: 'scaleSupabaseConnections',
            description:
                'Increases connection pool size by 50% and scales read replicas to 3',
            status:
                actions.any((a) => a['action'] == 'scaleSupabaseConnections')
                ? 'success'
                : 'pending',
            details:
                'Supabase Management API → connection_pool_size +50%, read_replicas: 3',
            onRollback: _lastReport != null ? _rollbackAll : null,
          ),
          ResponseActionCardWidget(
            actionName: 'pauseHighRiskElections',
            description:
                'Pauses elections with risk_score > 0.7 and notifies creators',
            status: actions.any((a) => a['action'] == 'pauseHighRiskElections')
                ? 'success'
                : 'pending',
            details:
                'Query: elections WHERE risk_score > 0.7 AND status = active → paused',
            onRollback: _lastReport != null ? _rollbackAll : null,
          ),
          ResponseActionCardWidget(
            actionName: 'activateCircuitBreakers',
            description:
                'Enables rate limiting for affected services, sets rollback_ready flag',
            status: actions.any((a) => a['action'] == 'activateCircuitBreakers')
                ? 'success'
                : 'pending',
            details:
                'circuit_breaker_state → state: open, rate_limiting: 100 RPS, rollback_ready: true',
            onRollback: _lastReport != null ? _rollbackAll : null,
          ),
          SizedBox(height: 2.h),
          if (_pausedElections.isNotEmpty) ...[
            Text(
              'Paused Elections (${_pausedElections.length})',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 1.h),
            ..._pausedElections.map(
              (e) => Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(15),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.orange.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle, color: Colors.orange, size: 5.w),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] ?? 'Election',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Risk Score: ${(e['risk_score'] ?? 0).toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircuitBreakersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: CircuitBreakerStatusWidget(
        circuitBreakers: _circuitBreakers,
        onRollback: _circuitBreakers.isNotEmpty ? _rollbackAll : null,
      ),
    );
  }

  Widget _buildScalingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: ScalingDashboardWidget(
        responseLog: _autoResponseService.responseLog,
        isScaling: _isScaling,
      ),
    );
  }
}