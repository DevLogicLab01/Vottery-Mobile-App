import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DatabaseMonitoringWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const DatabaseMonitoringWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final connectionPoolUsage = metrics['connection_pool_usage'] ?? 0.0;
    final slowQueriesCount = metrics['slow_queries_count'] ?? 0;
    final missingIndexes = metrics['missing_indexes'] ?? 0;
    final tableBloat = metrics['table_bloat_percentage'] ?? 0.0;
    final indexRecommendations =
        metrics['index_recommendations'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Database Health',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.storage,
                  label: 'Connection Pool',
                  value: '${connectionPoolUsage.toStringAsFixed(1)}%',
                  color: _getPoolUsageColor(connectionPoolUsage),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.hourglass_empty,
                  label: 'Slow Queries',
                  value: slowQueriesCount.toString(),
                  color: slowQueriesCount > 20 ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.warning_amber,
                  label: 'Missing Indexes',
                  value: missingIndexes.toString(),
                  color: missingIndexes > 3 ? Colors.red : Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.pie_chart,
                  label: 'Table Bloat',
                  value: '${tableBloat.toStringAsFixed(1)}%',
                  color: tableBloat > 15 ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Index Recommendations',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          if (indexRecommendations.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 12.w,
                      color: Colors.green.withAlpha(128),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'All indexes optimized',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...indexRecommendations.map((rec) {
              return _buildIndexRecommendationCard(rec as Map<String, dynamic>);
            }),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 6.w, color: color),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexRecommendationCard(Map<String, dynamic> recommendation) {
    final table = recommendation['table'] ?? '';
    final columns = recommendation['columns'] as List<dynamic>? ?? [];
    final type = recommendation['type'] ?? '';
    final impact = recommendation['impact'] ?? 'low';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getImpactColor(impact).withAlpha(77),
          width: 1.5,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart,
                      size: 5.w,
                      color: AppTheme.primaryLight,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        table,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getImpactColor(impact),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${impact.toUpperCase()} IMPACT',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Index Type: ',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _formatType(type),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.view_column,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Columns: ',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        columns.join(', '),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue.withAlpha(51), width: 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 4.w, color: Colors.blue),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _generateIndexSQL(table, columns, type),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'monospace',
                      color: AppTheme.textPrimaryLight,
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

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _generateIndexSQL(String table, List<dynamic> columns, String type) {
    final columnList = columns.join(', ');
    return 'CREATE INDEX idx_${table}_${columns.join('_')} ON $table ($columnList);';
  }

  Color _getPoolUsageColor(double usage) {
    if (usage < 60) return Colors.green;
    if (usage < 80) return Colors.orange;
    return Colors.red;
  }

  Color _getImpactColor(String impact) {
    switch (impact.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
