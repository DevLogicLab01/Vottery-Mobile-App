import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Adaptive Strategy Widget
/// Displays network-based frequency adjustment configuration
class AdaptiveStrategyWidget extends StatelessWidget {
  final String networkQuality;
  final String syncStrategy;
  final bool isOnline;

  const AdaptiveStrategyWidget({
    super.key,
    required this.networkQuality,
    required this.syncStrategy,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adaptive Sync Strategy',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Sync frequency adjusts automatically based on network quality',
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
          ),
          SizedBox(height: 3.h),
          _buildCurrentStatus(theme),
          SizedBox(height: 3.h),
          Text(
            'Strategy Configuration',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildStrategyCard(
            'WiFi',
            'Real-time',
            'Instant sync for all changes',
            Icons.wifi,
            Colors.green,
            networkQuality == 'wifi',
            theme,
          ),
          _buildStrategyCard(
            '4G',
            'Every 30 seconds',
            'Frequent sync with minimal delay',
            Icons.signal_cellular_4_bar,
            Colors.blue,
            networkQuality == '4g',
            theme,
          ),
          _buildStrategyCard(
            '3G',
            'Every 5 minutes',
            'Balanced sync for slower connections',
            Icons.signal_cellular_alt,
            Colors.orange,
            networkQuality == '3g',
            theme,
          ),
          _buildStrategyCard(
            '2G / Offline',
            'Manual only',
            'Sync when you trigger it manually',
            Icons.signal_cellular_off,
            Colors.red,
            networkQuality == '2g' || networkQuality == 'offline',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withAlpha(179),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Status',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                isOnline ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatNetworkQuality(networkQuality),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Strategy: ${_formatSyncStrategy(syncStrategy)}',
                      style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(
    String network,
    String frequency,
    String description,
    IconData icon,
    Color color,
    bool isActive,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(26) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive ? color : theme.colorScheme.outline.withAlpha(51),
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      network,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isActive) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  frequency,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNetworkQuality(String quality) {
    switch (quality) {
      case 'wifi':
        return 'WiFi Connection';
      case '4g':
        return '4G Connection';
      case '3g':
        return '3G Connection';
      case '2g':
        return '2G Connection';
      default:
        return 'Offline';
    }
  }

  String _formatSyncStrategy(String strategy) {
    switch (strategy) {
      case 'realtime':
        return 'Real-time';
      case 'interval_30s':
        return 'Every 30 seconds';
      case 'interval_5min':
        return 'Every 5 minutes';
      default:
        return 'Manual only';
    }
  }
}
