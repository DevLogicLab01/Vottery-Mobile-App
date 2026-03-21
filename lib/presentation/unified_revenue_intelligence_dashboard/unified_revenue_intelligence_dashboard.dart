import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/revenue_intelligence_service.dart';
import './widgets/growth_recommendations_card_widget.dart';
import './widgets/predictive_revenue_panel_widget.dart';
import './widgets/revenue_breakdown_chart_widget.dart';
import './widgets/revenue_streams_list_widget.dart';
import './widgets/total_revenue_card_widget.dart';
import './widgets/zone_revenue_analysis_widget.dart';

class UnifiedRevenueIntelligenceDashboard extends StatefulWidget {
  const UnifiedRevenueIntelligenceDashboard({super.key});

  @override
  State<UnifiedRevenueIntelligenceDashboard> createState() =>
      _UnifiedRevenueIntelligenceDashboardState();
}

class _UnifiedRevenueIntelligenceDashboardState
    extends State<UnifiedRevenueIntelligenceDashboard> {
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  // Revenue data
  double _totalRevenue = 0;
  double _monthOverMonthChange = 0;
  Map<String, double> _revenueBreakdown = {};
  List<Map<String, dynamic>> _revenueStreams = [];
  Map<String, dynamic> _forecastData = {};
  List<FlSpot> _historicalSpots = [];
  List<FlSpot> _predictedSpots = [];
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() => _isLoading = true);
    final svc = RevenueIntelligenceService.instance;
    try {
      const timeRange = '30d';
      final rawStreams = await svc.getAllRevenueStreams(timeRange: timeRange);
      final streamsUi = await svc.getMobileRevenueStreams(timeRange: timeRange);
      final breakdown = await svc.getRevenueBreakdown(timeRange: timeRange);
      final historical = await svc.getHistoricalRevenue(months: 6);
      final forecast = await svc.generateRevenueForecast(
        historicalData: historical,
        streams: rawStreams,
        forecastDays: 30,
      );

      final total =
          rawStreams.fold<double>(0, (a, s) => a + (s['total'] as double));

      double mom = 12.4;
      if (historical.length >= 2) {
        final a = (historical[historical.length - 2]['revenue'] as num)
            .toDouble();
        final b = (historical[historical.length - 1]['revenue'] as num)
            .toDouble();
        if (a > 0) mom = ((b - a) / a) * 100;
      }

      final f30 = (forecast['forecast_total'] as num?)?.toDouble() ??
          total * 1.12;
      final f60 = f30 * (1.26 / 1.12);
      final f90 = f30 * (1.42 / 1.12);

      double conf(String key) {
        final ci = forecast['confidence_interval'];
        if (ci is Map && ci['low'] != null && ci['high'] != null) {
          final low = (ci['low'] as num).toDouble();
          final high = (ci['high'] as num).toDouble();
          final mid = (low + high) / 2;
          if (mid > 0) return ((high - low) / mid).clamp(0.2, 0.95);
        }
        return key == '30'
            ? 0.88
            : key == '60'
                ? 0.76
                : 0.64;
      }

      final histSpots = <FlSpot>[];
      for (var i = 0; i < historical.length; i++) {
        histSpots.add(FlSpot(
          i.toDouble(),
          (historical[i]['revenue'] as num).toDouble(),
        ));
      }

      final lastX = histSpots.isNotEmpty ? histSpots.last.x : 0.0;
      final lastY = histSpots.isNotEmpty ? histSpots.last.y : total;
      final predSpots = <FlSpot>[
        FlSpot(lastX, lastY),
        FlSpot(lastX + 1, f30),
        FlSpot(lastX + 2, f60),
        FlSpot(lastX + 3, f90),
      ];

      var zones = await svc.generateZoneRecommendations(rawStreams);
      for (var i = 0; i < zones.length; i++) {
        zones[i]['zone_number'] = i + 1;
      }

      final sorted = List<Map<String, dynamic>>.from(zones)
        ..sort(
          (a, b) => ((b['growth_rate'] as num?)?.toDouble() ?? 0).compareTo(
                (a['growth_rate'] as num?)?.toDouble() ?? 0,
              ),
        );
      final recs = <Map<String, dynamic>>[];
      for (final z in sorted.take(4)) {
        final name = z['name']?.toString() ?? 'Zone';
        final strat = z['primary_strategy']?.toString() ??
            'Expand localized monetization and partnerships';
        final rev = (z['revenue'] as num?)?.toDouble() ?? 0;
        recs.add({
          'recommendation': '$name: $strat',
          'projected_gain':
              '+\$${(rev * 0.015 / 1000).toStringAsFixed(1)}K/month',
          'rationale':
              'Growth rate ${(z['growth_rate'] as num?)?.toStringAsFixed(1) ?? '—'}% with ARPU \$${(z['arpu'] as num?)?.toStringAsFixed(2) ?? '—'}',
          'impact': (z['growth_rate'] as num?) != null &&
                  (z['growth_rate'] as num) > 25
              ? 'high'
              : 'medium',
          'difficulty': 'medium',
        });
      }

      if (!mounted) return;
      setState(() {
        _totalRevenue = total;
        _monthOverMonthChange = mom;
        _revenueBreakdown = breakdown;
        _revenueStreams = streamsUi;
        _forecastData = {
          'forecast_30d': f30,
          'confidence_30d': conf('30'),
          'forecast_60d': f60,
          'confidence_60d': conf('60'),
          'forecast_90d': f90,
          'confidence_90d': conf('90'),
          'executive_summary': forecast['summary'],
        };
        _historicalSpots = histSpots;
        _predictedSpots = predSpots;
        _zones = zones;
        _recommendations =
            recs.isNotEmpty ? recs : svc.defaultGrowthRecommendations();
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('UnifiedRevenueIntelligenceDashboard load error: $e $st');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  final List<String> _tabs = [
    'Overview',
    'Streams',
    'Forecast',
    'Zones',
    'Insights',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181825),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Intelligence',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'All Revenue Streams',
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white54),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadRevenueData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            color: const Color(0xFF1E1E2E),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 6),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedTabIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTabIndex = index),
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF89B4FA)
                          : const Color(0xFF313244),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      _tabs[index],
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF1E1E2E)
                            : Colors.white60,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF89B4FA)),
            )
          : _buildTabContent(),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildStreamsTab();
      case 2:
        return _buildForecastTab();
      case 3:
        return _buildZonesTab();
      case 4:
        return _buildInsightsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          TotalRevenueCardWidget(
            totalRevenue: _totalRevenue,
            monthOverMonthChange: _monthOverMonthChange,
          ),
          SizedBox(height: 2.h),
          RevenueBreakdownChartWidget(
            revenueBreakdown: _revenueBreakdown,
            onSegmentTap: (segment) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Drilling into $segment revenue...'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF313244),
                ),
              );
            },
          ),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildStreamsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          RevenueStreamsListWidget(streams: _revenueStreams),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildForecastTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PredictiveRevenuePanelWidget(
            forecastData: _forecastData,
            historicalSpots: _historicalSpots,
            predictedSpots: _predictedSpots,
          ),
          if (_forecastData['executive_summary'] != null &&
              _forecastData['executive_summary'].toString().isNotEmpty) ...[
            SizedBox(height: 2.h),
            _buildExecutiveSummaryCard(),
          ],
          SizedBox(height: 2.h),
          _buildScenarioAnalysisCard(),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummaryCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Executive summary',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _forecastData['executive_summary'].toString(),
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          ZoneRevenueAnalysisWidget(zones: _zones),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          GrowthRecommendationsCardWidget(
            recommendations: _recommendations,
            onImplement: (rec) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Implementing: ${rec['recommendation']}'),
                  backgroundColor: const Color(0xFFA6E3A1).withAlpha(204),
                ),
              );
            },
            onAnalyze: (rec) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Analyzing: ${rec['recommendation']}'),
                  backgroundColor: const Color(0xFF89B4FA).withAlpha(204),
                ),
              );
            },
          ),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  Widget _buildScenarioAnalysisCard() {
    final base = (_forecastData['forecast_90d'] as num?)?.toDouble() ?? 389000;
    final best = base * 1.09;
    final realistic = base;
    final worst = base * 0.88;
    String fmt(double v) =>
        '\$${v >= 1000000 ? '${(v / 1000000).toStringAsFixed(2)}M' : '${(v / 1000).toStringAsFixed(0)}K'}';

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '90-Day Scenario Analysis',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildScenarioRow('Best Case', fmt(best), const Color(0xFFA6E3A1)),
          _buildScenarioRow(
              'Realistic', fmt(realistic), const Color(0xFF89B4FA)),
          _buildScenarioRow('Worst Case', fmt(worst), const Color(0xFFF38BA8)),
        ],
      ),
    );
  }

  Widget _buildScenarioRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
