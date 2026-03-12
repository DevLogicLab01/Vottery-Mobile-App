import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/enhanced_analytics_service.dart';
import '../../services/system_monitoring_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../real_time_system_monitoring_dashboard/widgets/ai_service_health_card_widget.dart';
import './widgets/cache_analytics_card_widget.dart';
import './widgets/offline_sync_metrics_widget.dart';
import './widgets/voice_interaction_stats_widget.dart';
import './widgets/performance_summary_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AppPerformanceDashboard extends StatefulWidget {
  const AppPerformanceDashboard({super.key});

  @override
  State<AppPerformanceDashboard> createState() =>
      _AppPerformanceDashboardState();
}

class _AppPerformanceDashboardState extends State<AppPerformanceDashboard> {
  bool _isLoading = true;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;

  Map<String, Map<String, dynamic>> _aiServiceHealth = {};
  Map<String, dynamic> _cacheAnalytics = {};
  Map<String, dynamic> _offlineSyncMetrics = {};
  Map<String, dynamic> _voiceStats = {};
  Map<String, dynamic> _performanceSummary = {};
  List<Map<String, dynamic>> _recentErrors = [];

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
    _setupAutoRefresh();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'App Performance Dashboard',
      screenClass: 'AppPerformanceDashboard',
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) {
          _loadPerformanceData(silent: true);
        }
      });
    }
  }

  Future<void> _loadPerformanceData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      await Future.wait([
        _loadAIServiceHealth(),
        _loadCacheAnalytics(),
        _loadOfflineSyncMetrics(),
        _loadVoiceStats(),
        _loadPerformanceSummary(),
        _loadRecentErrors(),
      ]);
    } catch (e) {
      debugPrint('Load performance data error: $e');
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAIServiceHealth() async {
    try {
      final openaiHealth = await _checkOpenAIHealth();
      final anthropicHealth = await _checkAnthropicHealth();
      final geminiHealth = await _checkGeminiHealth();
      final perplexityHealth = await _checkPerplexityHealth();

      if (mounted) {
        setState(() {
          _aiServiceHealth = {
            'openai': openaiHealth,
            'anthropic': anthropicHealth,
            'gemini': geminiHealth,
            'perplexity': perplexityHealth,
          };
        });
      }
    } catch (e) {
      debugPrint('Load AI service health error: $e');
    }
  }

  Future<Map<String, dynamic>> _checkOpenAIHealth() async {
    final startTime = DateTime.now();
    try {
      // Simulate health check
      await Future.delayed(const Duration(milliseconds: 100));
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      return {
        'status': 'healthy',
        'latency': latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _checkAnthropicHealth() async {
    final startTime = DateTime.now();
    try {
      await Future.delayed(const Duration(milliseconds: 120));
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      return {
        'status': 'healthy',
        'latency': latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _checkGeminiHealth() async {
    final startTime = DateTime.now();
    try {
      await Future.delayed(const Duration(milliseconds: 90));
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      return {
        'status': 'healthy',
        'latency': latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> _checkPerplexityHealth() async {
    final startTime = DateTime.now();
    try {
      await Future.delayed(const Duration(milliseconds: 110));
      final latency = DateTime.now().difference(startTime).inMilliseconds;
      return {
        'status': 'healthy',
        'latency': latency,
        'last_check': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> _loadCacheAnalytics() async {
    try {
      // Simulate cache analytics
      setState(() {
        _cacheAnalytics = {
          'hit_rate': 87.5,
          'miss_rate': 12.5,
          'total_requests': 1247,
          'cache_size_mb': 45.3,
          'eviction_count': 23,
        };
      });
    } catch (e) {
      debugPrint('Load cache analytics error: $e');
    }
  }

  Future<void> _loadOfflineSyncMetrics() async {
    try {
      setState(() {
        _offlineSyncMetrics = {
          'success_rate': 96.8,
          'pending_count': 3,
          'failed_count': 2,
          'last_sync': DateTime.now().subtract(const Duration(minutes: 5)),
          'total_synced': 342,
        };
      });
    } catch (e) {
      debugPrint('Load offline sync metrics error: $e');
    }
  }

  Future<void> _loadVoiceStats() async {
    try {
      setState(() {
        _voiceStats = {
          'recognition_accuracy': 94.2,
          'avg_response_time_ms': 850,
          'total_interactions': 156,
          'success_rate': 92.3,
          'error_count': 12,
        };
      });
    } catch (e) {
      debugPrint('Load voice stats error: $e');
    }
  }

  Future<void> _loadPerformanceSummary() async {
    try {
      final latencyStats = await SystemMonitoringService.instance
          .getAPILatencyStatistics();
      final dbPerformance = await SystemMonitoringService.instance
          .getDatabasePerformance();

      setState(() {
        _performanceSummary = {
          'avg_api_latency': latencyStats['average_ms'] ?? 0,
          'p95_latency': latencyStats['p95_ms'] ?? 0,
          'error_rate': 2.3,
          'uptime': 99.8,
          'active_connections': dbPerformance['active_connections'] ?? 0,
        };
      });
    } catch (e) {
      debugPrint('Load performance summary error: $e');
    }
  }

  Future<void> _loadRecentErrors() async {
    try {
      final alerts = await SystemMonitoringService.instance.getSystemAlerts(
        severity: 'critical',
        limit: 5,
      );

      setState(() {
        _recentErrors = alerts;
      });
    } catch (e) {
      debugPrint('Load recent errors error: $e');
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _setupAutoRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AppPerformanceDashboard',
      onRetry: () => _loadPerformanceData(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Performance Dashboard',
            variant: CustomAppBarVariant.standard,
            actions: [
              IconButton(
                icon: Icon(
                  _autoRefreshEnabled ? Icons.pause : Icons.play_arrow,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _toggleAutoRefresh,
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: () => _loadPerformanceData(),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: () => _loadPerformanceData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Performance Summary', theme),
                      PerformanceSummaryCardWidget(
                        summary: _performanceSummary,
                      ),
                      SizedBox(height: 3.h),
                      _buildSectionHeader('AI Service Health', theme),
                      _buildAIServiceHealthSection(),
                      SizedBox(height: 3.h),
                      _buildSectionHeader('Cache Analytics', theme),
                      CacheAnalyticsCardWidget(analytics: _cacheAnalytics),
                      SizedBox(height: 3.h),
                      _buildSectionHeader('Offline Sync Metrics', theme),
                      OfflineSyncMetricsWidget(metrics: _offlineSyncMetrics),
                      SizedBox(height: 3.h),
                      _buildSectionHeader('Voice Interaction Stats', theme),
                      VoiceInteractionStatsWidget(stats: _voiceStats),
                      SizedBox(height: 3.h),
                      if (_recentErrors.isNotEmpty) ...[
                        _buildSectionHeader('Recent Critical Errors', theme),
                        _buildRecentErrorsSection(theme),
                        SizedBox(height: 3.h),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAIServiceHealthSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          AIServiceHealthCardWidget(
            serviceName: 'OpenAI',
            health: _aiServiceHealth['openai'] ?? {},
          ),
          SizedBox(height: 2.h),
          AIServiceHealthCardWidget(
            serviceName: 'Anthropic (Claude)',
            health: _aiServiceHealth['anthropic'] ?? {},
          ),
          SizedBox(height: 2.h),
          AIServiceHealthCardWidget(
            serviceName: 'Google Gemini',
            health: _aiServiceHealth['gemini'] ?? {},
          ),
          SizedBox(height: 2.h),
          AIServiceHealthCardWidget(
            serviceName: 'Perplexity',
            health: _aiServiceHealth['perplexity'] ?? {},
          ),
        ],
      ),
    );
  }

  Widget _buildRecentErrorsSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: _recentErrors.map((error) {
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.red.withAlpha(51)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error['title'] ?? 'Error',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      if (error['description'] != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          error['description'],
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
