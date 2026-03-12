import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';

class ErrorAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const ErrorAnalyticsWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalErrors = analytics['totalErrors'] as int? ?? 0;
    final errorCounts = analytics['errorCounts'] as Map<String, dynamic>? ?? {};
    final errorRates = analytics['errorRates'] as Map<String, dynamic>? ?? {};

    if (totalErrors == 0) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 15.w),
              SizedBox(height: 2.h),
              Text(
                'No Errors Detected',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'All verifications successful in the last 30 days',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCard(theme, totalErrors),
        SizedBox(height: 2.h),
        _buildErrorBreakdown(theme, errorCounts, errorRates),
        SizedBox(height: 2.h),
        _buildErrorChart(theme, errorCounts),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme, int totalErrors) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  totalErrors.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Total Errors',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Container(
              height: 6.h,
              width: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            Column(
              children: [
                Text(
                  '30 Days',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Time Period',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBreakdown(
    ThemeData theme,
    Map<String, dynamic> errorCounts,
    Map<String, dynamic> errorRates,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            ...errorCounts.entries.map(
              (entry) => _buildErrorRow(
                theme,
                entry.key,
                entry.value as int,
                errorRates[entry.key] as int? ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorRow(
    ThemeData theme,
    String errorType,
    int count,
    int rate,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _formatErrorType(errorType),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count ($rate%)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11.sp,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: rate / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorChart(ThemeData theme, Map<String, dynamic> errorCounts) {
    if (errorCounts.isEmpty) return const SizedBox.shrink();

    final pieChartData = errorCounts.entries.map((entry) {
      return PieChartSectionData(
        value: (entry.value as int).toDouble(),
        title: '${entry.value}',
        color: _getErrorColor(entry.key),
        radius: 15.w,
        titleStyle: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 40.w,
              child: PieChart(
                PieChartData(
                  sections: pieChartData,
                  sectionsSpace: 2,
                  centerSpaceRadius: 10.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatErrorType(String errorType) {
    return errorType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getErrorColor(String errorType) {
    switch (errorType) {
      case 'rsaDecryptionFailure':
        return Colors.orange;
      case 'blockchainTimeout':
        return Colors.blue;
      case 'invalidHash':
        return Colors.red;
      case 'networkError':
        return Colors.purple;
      case 'verificationFailed':
        return Colors.deepOrange;
      case 'expiredCertificate':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
