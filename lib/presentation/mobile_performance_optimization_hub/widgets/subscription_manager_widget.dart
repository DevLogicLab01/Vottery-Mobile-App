import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../services/global_subscription_manager.dart';

class SubscriptionManagerWidget extends StatefulWidget {
  const SubscriptionManagerWidget({super.key});

  @override
  State<SubscriptionManagerWidget> createState() =>
      _SubscriptionManagerWidgetState();
}

class _SubscriptionManagerWidgetState extends State<SubscriptionManagerWidget> {
  final GlobalSubscriptionManager _manager = GlobalSubscriptionManager.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final networkQuality = _manager.networkQuality;
    final activeCount = _manager.activeSubscriptionCount;

    Color networkColor;
    String networkLabel;
    IconData networkIcon;

    switch (networkQuality) {
      case NetworkQuality.wifi:
        networkColor = const Color(0xFF10B981);
        networkLabel = 'WiFi - Real-time';
        networkIcon = Icons.wifi;
        break;
      case NetworkQuality.cellular:
        networkColor = const Color(0xFFF59E0B);
        networkLabel = 'Cellular - 5s Polling';
        networkIcon = Icons.signal_cellular_alt;
        break;
      case NetworkQuality.offline:
        networkColor = const Color(0xFFEF4444);
        networkLabel = 'Offline';
        networkIcon = Icons.wifi_off;
        break;
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub, color: AppTheme.vibrantYellow, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Global Subscription Manager',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: networkIcon,
                  label: 'Network',
                  value: networkLabel,
                  color: networkColor,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _MetricTile(
                  icon: Icons.subscriptions,
                  label: 'Active Channels',
                  value: '$activeCount',
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: networkColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: networkColor, size: 4.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    networkQuality == NetworkQuality.cellular
                        ? 'Switched to 5-second polling to save battery on cellular'
                        : networkQuality == NetworkQuality.offline
                        ? 'Offline mode - messages queued for sync'
                        : 'Real-time subscriptions active - batched within 200ms',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: networkColor,
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
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 4.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
