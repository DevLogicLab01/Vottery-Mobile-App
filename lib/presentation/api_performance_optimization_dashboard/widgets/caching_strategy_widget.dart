import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CachingStrategyWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;

  const CachingStrategyWidget({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 15.w,
              color: Colors.green.withAlpha(128),
            ),
            SizedBox(height: 2.h),
            Text(
              'All endpoints optimally cached',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return _buildRecommendationCard(recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final endpoint = recommendation['endpoint'] ?? '';
    final cacheType = recommendation['cache_type'] ?? '';
    final ttlSeconds = recommendation['ttl_seconds'] ?? 0;
    final hitRateProjection = recommendation['hit_rate_projection'] ?? 0.0;
    final latencyReduction = recommendation['latency_reduction'] ?? 0;
    final costSavings = recommendation['cost_savings'] ?? 0;
    final priority = recommendation['priority'] ?? 'low';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getPriorityColor(priority).withAlpha(77),
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
                child: Text(
                  endpoint,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  priority.toUpperCase(),
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
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight.withAlpha(26),
                  AppTheme.primaryLight.withAlpha(13),
                ],
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  _getCacheTypeIcon(cacheType),
                  size: 6.w,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 2.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended Cache Type',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      cacheType,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TTL',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      _formatTTL(ttlSeconds),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Projected Impact',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildImpactMetric(
                  icon: Icons.trending_up,
                  label: 'Hit Rate',
                  value: '${hitRateProjection.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildImpactMetric(
                  icon: Icons.speed,
                  label: 'Latency ↓',
                  value: '$latencyReduction%',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildImpactMetric(
                  icon: Icons.attach_money,
                  label: 'Savings',
                  value: '\$$costSavings/mo',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.green.withAlpha(51), width: 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 4.w, color: Colors.green),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _getCacheDescription(cacheType),
                    style: TextStyle(
                      fontSize: 11.sp,
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

  Widget _buildImpactMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, size: 5.w, color: color),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 0.3.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getCacheTypeIcon(String cacheType) {
    switch (cacheType.toLowerCase()) {
      case 'redis':
        return Icons.storage;
      case 'in-memory':
        return Icons.memory;
      case 'cdn':
        return Icons.cloud;
      default:
        return Icons.cached;
    }
  }

  String _formatTTL(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).toInt()}m';
    return '${(seconds / 3600).toInt()}h';
  }

  String _getCacheDescription(String cacheType) {
    switch (cacheType.toLowerCase()) {
      case 'redis':
        return 'Distributed cache for frequently accessed data with automatic invalidation';
      case 'in-memory':
        return 'Fast local cache for real-time data with low latency requirements';
      case 'cdn':
        return 'Edge caching for static content with global distribution';
      default:
        return 'Optimized caching strategy for improved performance';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
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
