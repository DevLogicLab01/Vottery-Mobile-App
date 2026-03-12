import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CostEfficiencyTrackingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentAnalyses;

  const CostEfficiencyTrackingWidget({super.key, required this.recentAnalyses});

  @override
  Widget build(BuildContext context) {
    final costMetrics = _calculateCostMetrics();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Efficiency Tracking',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildCostCard(
                  'Total Cost',
                  '\$${costMetrics["total_cost"].toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildCostCard(
                  'Cost per Analysis',
                  '\$${costMetrics["cost_per_analysis"].toStringAsFixed(4)}',
                  Icons.analytics,
                  Colors.purple,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Cost Breakdown by Model',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCostBreakdownChart(costMetrics['model_costs']),
          SizedBox(height: 3.h),
          Text(
            'Model Cost Details',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildModelCostCard(
            'Claude Sonnet 4.5',
            costMetrics['claude_cost'],
            costMetrics['claude_count'],
            Colors.purple,
          ),
          SizedBox(height: 1.h),
          _buildModelCostCard(
            'Perplexity Sonar',
            costMetrics['perplexity_cost'],
            costMetrics['perplexity_count'],
            Colors.blue,
          ),
          SizedBox(height: 1.h),
          _buildModelCostCard(
            'OpenAI GPT-4o',
            costMetrics['openai_cost'],
            costMetrics['openai_count'],
            Colors.green,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateCostMetrics() {
    const claudeCostPer1K = 0.015;
    const perplexityCostPer1K = 0.005;
    const openaiCostPer1K = 0.01;

    double claudeCost = 0.0;
    double perplexityCost = 0.0;
    double openaiCost = 0.0;
    int claudeCount = 0;
    int perplexityCount = 0;
    int openaiCount = 0;

    for (var analysis in recentAnalyses) {
      final aiResults = analysis['ai_results'] as List<dynamic>? ?? [];
      for (var result in aiResults) {
        if (result is Map<String, dynamic>) {
          final service = result['ai_service'] as String?;
          final tokens = (result['tokens_used'] as num?)?.toDouble() ?? 1000.0;

          switch (service) {
            case 'claude':
              claudeCost += (tokens / 1000) * claudeCostPer1K;
              claudeCount++;
              break;
            case 'perplexity':
              perplexityCost += (tokens / 1000) * perplexityCostPer1K;
              perplexityCount++;
              break;
            case 'openai':
              openaiCost += (tokens / 1000) * openaiCostPer1K;
              openaiCount++;
              break;
          }
        }
      }
    }

    final totalCost = claudeCost + perplexityCost + openaiCost;
    final totalCount = recentAnalyses.length;
    final costPerAnalysis = totalCount > 0 ? totalCost / totalCount : 0.0;

    return {
      'total_cost': totalCost,
      'cost_per_analysis': costPerAnalysis,
      'claude_cost': claudeCost,
      'perplexity_cost': perplexityCost,
      'openai_cost': openaiCost,
      'claude_count': claudeCount,
      'perplexity_count': perplexityCount,
      'openai_count': openaiCount,
      'model_costs': {
        'Claude': claudeCost,
        'Perplexity': perplexityCost,
        'OpenAI': openaiCost,
      },
    };
  }

  Widget _buildCostCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
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
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownChart(Map<String, dynamic> modelCosts) {
    final totalCost = modelCosts.values.fold<double>(
      0.0,
      (sum, cost) => sum + (cost as num).toDouble(),
    );

    if (totalCost == 0) {
      return Container(
        height: 25.h,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No cost data available',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 25.h,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: (modelCosts['Claude'] as num).toDouble(),
                    title:
                        '${((modelCosts['Claude'] as num).toDouble() / totalCost * 100).toStringAsFixed(0)}%',
                    color: Colors.purple,
                    radius: 15.w,
                    titleStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (modelCosts['Perplexity'] as num).toDouble(),
                    title:
                        '${((modelCosts['Perplexity'] as num).toDouble() / totalCost * 100).toStringAsFixed(0)}%',
                    color: Colors.blue,
                    radius: 15.w,
                    titleStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (modelCosts['OpenAI'] as num).toDouble(),
                    title:
                        '${((modelCosts['OpenAI'] as num).toDouble() / totalCost * 100).toStringAsFixed(0)}%',
                    color: Colors.green,
                    radius: 15.w,
                    titleStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 8.w,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  'Claude',
                  Colors.purple,
                  '\$${(modelCosts['Claude'] as num).toDouble().toStringAsFixed(2)}',
                ),
                SizedBox(height: 1.h),
                _buildLegendItem(
                  'Perplexity',
                  Colors.blue,
                  '\$${(modelCosts['Perplexity'] as num).toDouble().toStringAsFixed(2)}',
                ),
                SizedBox(height: 1.h),
                _buildLegendItem(
                  'OpenAI',
                  Colors.green,
                  '\$${(modelCosts['OpenAI'] as num).toDouble().toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String cost) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                cost,
                style: TextStyle(
                  fontSize: 8.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelCostCard(
    String modelName,
    double cost,
    int count,
    Color color,
  ) {
    final costPerCall = count > 0 ? cost / count : 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            width: 1.w,
            height: 8.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$count API calls',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${cost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '\$${costPerCall.toStringAsFixed(4)}/call',
                style: TextStyle(
                  fontSize: 8.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
