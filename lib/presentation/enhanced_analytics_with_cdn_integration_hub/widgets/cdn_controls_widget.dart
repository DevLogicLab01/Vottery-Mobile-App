import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CDNControlsWidget extends StatelessWidget {
  final Function(String) onOptimize;

  const CDNControlsWidget({super.key, required this.onOptimize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              Icon(Icons.settings, color: theme.colorScheme.primary, size: 24),
              SizedBox(width: 3.w),
              Text(
                'CDN Optimization Controls',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Format Conversion Settings
          _buildControlSection(theme, 'Format Conversion', [
            _buildControlButton(
              theme,
              'Enable WebP',
              Icons.image,
              () => onOptimize('webp'),
            ),
            _buildControlButton(
              theme,
              'Enable AVIF',
              Icons.high_quality,
              () => onOptimize('avif'),
            ),
          ]),

          SizedBox(height: 2.h),

          // Cache Optimization
          _buildControlSection(theme, 'Cache Optimization', [
            _buildControlButton(
              theme,
              'Purge Cache',
              Icons.delete_sweep,
              () => onOptimize('purge_cache'),
            ),
            _buildControlButton(
              theme,
              'Optimize TTL',
              Icons.timer,
              () => onOptimize('optimize_ttl'),
            ),
          ]),

          SizedBox(height: 2.h),

          // Edge Location Management
          _buildControlSection(theme, 'Edge Location Management', [
            _buildControlButton(
              theme,
              'View Locations',
              Icons.location_on,
              () => onOptimize('view_locations'),
            ),
            _buildControlButton(
              theme,
              'Performance Monitor',
              Icons.monitor,
              () => onOptimize('monitor'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildControlSection(
    ThemeData theme,
    String title,
    List<Widget> buttons,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(spacing: 2.w, runSpacing: 1.h, children: buttons),
      ],
    );
  }

  Widget _buildControlButton(
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
