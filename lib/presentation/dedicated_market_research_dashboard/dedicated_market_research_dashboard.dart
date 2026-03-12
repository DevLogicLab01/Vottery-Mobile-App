import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/perplexity_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class DedicatedMarketResearchDashboard extends StatefulWidget {
  const DedicatedMarketResearchDashboard({super.key});

  @override
  State<DedicatedMarketResearchDashboard> createState() =>
      _DedicatedMarketResearchDashboardState();
}

class _DedicatedMarketResearchDashboardState
    extends State<DedicatedMarketResearchDashboard> {
  final PerplexityService _perplexity = PerplexityService.instance;
  final AuthService _auth = AuthService.instance;
  final _client = SupabaseService.instance.client;

  bool _isLoading = false;
  Map<String, dynamic>? _sentimentData;
  Map<String, dynamic>? _competitiveIntelligence;
  Map<String, dynamic>? _trendForecasting;
  String _selectedBrand = '';
  String _timeRange = '30d';

  @override
  void initState() {
    super.initState();
    _loadMarketResearchData();
  }

  Future<void> _loadMarketResearchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final sentiment = await _perplexity.analyzeMarketSentiment(
        topic: _selectedBrand.isNotEmpty ? _selectedBrand : 'platform',
        category: 'brand_analysis',
      );

      final competitive = await _client.rpc(
        'get_competitive_intelligence',
        params: {'brand_name': _selectedBrand, 'time_range': _timeRange},
      );

      final trends = await _client.rpc(
        'get_trend_forecasting',
        params: {'brand_name': _selectedBrand},
      );

      if (mounted) {
        setState(() {
          _sentimentData = sentiment;
          _competitiveIntelligence = competitive;
          _trendForecasting = trends;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load market research error: $e');
      if (mounted) {
        setState(() {
          _sentimentData = _getMockSentimentData();
          _competitiveIntelligence = _getMockCompetitiveData();
          _trendForecasting = _getMockTrendData();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMockSentimentData() {
    return {
      'positive': 65.0,
      'neutral': 25.0,
      'negative': 10.0,
      'sentiment_score': 7.8,
      'trend': 'increasing',
    };
  }

  Map<String, dynamic> _getMockCompetitiveData() {
    return {
      'market_share': 32.5,
      'competitor_comparison': [
        {'name': 'Competitor A', 'share': 28.0},
        {'name': 'Competitor B', 'share': 22.0},
        {'name': 'Competitor C', 'share': 17.5},
      ],
    };
  }

  Map<String, dynamic> _getMockTrendData() {
    return {
      'predicted_growth': 15.5,
      'campaign_effectiveness': 8.2,
      'emerging_patterns': [
        'Increased mobile engagement',
        'Growing interest in sustainability',
        'Rising demand for personalization',
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Research Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarketResearchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  SizedBox(height: 2.h),
                  _buildSentimentAnalysis(),
                  SizedBox(height: 2.h),
                  _buildCompetitiveIntelligence(),
                  SizedBox(height: 2.h),
                  _buildTrendForecasting(),
                  SizedBox(height: 2.h),
                  _buildDemographicBreakdown(),
                  SizedBox(height: 2.h),
                  _buildBrandHealthScoring(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Research Filters',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Brand Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _selectedBrand = value),
            ),
            SizedBox(height: 1.h),
            DropdownButtonFormField<String>(
              initialValue: _timeRange,
              decoration: const InputDecoration(
                labelText: 'Time Range',
                border: OutlineInputBorder(),
              ),
              items: ['7d', '30d', '90d', '1y'].map((range) {
                return DropdownMenuItem(
                  value: range,
                  child: Text(_formatTimeRange(range)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _timeRange = value);
                  _loadMarketResearchData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentAnalysis() {
    if (_sentimentData == null) return const SizedBox();

    final positive = (_sentimentData!['positive'] ?? 0.0).toDouble();
    final neutral = (_sentimentData!['neutral'] ?? 0.0).toDouble();
    final negative = (_sentimentData!['negative'] ?? 0.0).toDouble();
    final score = (_sentimentData!['sentiment_score'] ?? 0.0).toDouble();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sentiment Analysis',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'Score: ${score.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildSentimentCard(
                    'Positive',
                    positive,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildSentimentCard('Neutral', neutral, Colors.orange),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildSentimentCard('Negative', negative, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCard(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitiveIntelligence() {
    if (_competitiveIntelligence == null) return const SizedBox();

    final marketShare = (_competitiveIntelligence!['market_share'] ?? 0.0)
        .toDouble();
    final competitors =
        _competitiveIntelligence!['competitor_comparison'] as List? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Competitive Intelligence',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text(
              'Your Market Share: ${marketShare.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1.5.h),
            ...competitors.map((comp) {
              final name = comp['name'] ?? 'Unknown';
              final share = (comp['share'] ?? 0.0).toDouble();
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(name, style: TextStyle(fontSize: 11.sp)),
                    ),
                    Expanded(
                      flex: 7,
                      child: LinearProgressIndicator(
                        value: share / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                        minHeight: 2.h,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${share.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendForecasting() {
    if (_trendForecasting == null) return const SizedBox();

    final growth = (_trendForecasting!['predicted_growth'] ?? 0.0).toDouble();
    final effectiveness = (_trendForecasting!['campaign_effectiveness'] ?? 0.0)
        .toDouble();
    final patterns = _trendForecasting!['emerging_patterns'] as List? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trend Forecasting',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Predicted Growth',
                    '+${growth.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Campaign Effectiveness',
                    '${effectiveness.toStringAsFixed(1)}/10',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Emerging Patterns:',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1.h),
            ...patterns.map((pattern) {
              return Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16.sp, color: Colors.blue),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        pattern.toString(),
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBreakdown() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demographic Breakdown',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildDemographicRow('18-24', 25.0, Colors.purple),
            _buildDemographicRow('25-34', 35.0, Colors.blue),
            _buildDemographicRow('35-44', 22.0, Colors.green),
            _buildDemographicRow('45+', 18.0, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicRow(String label, double value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          SizedBox(
            width: 15.w,
            child: Text(label, style: TextStyle(fontSize: 11.sp)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 2.h,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            '${value.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHealthScoring() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Health Score',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Center(
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '8.5',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'out of 10',
                        style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Strong brand performance with positive sentiment trajectory',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport() async {
    try {
      await _client.rpc(
        'generate_market_research_report',
        params: {
          'brand_name': _selectedBrand,
          'time_range': _timeRange,
          'format': 'pdf',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimeRange(String range) {
    switch (range) {
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 90 Days';
      case '1y':
        return 'Last Year';
      default:
        return range;
    }
  }
}
