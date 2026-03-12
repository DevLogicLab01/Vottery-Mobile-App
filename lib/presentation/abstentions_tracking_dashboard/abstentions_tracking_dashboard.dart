import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/abstention_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/abstention_trends_chart_widget.dart';
import './widgets/abstention_reasons_widget.dart';
import './widgets/engagement_correlation_widget.dart';
import './widgets/high_abstention_elections_widget.dart';
import './widgets/improvement_recommendations_widget.dart';

/// Abstentions Tracking Dashboard
/// Provides comprehensive abstention management with voter choice analytics
class AbstentionsTrackingDashboard extends StatefulWidget {
  const AbstentionsTrackingDashboard({super.key});

  @override
  State<AbstentionsTrackingDashboard> createState() =>
      _AbstentionsTrackingDashboardState();
}

class _AbstentionsTrackingDashboardState
    extends State<AbstentionsTrackingDashboard>
    with SingleTickerProviderStateMixin {
  final AbstentionService _abstentionService = AbstentionService.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _highAbstentionElections = [];
  Map<String, dynamic> _engagementCorrelation = {};
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Statistics
  double _averageAbstentionRate = 0.0;
  int _totalAbstentions = 0;
  int _concerningElections = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAbstentionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAbstentionData() async {
    setState(() => _isLoading = true);

    try {
      final trends = await _abstentionService.getAbstentionTrends(days: 7);
      final highAbstentionElections = await _abstentionService
          .getHighAbstentionElections();
      final correlation = await _abstentionService.getEngagementCorrelation();

      // Calculate statistics
      double avgRate = 0.0;
      int totalAbs = 0;
      if (trends.isNotEmpty) {
        avgRate =
            trends.fold<double>(
              0.0,
              (sum, item) =>
                  sum +
                  ((item['average_abstention_rate'] as num?)?.toDouble() ??
                      0.0),
            ) /
            trends.length;
        totalAbs = trends.fold<int>(
          0,
          (sum, item) =>
              sum +
              ((item['elections_with_abstentions'] as num?)?.toInt() ?? 0),
        );
      }

      setState(() {
        _trends = trends;
        _highAbstentionElections = highAbstentionElections;
        _engagementCorrelation = correlation;
        _averageAbstentionRate = avgRate;
        _totalAbstentions = totalAbs;
        _concerningElections = highAbstentionElections.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load abstention data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadAbstentionData();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AbstentionsTrackingDashboard',
      onRetry: _loadAbstentionData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Abstentions Tracking',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(14.h),
            child: Column(
              children: [
                // Statistics Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '📊 Avg Rate',
                        '${_averageAbstentionRate.toStringAsFixed(1)}%',
                        _averageAbstentionRate > 20
                            ? Colors.red
                            : Colors.orange,
                      ),
                      _buildStatCard(
                        '📈 Total',
                        _totalAbstentions.toString(),
                        Colors.blue,
                      ),
                      _buildStatCard(
                        '⚠️ Concerning',
                        _concerningElections.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Trends'),
                    Tab(text: 'Analysis'),
                    Tab(text: 'Recommendations'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.primaryLight,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTrendsTab(),
                    _buildAnalysisTab(),
                    _buildRecommendationsTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abstention Trends (Last 7 Days)',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          AbstentionTrendsChartWidget(trends: _trends),
          SizedBox(height: 3.h),
          Text(
            'High Abstention Elections',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          HighAbstentionElectionsWidget(elections: _highAbstentionElections),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Abstention Reasons',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          const AbstentionReasonsWidget(),
          SizedBox(height: 3.h),
          Text(
            'Engagement Correlation',
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          EngagementCorrelationWidget(correlationData: _engagementCorrelation),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: ImprovementRecommendationsWidget(
        highAbstentionElections: _highAbstentionElections,
      ),
    );
  }
}
