import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/perplexity_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AIAnalyticsHubScreen extends StatefulWidget {
  const AIAnalyticsHubScreen({super.key});

  @override
  State<AIAnalyticsHubScreen> createState() => _AIAnalyticsHubScreenState();
}

class _AIAnalyticsHubScreenState extends State<AIAnalyticsHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isRefreshing = false;
  DateTime _lastRefresh = DateTime.now();

  Map<String, dynamic> _marketIntelligence = {};
  Map<String, dynamic> _sentimentData = {};
  Map<String, dynamic> _fraudForecast = {};
  Map<String, dynamic> _strategicPlan = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        PerplexityService.instance.analyzeMarketSentiment(
          topic: 'civic engagement voting trends',
          category: 'politics',
        ),
        PerplexityService.instance.analyzeMarketSentiment(
          topic: 'voter participation',
        ),
        PerplexityService.instance.forecastFraudTrends(historicalData: []),
        PerplexityService.instance.generateStrategicPlan(
          businessData: {'platform': 'vottery', 'focus': 'civic_engagement'},
        ),
      ]);

      setState(() {
        _marketIntelligence = results[0];
        _sentimentData = results[1];
        _fraudForecast = results[2];
        _strategicPlan = results[3];
        _lastRefresh = DateTime.now();
      });
    } catch (e) {
      debugPrint('Load analytics error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshAnalytics() async {
    setState(() => _isRefreshing = true);
    await _loadAllAnalytics();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AIAnalyticsHub',
      onRetry: _loadAllAnalytics,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'AI Analytics Hub',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.refresh, size: 24.w),
              onPressed: _isRefreshing ? null : _refreshAnalytics,
            ),
            SizedBox(width: 2.w),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Market Intelligence'),
              Tab(text: 'Sentiment Tracking'),
              Tab(text: 'Fraud Forecasting'),
              Tab(text: 'Strategic Planning'),
              Tab(text: 'User Engagement'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    _buildStatusHeader(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMarketIntelligenceTab(),
                          _buildSentimentTrackingTab(),
                          _buildFraudForecastingTab(),
                          _buildStrategicPlanningTab(),
                          _buildUserEngagementTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final minutesAgo = DateTime.now().difference(_lastRefresh).inMinutes;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18.w),
          SizedBox(width: 2.w),
          Text(
            'AI Processing Active',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: Colors.green.shade700,
            ),
          ),
          Spacer(),
          Text(
            'Updated $minutesAgo min ago',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketIntelligenceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Voting Pattern Trends'),
          SizedBox(height: 2.h),
          _buildTrendChart(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Competitive Landscape'),
          SizedBox(height: 2.h),
          _buildCompetitiveInsights(),
          SizedBox(height: 3.h),
          _buildSectionTitle('User Engagement Metrics'),
          SizedBox(height: 2.h),
          _buildEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildSentimentTrackingTab() {
    final sentiment = _sentimentData['overall_sentiment'] as Map? ?? {};
    final positive = sentiment['positive'] ?? 50;
    final neutral = sentiment['neutral'] ?? 30;
    final negative = sentiment['negative'] ?? 20;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Real-Time Sentiment Analysis'),
          SizedBox(height: 2.h),
          _buildSentimentIndicators(positive, neutral, negative),
          SizedBox(height: 3.h),
          _buildSectionTitle('Demographic Breakdown'),
          SizedBox(height: 2.h),
          _buildDemographicBreakdown(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Brand Mentions'),
          SizedBox(height: 2.h),
          _buildBrandMentions(),
        ],
      ),
    );
  }

  Widget _buildFraudForecastingTab() {
    final forecast60d = _fraudForecast['forecast_60d'] as Map? ?? {};
    final probability = forecast60d['fraud_probability'] ?? 0.0;
    final confidence = forecast60d['confidence'] ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Predictive Fraud Models'),
          SizedBox(height: 2.h),
          _buildFraudPredictionCard(probability, confidence),
          SizedBox(height: 3.h),
          _buildSectionTitle('Risk Timeline Projections'),
          SizedBox(height: 2.h),
          _buildRiskTimeline(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Emerging Threats'),
          SizedBox(height: 2.h),
          _buildEmergingThreats(),
        ],
      ),
    );
  }

  Widget _buildStrategicPlanningTab() {
    final opportunities = _strategicPlan['market_opportunities'] as List? ?? [];
    final strategies = _strategicPlan['growth_strategies'] as List? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('AI-Assisted Decision Making'),
          SizedBox(height: 2.h),
          _buildDecisionWorkspace(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Market Opportunities'),
          SizedBox(height: 2.h),
          ...opportunities.take(3).map((opp) => _buildOpportunityCard(opp)),
          SizedBox(height: 3.h),
          _buildSectionTitle('Growth Strategies'),
          SizedBox(height: 2.h),
          ...strategies.take(3).map((strategy) => _buildStrategyCard(strategy)),
        ],
      ),
    );
  }

  Widget _buildUserEngagementTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Voting Session Heatmaps'),
          SizedBox(height: 2.h),
          _buildVotingHeatmap(),
          SizedBox(height: 3.h),
          _buildSectionTitle('User Retention Funnel'),
          SizedBox(height: 2.h),
          _buildRetentionFunnel(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Engagement Scoring'),
          SizedBox(height: 2.h),
          _buildEngagementScoring(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Churn Prediction'),
          SizedBox(height: 2.h),
          _buildChurnPrediction(),
          SizedBox(height: 3.h),
          _buildSectionTitle('Personalized Recommendations'),
          SizedBox(height: 2.h),
          _buildPersonalizedRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 3),
                FlSpot(1, 4),
                FlSpot(2, 3.5),
                FlSpot(3, 5),
                FlSpot(4, 4.5),
                FlSpot(5, 6),
              ],
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitiveInsights() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInsightRow('Market Leader', 'Vottery', '45%', Colors.green),
          Divider(height: 2.h),
          _buildInsightRow('Competitor A', 'Platform X', '30%', Colors.orange),
          Divider(height: 2.h),
          _buildInsightRow('Competitor B', 'Platform Y', '25%', Colors.red),
        ],
      ),
    );
  }

  Widget _buildInsightRow(
    String label,
    String name,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard('Active Users', '12.5K', Icons.people),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard('Avg. Session', '8.2 min', Icons.timer),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28.w, color: Colors.blue),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentIndicators(int positive, int neutral, int negative) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSentimentBar('Positive', positive, Colors.green),
          SizedBox(height: 2.h),
          _buildSentimentBar('Neutral', neutral, Colors.orange),
          SizedBox(height: 2.h),
          _buildSentimentBar('Negative', negative, Colors.red),
        ],
      ),
    );
  }

  Widget _buildSentimentBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value%',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildDemographicBreakdown() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDemographicRow('18-24', '25%'),
          Divider(height: 2.h),
          _buildDemographicRow('25-34', '35%'),
          Divider(height: 2.h),
          _buildDemographicRow('35-44', '20%'),
          Divider(height: 2.h),
          _buildDemographicRow('45+', '20%'),
        ],
      ),
    );
  }

  Widget _buildDemographicRow(String ageGroup, String percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          ageGroup,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandMentions() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Brand mention tracking available with real-time data',
        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildFraudPredictionCard(double probability, double confidence) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fraud Probability (60d)',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(probability * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: probability > 0.5 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskTimeline() {
    return Container(
      height: 20.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Risk timeline visualization',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmergingThreats() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildThreatRow('Velocity Anomalies', 'Medium', Colors.orange),
          Divider(height: 2.h),
          _buildThreatRow('Pattern Matching', 'Low', Colors.green),
          Divider(height: 2.h),
          _buildThreatRow('Geographic Clustering', 'High', Colors.red),
        ],
      ),
    );
  }

  Widget _buildThreatRow(String threat, String severity, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            threat,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            severity,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionWorkspace() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue, size: 20.w),
              SizedBox(width: 2.w),
              Text(
                'AI Recommendation',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Focus on user engagement campaigns to increase retention by 15%',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> opportunity) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            opportunity['opportunity'] ?? 'Market Opportunity',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Impact: ${opportunity['potential_impact'] ?? 0}%',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(Map<String, dynamic> strategy) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strategy['strategy'] ?? 'Growth Strategy',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Expected ROI: ${strategy['expected_ROI'] ?? 0}%',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingHeatmap() {
    final heatmapData = _generateHeatmapData();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peak Activity Hours',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 1.w,
                mainAxisSpacing: 1.h,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final intensity = heatmapData[index];
                return Container(
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(intensity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      intensity.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: intensity > 150 ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeatmapLegend('Low', Colors.blue.shade100),
              _buildHeatmapLegend('Medium', Colors.blue.shade300),
              _buildHeatmapLegend('High', Colors.blue.shade600),
              _buildHeatmapLegend('Peak', Colors.blue.shade900),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16.w,
          height: 16.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getHeatmapColor(int intensity) {
    if (intensity < 50) return Colors.blue.shade100;
    if (intensity < 100) return Colors.blue.shade300;
    if (intensity < 150) return Colors.blue.shade600;
    return Colors.blue.shade900;
  }

  List<int> _generateHeatmapData() {
    return List.generate(28, (index) => 20 + (index * 7) % 200);
  }

  Widget _buildRetentionFunnel() {
    final funnelStages = [
      {'stage': 'Registered Users', 'count': 10000, 'percentage': 100.0},
      {'stage': 'First Vote Cast', 'count': 7500, 'percentage': 75.0},
      {'stage': 'Second Vote', 'count': 5200, 'percentage': 52.0},
      {'stage': 'Active (5+ votes)', 'count': 3100, 'percentage': 31.0},
      {'stage': 'Power Users (20+)', 'count': 1200, 'percentage': 12.0},
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: funnelStages.asMap().entries.map((entry) {
          final index = entry.key;
          final stage = entry.value;
          final isLast = index == funnelStages.length - 1;

          return Column(
            children: [
              _buildFunnelStage(
                stage['stage'] as String,
                stage['count'] as int,
                stage['percentage'] as double,
              ),
              if (!isLast)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.grey.shade400,
                    size: 20.w,
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFunnelStage(String stage, int count, double percentage) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              stage,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementScoring() {
    final engagementMetrics = [
      {'metric': 'Vote Frequency', 'score': 8.5, 'trend': 'up'},
      {'metric': 'Session Duration', 'score': 7.2, 'trend': 'up'},
      {'metric': 'Social Sharing', 'score': 6.8, 'trend': 'down'},
      {'metric': 'Comment Activity', 'score': 7.9, 'trend': 'up'},
      {'metric': 'Return Rate', 'score': 8.1, 'trend': 'stable'},
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Engagement Score',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '7.7/10',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...engagementMetrics.map((metric) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: _buildEngagementMetricRow(
                metric['metric'] as String,
                metric['score'] as double,
                metric['trend'] as String,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEngagementMetricRow(String metric, double score, String trend) {
    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orange;
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            metric,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: score / 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          score.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 2.w),
        Icon(trendIcon, color: trendColor, size: 18.w),
      ],
    );
  }

  Widget _buildChurnPrediction() {
    final churnSegments = [
      {
        'segment': 'Low Risk',
        'users': 7200,
        'percentage': 72.0,
        'color': Colors.green,
      },
      {
        'segment': 'Medium Risk',
        'users': 2100,
        'percentage': 21.0,
        'color': Colors.orange,
      },
      {
        'segment': 'High Risk',
        'users': 700,
        'percentage': 7.0,
        'color': Colors.red,
      },
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24.w),
              SizedBox(width: 2.w),
              Text(
                'Churn Risk Analysis',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...churnSegments.map((segment) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: _buildChurnSegmentRow(
                segment['segment'] as String,
                segment['users'] as int,
                segment['percentage'] as double,
                segment['color'] as Color,
              ),
            );
          }),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue, size: 18.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Predicted 30-day churn rate: 5.2% (-1.3% from last month)',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.blue.shade700,
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

  Widget _buildChurnSegmentRow(
    String segment,
    int users,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                segment,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$users users',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizedRecommendations() {
    final recommendations = [
      {
        'title': 'Re-engagement Campaign',
        'description': 'Target 700 high-risk users with personalized content',
        'impact': 'High',
        'effort': 'Medium',
      },
      {
        'title': 'Gamification Boost',
        'description': 'Introduce achievement badges for consistent voters',
        'impact': 'Medium',
        'effort': 'Low',
      },
      {
        'title': 'Social Features',
        'description': 'Enable friend invites and voting together features',
        'impact': 'High',
        'effort': 'High',
      },
    ];

    return Column(
      children: recommendations.map((rec) {
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rec['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildImpactBadge(rec['impact'] as String),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                rec['description'] as String,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.work_outline, size: 14.w, color: Colors.grey),
                  SizedBox(width: 1.w),
                  Text(
                    'Effort: ${rec['effort']}',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImpactBadge(String impact) {
    Color color;
    switch (impact.toLowerCase()) {
      case 'high':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        impact,
        style: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
