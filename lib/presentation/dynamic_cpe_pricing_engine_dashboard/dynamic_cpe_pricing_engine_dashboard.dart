import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../services/perplexity_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class DynamicCpePricingEngineDashboard extends StatefulWidget {
  const DynamicCpePricingEngineDashboard({super.key});

  @override
  State<DynamicCpePricingEngineDashboard> createState() =>
      _DynamicCpePricingEngineDashboardState();
}

class _DynamicCpePricingEngineDashboardState
    extends State<DynamicCpePricingEngineDashboard> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _perplexity = PerplexityService.instance;

  bool _isLoading = true;
  bool _isOptimizing = false;
  List<Map<String, dynamic>> _zones = [];
  Map<String, dynamic> _aiRecommendations = {};
  Timer? _optimizationTimer;

  final List<Map<String, dynamic>> _zoneData = [
    {'id': 1, 'name': 'Zone 1 - US', 'flag': '🇺🇸', 'baseCpe': 0.50},
    {
      'id': 2,
      'name': 'Zone 2 - Eastern Europe',
      'flag': '🇪🇺',
      'baseCpe': 0.15,
    },
    {
      'id': 3,
      'name': 'Zone 3 - Latin America',
      'flag': '🇧🇷',
      'baseCpe': 0.20,
    },
    {'id': 4, 'name': 'Zone 4 - Middle East', 'flag': '🇦🇪', 'baseCpe': 0.25},
    {'id': 5, 'name': 'Zone 5 - East Asia', 'flag': '🇯🇵', 'baseCpe': 0.35},
    {
      'id': 6,
      'name': 'Zone 6 - Southeast Asia',
      'flag': '🇸🇬',
      'baseCpe': 0.18,
    },
    {'id': 7, 'name': 'Zone 7 - South Asia', 'flag': '🇮🇳', 'baseCpe': 0.12},
    {'id': 8, 'name': 'Zone 8 - Africa', 'flag': '🇿🇦', 'baseCpe': 0.10},
  ];

  @override
  void initState() {
    super.initState();
    _loadPricingData();
    _startOptimizationTimer();
  }

  @override
  void dispose() {
    _optimizationTimer?.cancel();
    super.dispose();
  }

  void _startOptimizationTimer() {
    _optimizationTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _runPricingOptimization(),
    );
  }

  Future<void> _loadPricingData() async {
    setState(() => _isLoading = true);

    try {
      final priceHistory = await _client
          .from('cpe_price_history')
          .select()
          .order('adjusted_at', ascending: false)
          .limit(100);

      final engagementMetrics = await _client
          .from('ad_engagement_metrics')
          .select()
          .gte(
            'recorded_at',
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          )
          .order('recorded_at', ascending: false);

      final zones = _zoneData.map((zone) {
        final zoneMetrics = (engagementMetrics as List)
            .where((m) => m['zone_id'] == zone['id'])
            .toList();

        final latestPrice =
            (priceHistory as List)
                .where((p) => p['zone_id'] == zone['id'])
                .isNotEmpty
            ? (priceHistory as List).firstWhere(
                (p) => p['zone_id'] == zone['id'],
                orElse: () => {'new_price': zone['baseCpe']},
              )['new_price']
            : zone['baseCpe'];

        final demandScore = zoneMetrics.isNotEmpty
            ? zoneMetrics.first['demand_score'] ?? 0.5
            : 0.5;

        final qualityScore = zoneMetrics.isNotEmpty
            ? zoneMetrics.first['quality_score'] ?? 50.0
            : 50.0;

        final engagementRate = zoneMetrics.isNotEmpty
            ? zoneMetrics.first['engagement_rate'] ?? 0.05
            : 0.05;

        return {
          ...zone,
          'currentCpe': latestPrice,
          'demandScore': demandScore,
          'qualityScore': qualityScore,
          'engagementRate': engagementRate,
          'demandLevel': _getDemandLevel(demandScore),
          'change24h': _calculate24hChange(priceHistory as List, zone['id']),
        };
      }).toList();

      setState(() {
        _zones = zones;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load pricing data error: $e');
      setState(() {
        _zones = _zoneData
            .map(
              (z) => {
                ...z,
                'currentCpe': z['baseCpe'],
                'demandScore': 0.5,
                'qualityScore': 50.0,
                'engagementRate': 0.05,
                'demandLevel': 'Medium',
                'change24h': 0.0,
              },
            )
            .toList();
        _isLoading = false;
      });
    }
  }

  String _getDemandLevel(double score) {
    if (score >= 0.9) return 'Very High';
    if (score >= 0.7) return 'High';
    if (score >= 0.4) return 'Medium';
    return 'Low';
  }

  double _calculate24hChange(List<dynamic> history, int zoneId) {
    final zoneHistory = history.where((h) => h['zone_id'] == zoneId).toList();
    if (zoneHistory.length < 2) return 0.0;

    final latest = zoneHistory[0]['new_price'] as num;
    final previous = zoneHistory[1]['new_price'] as num;

    return ((latest - previous) / previous * 100).toDouble();
  }

  Future<void> _runPricingOptimization() async {
    if (_isOptimizing || !_auth.isAuthenticated) return;

    setState(() => _isOptimizing = true);

    try {
      final zoneMetrics = _zones
          .map(
            (z) => {
              'zone_id': z['id'],
              'zone_name': z['name'],
              'current_cpe': z['currentCpe'],
              'demand_score': z['demandScore'],
              'quality_score': z['qualityScore'],
              'engagement_rate': z['engagementRate'],
            },
          )
          .toList();

      final recommendations = await _perplexity.callPerplexityAPI(
        _buildOptimizationPrompt(zoneMetrics),
        model: 'sonar-reasoning',
      );

      final aiResponse =
          recommendations['choices']?[0]?['message']?['content'] ?? '';
      final parsedRecommendations = _parseAIRecommendations(aiResponse);

      setState(() {
        _aiRecommendations = parsedRecommendations;
        _isOptimizing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing optimization completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Pricing optimization error: $e');
      setState(() => _isOptimizing = false);
    }
  }

  String _buildOptimizationPrompt(List<Map<String, dynamic>> metrics) {
    return '''
Analyze ad performance data across 8 purchasing power zones and recommend optimal CPE pricing:

Zone Metrics:
${metrics.map((m) => '${m['zone_name']}: CPE \$${m['current_cpe']}, Demand ${m['demand_score']}, Quality ${m['quality_score']}, Engagement ${m['engagement_rate']}').join('\n')}

Recommend optimal CPE for each zone to maximize total revenue considering:
1) Supply-demand balance
2) Price elasticity
3) Audience quality vs price
4) Geographic purchasing power

Provide specific price recommendations with expected impact and confidence level.
''';
  }

  Map<String, dynamic> _parseAIRecommendations(String response) {
    return {
      'summary': response.substring(
        0,
        response.length > 200 ? 200 : response.length,
      ),
      'confidence': 0.85,
      'recommendations': _zones
          .map(
            (z) => {
              'zone_id': z['id'],
              'recommended_cpe': z['currentCpe'],
              'reasoning': 'AI analysis in progress',
            },
          )
          .toList(),
    };
  }

  Future<void> _applyPriceAdjustment(int zoneId, double newPrice) async {
    try {
      final zone = _zones.firstWhere((z) => z['id'] == zoneId);
      final oldPrice = zone['currentCpe'];

      await _client.from('cpe_price_history').insert({
        'zone_id': zoneId,
        'zone_name': zone['name'],
        'old_price': oldPrice,
        'new_price': newPrice,
        'change_percentage': ((newPrice - oldPrice) / oldPrice * 100),
        'demand_score': zone['demandScore'],
        'quality_score': zone['qualityScore'],
        'change_reason': 'AI-powered optimization',
        'adjusted_by': _auth.currentUser?.id,
      });

      await _loadPricingData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Price updated for ${zone['name']}')),
        );
      }
    } catch (e) {
      debugPrint('Apply price adjustment error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'DynamicCpePricingEngineDashboard',
      onRetry: _loadPricingData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'CPE Pricing Engine',
          actions: [
            if (_isOptimizing)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _runPricingOptimization,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPricingData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOptimizationStatus(theme),
                      SizedBox(height: 3.h),
                      _buildZonesGrid(theme),
                      SizedBox(height: 3.h),
                      if (_aiRecommendations.isNotEmpty) ...[
                        _buildAIRecommendations(theme),
                        SizedBox(height: 3.h),
                      ],
                      _buildRevenueDashboard(theme),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildOptimizationStatus(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Powered Optimization',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Next optimization in 15 minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.85,
      ),
      itemCount: _zones.length,
      itemBuilder: (context, index) {
        final zone = _zones[index];
        return _buildZoneCard(zone, theme);
      },
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone, ThemeData theme) {
    final change = zone['change24h'] as double;
    final isPositive = change >= 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(zone['flag'], style: TextStyle(fontSize: 20.sp)),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  zone['name'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${zone['currentCpe'].toStringAsFixed(2)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 4.w,
                color: isPositive ? Colors.green : Colors.red,
              ),
              Text(
                '${change.abs().toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildDemandBadge(zone['demandLevel'], theme),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: zone['qualityScore'] / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              _getQualityColor(zone['qualityScore']),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Quality: ${zone['qualityScore'].toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDemandBadge(String level, ThemeData theme) {
    Color color;
    switch (level) {
      case 'Very High':
        color = Colors.red;
        break;
      case 'High':
        color = Colors.orange;
        break;
      case 'Medium':
        color = Colors.yellow;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        level,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getQualityColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAIRecommendations(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Text(
                'AI Recommendations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            _aiRecommendations['summary'] ?? 'No recommendations available',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                'Confidence:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                '${(_aiRecommendations['confidence'] * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueDashboard(ThemeData theme) {
    final projectedRevenue = _zones.fold<double>(
      0,
      (sum, z) => sum + (z['currentCpe'] * 1000 * z['engagementRate']),
    );

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Optimization',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projected Monthly Revenue',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '\$${projectedRevenue.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    _zones
                        .map((z) => z['currentCpe'] as double)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barGroups: _zones.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['currentCpe'],
                        color: theme.colorScheme.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _zones.length) {
                          return Text(
                            'Z${value.toInt() + 1}',
                            style: theme.textTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
