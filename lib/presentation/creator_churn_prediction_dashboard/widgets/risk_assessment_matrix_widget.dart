import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/creator_churn_prediction_service.dart';

class RiskAssessmentMatrixWidget extends StatelessWidget {
  final List<ChurnPrediction> predictions;
  final String selectedRiskFilter;
  final ValueChanged<String> onFilterChanged;

  const RiskAssessmentMatrixWidget({
    super.key,
    required this.predictions,
    required this.selectedRiskFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final riskLevels = ['all', 'critical', 'high', 'medium', 'low'];

    final criticalCount = predictions
        .where((p) => p.riskLevel == 'critical')
        .length;
    final highCount = predictions.where((p) => p.riskLevel == 'high').length;
    final mediumCount = predictions
        .where((p) => p.riskLevel == 'medium')
        .length;
    final lowCount = predictions.where((p) => p.riskLevel == 'low').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Risk level summary cards
        Row(
          children: [
            _RiskCountCard(
              label: 'Critical',
              count: criticalCount,
              color: const Color(0xFFEF4444),
            ),
            SizedBox(width: 2.w),
            _RiskCountCard(
              label: 'High',
              count: highCount,
              color: const Color(0xFFF97316),
            ),
            SizedBox(width: 2.w),
            _RiskCountCard(
              label: 'Medium',
              count: mediumCount,
              color: const Color(0xFFF59E0B),
            ),
            SizedBox(width: 2.w),
            _RiskCountCard(
              label: 'Low',
              count: lowCount,
              color: const Color(0xFF10B981),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: riskLevels.map((level) {
              final isSelected = selectedRiskFilter == level;
              final color = _getRiskColor(level);
              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: GestureDetector(
                  onTap: () => onFilterChanged(level),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withAlpha(26),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: color.withOpacity(isSelected ? 1.0 : 0.3),
                      ),
                    ),
                    child: Text(
                      level == 'all' ? 'All Risks' : level.capitalize(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _RiskCountCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RiskCountCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.sp,
                color: color.withAlpha(204),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
