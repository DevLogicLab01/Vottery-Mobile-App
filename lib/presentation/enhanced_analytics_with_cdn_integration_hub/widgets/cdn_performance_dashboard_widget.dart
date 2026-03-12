import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CDNPerformanceDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const CDNPerformanceDashboardWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageOpt = metrics['image_optimization'] ?? {};
    final videoOpt = metrics['video_optimization'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CDN Performance Dashboard',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),

        // Image Delivery Optimization
        _buildOptimizationCard(
          theme,
          'Image Delivery Optimization',
          Icons.image,
          [
            _buildMetricRow(
              theme,
              'WebP Conversions',
              '${imageOpt['webp_conversions'] ?? 0}',
            ),
            _buildMetricRow(
              theme,
              'AVIF Conversions',
              '${imageOpt['avif_conversions'] ?? 0}',
            ),
            _buildMetricRow(
              theme,
              'Size Reduction',
              '${imageOpt['size_reduction'] ?? 0}%',
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Video Delivery Optimization
        _buildOptimizationCard(
          theme,
          'Video Delivery Optimization',
          Icons.video_library,
          [
            _buildMetricRow(
              theme,
              'Adaptive Bitrate Streams',
              '${videoOpt['adaptive_bitrate_streams'] ?? 0}',
            ),
            _buildMetricRow(
              theme,
              'Geo-Distributed Cache',
              videoOpt['geo_distributed_cache'] == true
                  ? 'Enabled'
                  : 'Disabled',
            ),
            _buildMetricRow(
              theme,
              'Avg Startup Time',
              '${videoOpt['avg_startup_time'] ?? 0}s',
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Performance Metrics
        _buildPerformanceMetrics(theme),
      ],
    );
  }

  Widget _buildOptimizationCard(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              SizedBox(width: 3.w),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(ThemeData theme) {
    final bandwidthSaved = metrics['bandwidth_saved'] ?? 0.0;
    final requestsServed = metrics['requests_served'] ?? 0;
    final avgResponseTime = metrics['avg_response_time'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Bandwidth Saved',
                  '${bandwidthSaved.toStringAsFixed(1)} GB',
                  Icons.save,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Requests Served',
                  '${(requestsServed / 1000000).toStringAsFixed(1)}M',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildStatCard(
            theme,
            'Avg Response Time',
            '${avgResponseTime}ms',
            Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  label,
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
}
