import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StrategyComparisonWidget extends StatelessWidget {
  final List<Map<String, dynamic>> strategies;

  const StrategyComparisonWidget({super.key, required this.strategies});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ranking Strategy Performance',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          strategies.isEmpty
              ? Center(
                  child: Text(
                    'No strategy data available',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                )
              : Column(
                  children: strategies
                      .map((strategy) => _buildStrategyCard(strategy))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(Map<String, dynamic> strategy) {
    final strategyName = strategy['strategy_name'] ?? 'Unknown';
    final testGroup = strategy['test_group'] ?? 'unknown';
    final avgScore = strategy['avg_ranking_score'] ?? 0.0;
    final satisfactionScore = strategy['user_satisfaction_score'] ?? 0.0;
    final significance = strategy['statistical_significance'] ?? 0.0;
    final sampleSize = strategy['sample_size'] ?? 0;

    final groupColor = _getGroupColor(testGroup);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strategyName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: groupColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: groupColor),
                ),
                child: Text(
                  testGroup.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: groupColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  'Avg Score',
                  avgScore.toStringAsFixed(2),
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Satisfaction',
                  '${(satisfactionScore * 100).toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  'Significance',
                  '${(significance * 100).toStringAsFixed(1)}%',
                ),
              ),
              Expanded(
                child: _buildMetricColumn('Sample', sampleSize.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case 'control':
        return Colors.grey;
      case 'algorithm_v1':
        return Colors.blue;
      case 'algorithm_v2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
