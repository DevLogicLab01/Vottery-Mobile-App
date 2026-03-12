import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

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
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _totalRevenue = 284750.0;
      _monthOverMonthChange = 12.4;

      _revenueBreakdown = {
        'SMS Ads': 68500,
        'Elections': 52300,
        'Marketplace': 45800,
        'Creator Tiers': 38200,
        'Templates': 29750,
        'Sponsorships': 50200,
      };

      _revenueStreams = [
        {
          'name': 'SMS Ads Revenue',
          'subtitle': '12,450 campaigns active',
          'revenue': 68500.0,
          'target': 75000.0,
          'trend': 8.3,
          'color': 0xFF89B4FA,
          'icon': Icons.sms,
        },
        {
          'name': 'Participatory Elections',
          'subtitle': '3,280 sponsored elections',
          'revenue': 52300.0,
          'target': 55000.0,
          'trend': 15.2,
          'color': 0xFFA6E3A1,
          'icon': Icons.how_to_vote,
        },
        {
          'name': 'Marketplace Services',
          'subtitle': '\$2.1M transaction volume',
          'revenue': 45800.0,
          'target': 50000.0,
          'trend': -2.1,
          'color': 0xFFCBA6F7,
          'icon': Icons.store,
        },
        {
          'name': 'Creator Tiers',
          'subtitle': '8,920 premium subscribers',
          'revenue': 38200.0,
          'target': 40000.0,
          'trend': 22.7,
          'color': 0xFFFAB387,
          'icon': Icons.workspace_premium,
        },
        {
          'name': 'Template Sales',
          'subtitle': '4,560 templates sold',
          'revenue': 29750.0,
          'target': 35000.0,
          'trend': 5.8,
          'color': 0xFFF5C2E7,
          'icon': Icons.dashboard_customize,
        },
        {
          'name': 'Sponsorships',
          'subtitle': '145 active campaigns',
          'revenue': 50200.0,
          'target': 48000.0,
          'trend': 18.9,
          'color': 0xFFF9E2AF,
          'icon': Icons.handshake,
        },
      ];

      _forecastData = {
        'forecast_30d': 312000.0,
        'confidence_30d': 0.88,
        'forecast_60d': 345000.0,
        'confidence_60d': 0.76,
        'forecast_90d': 389000.0,
        'confidence_90d': 0.64,
      };

      _historicalSpots = [
        const FlSpot(0, 210000),
        const FlSpot(1, 228000),
        const FlSpot(2, 245000),
        const FlSpot(3, 258000),
        const FlSpot(4, 271000),
        const FlSpot(5, 284750),
      ];

      _predictedSpots = [
        const FlSpot(5, 284750),
        const FlSpot(6, 312000),
        const FlSpot(7, 328000),
        const FlSpot(8, 345000),
        const FlSpot(9, 362000),
        const FlSpot(10, 375000),
        const FlSpot(11, 389000),
      ];

      _zones = [
        {
          'zone_number': 1,
          'name': 'US & Canada',
          'revenue': 98500.0,
          'arpu': 12.40,
          'growth_rate': 8.2,
        },
        {
          'zone_number': 2,
          'name': 'Western Europe',
          'revenue': 72300.0,
          'arpu': 9.80,
          'growth_rate': 11.5,
        },
        {
          'zone_number': 3,
          'name': 'Australia/NZ',
          'revenue': 28400.0,
          'arpu': 8.90,
          'growth_rate': 6.3,
        },
        {
          'zone_number': 4,
          'name': 'Latin America',
          'revenue': 31200.0,
          'arpu': 4.20,
          'growth_rate': 24.8,
        },
        {
          'zone_number': 5,
          'name': 'Eastern Europe',
          'revenue': 18900.0,
          'arpu': 3.60,
          'growth_rate': 18.1,
        },
        {
          'zone_number': 6,
          'name': 'Southeast Asia',
          'revenue': 22100.0,
          'arpu': 2.80,
          'growth_rate': 31.4,
        },
        {
          'zone_number': 7,
          'name': 'Middle East',
          'revenue': 8750.0,
          'arpu': 5.10,
          'growth_rate': 14.7,
        },
        {
          'zone_number': 8,
          'name': 'Africa',
          'revenue': 4600.0,
          'arpu': 1.20,
          'growth_rate': 42.3,
        },
      ];

      _recommendations = [
        {
          'recommendation':
              'Zone 4 Latin America: Increase election sponsorships by 20%',
          'projected_gain': '+\$15K/month',
          'rationale':
              'High growth rate of 24.8% indicates strong market appetite for sponsored elections',
          'impact': 'high',
          'difficulty': 'medium',
        },
        {
          'recommendation':
              'Template Marketplace: Launch premium tier with advanced templates',
          'projected_gain': '+\$8K/month',
          'rationale':
              'Template sales showing 5.8% growth with room to expand premium offerings',
          'impact': 'medium',
          'difficulty': 'low',
        },
        {
          'recommendation':
              'Zone 8 Africa: Introduce micro-payment SMS ad packages',
          'projected_gain': '+\$5K/month',
          'rationale':
              'Highest growth zone at 42.3% - low ARPU suggests price sensitivity',
          'impact': 'medium',
          'difficulty': 'high',
        },
        {
          'recommendation':
              'Creator Tiers: Add annual subscription discount (20% off)',
          'projected_gain': '+\$12K/month',
          'rationale':
              'Tier revenue growing 22.7% - annual plans improve retention and cash flow',
          'impact': 'high',
          'difficulty': 'low',
        },
      ];

      _isLoading = false;
    });
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
        children: [
          PredictiveRevenuePanelWidget(
            forecastData: _forecastData,
            historicalSpots: _historicalSpots,
            predictedSpots: _predictedSpots,
          ),
          SizedBox(height: 2.h),
          _buildScenarioAnalysisCard(),
          SizedBox(height: 3.h),
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
          _buildScenarioRow('Best Case', '\$425,000', const Color(0xFFA6E3A1)),
          _buildScenarioRow('Realistic', '\$389,000', const Color(0xFF89B4FA)),
          _buildScenarioRow('Worst Case', '\$340,000', const Color(0xFFF38BA8)),
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
