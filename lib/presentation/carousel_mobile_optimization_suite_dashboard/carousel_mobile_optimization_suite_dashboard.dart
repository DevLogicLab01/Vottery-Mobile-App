import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_mobile_optimization_service.dart';
import '../../theme/app_theme.dart';
import './widgets/optimization_status_overview_widget.dart';
import './widgets/gesture_performance_panel_widget.dart';
import './widgets/battery_monitoring_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/device_capability_widget.dart';
import './widgets/optimization_controls_widget.dart';

/// Carousel Mobile Optimization Suite Dashboard
/// Comprehensive mobile performance enhancement with gesture refinements,
/// battery monitoring, and device-adaptive optimization
class CarouselMobileOptimizationSuiteDashboard extends StatefulWidget {
  const CarouselMobileOptimizationSuiteDashboard({super.key});

  @override
  State<CarouselMobileOptimizationSuiteDashboard> createState() =>
      _CarouselMobileOptimizationSuiteDashboardState();
}

class _CarouselMobileOptimizationSuiteDashboardState
    extends State<CarouselMobileOptimizationSuiteDashboard>
    with SingleTickerProviderStateMixin {
  final CarouselMobileOptimizationService _optimizationService =
      CarouselMobileOptimizationService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _gestureAnalytics = {};
  List<Map<String, dynamic>> _optimizationMetrics = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeOptimization();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeOptimization() async {
    setState(() => _isLoading = true);

    try {
      await _optimizationService.initialize();
      await _loadAnalytics();
    } catch (e) {
      debugPrint('Error initializing optimization: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final gestureAnalytics = await _optimizationService.getGestureAnalytics(
        days: 7,
      );
      final metrics = await _optimizationService.getOptimizationMetrics(
        deviceModel: _optimizationService.deviceModel,
        days: 7,
      );

      setState(() {
        _gestureAnalytics = gestureAnalytics;
        _optimizationMetrics = metrics;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Mobile Optimization Suite',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppThemeColors.electricGold,
          labelColor: AppThemeColors.electricGold,
          unselectedLabelColor: AppTheme.textSecondaryDark,
          labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Gestures'),
            Tab(text: 'Performance'),
            Tab(text: 'Battery'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildGesturesTab(),
                _buildPerformanceTab(),
                _buildBatteryTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OptimizationStatusOverviewWidget(
              deviceModel: _optimizationService.deviceModel,
              deviceTier: _optimizationService.deviceTier,
              optimizationLevel: _optimizationService.optimizationLevel,
              currentFPS: _optimizationService.currentFPS,
              isBatterySaverMode: _optimizationService.isBatterySaverMode,
            ),
            SizedBox(height: 3.h),
            DeviceCapabilityWidget(
              deviceModel: _optimizationService.deviceModel,
              deviceTier: _optimizationService.deviceTier,
              targetFrameRate: _optimizationService.targetFrameRate,
              imageQuality: _optimizationService.imageQuality,
            ),
            SizedBox(height: 3.h),
            OptimizationControlsWidget(
              optimizationLevel: _optimizationService.optimizationLevel,
              shouldEnableParallax: _optimizationService.shouldEnableParallax,
              shouldEnableGlassmorphism:
                  _optimizationService.shouldEnableGlassmorphism,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGesturesTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GesturePerformancePanelWidget(
              gestureAnalytics: _gestureAnalytics,
              swipeVelocityThreshold: _optimizationService
                  .getSwipeVelocityThreshold(),
            ),
            SizedBox(height: 3.h),
            _buildGestureSettingsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PerformanceMetricsWidget(
              currentFPS: _optimizationService.currentFPS,
              targetFPS: _optimizationService.targetFrameRate,
              frameDropsCount: _optimizationService.frameDropsCount,
              averageFrameTime: _optimizationService.averageFrameRenderTime,
            ),
            SizedBox(height: 3.h),
            _buildPerformanceChartCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BatteryMonitoringWidget(
              isBatterySaverMode: _optimizationService.isBatterySaverMode,
              optimizationLevel: _optimizationService.optimizationLevel,
            ),
            SizedBox(height: 3.h),
            _buildBatteryImpactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureSettingsCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gesture Configuration',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildSettingRow(
            'Swipe Velocity Threshold',
            '${_optimizationService.getSwipeVelocityThreshold().toStringAsFixed(0)} px/s',
          ),
          _buildSettingRow('Haptic Feedback', 'Enabled'),
          _buildSettingRow('Touch Target Size', '48x48 dp'),
        ],
      ),
    );
  }

  Widget _buildPerformanceChartCard() {
    if (_optimizationMetrics.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No performance data available',
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS Trend (Last 7 Days)',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _optimizationMetrics
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            (e.value['avg_fps'] as num?)?.toDouble() ?? 0.0,
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    color: AppThemeColors.neonMint,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryImpactCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Battery Impact Analysis',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.electricGold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Carousel usage optimized for minimal battery drain',
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 2.h),
          if (_optimizationService.isBatterySaverMode)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.battery_alert, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Battery Saver Mode Active',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
