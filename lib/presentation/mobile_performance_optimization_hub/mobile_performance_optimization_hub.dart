import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/global_subscription_manager.dart';
import '../../services/message_queue_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/deferred_loading_manager_widget.dart';
import './widgets/offline_message_queue_widget.dart';
import './widgets/subscription_manager_widget.dart';

class MobilePerformanceOptimizationHub extends StatefulWidget {
  const MobilePerformanceOptimizationHub({super.key});

  @override
  State<MobilePerformanceOptimizationHub> createState() =>
      _MobilePerformanceOptimizationHubState();
}

class _MobilePerformanceOptimizationHubState
    extends State<MobilePerformanceOptimizationHub> {
  final GlobalSubscriptionManager _subscriptionManager =
      GlobalSubscriptionManager.instance;
  final MessageQueueService _messageQueueService = MessageQueueService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'MobilePerformanceOptimizationHub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Performance Hub',
        ),
        body: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            // Status Overview
            _buildStatusOverview(theme),
            SizedBox(height: 2.h),

            // Deferred Loading Manager
            const DeferredLoadingManagerWidget(),
            SizedBox(height: 2.h),

            // Global Subscription Manager
            const SubscriptionManagerWidget(),
            SizedBox(height: 2.h),

            // Network Optimization Panel
            _buildNetworkOptimizationPanel(theme),
            SizedBox(height: 2.h),

            // Offline Message Queue
            const OfflineMessageQueueWidget(),
            SizedBox(height: 2.h),

            // Performance Tips
            _buildPerformanceTips(theme),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverview(ThemeData theme) {
    final networkQuality = _subscriptionManager.networkQuality;
    final activeChannels = _subscriptionManager.activeSubscriptionCount;
    final queuedMessages = _messageQueueService.queuedCount;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withAlpha(26),
            const Color(0xFF8B5CF6).withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF3B82F6).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: const Color(0xFF3B82F6), size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Performance Status',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  'OPTIMIZED',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  label: 'Network',
                  value: networkQuality == NetworkQuality.wifi
                      ? 'WiFi'
                      : networkQuality == NetworkQuality.cellular
                      ? 'Cellular'
                      : 'Offline',
                  icon: networkQuality == NetworkQuality.wifi
                      ? Icons.wifi
                      : networkQuality == NetworkQuality.cellular
                      ? Icons.signal_cellular_alt
                      : Icons.wifi_off,
                  color: networkQuality == NetworkQuality.wifi
                      ? const Color(0xFF10B981)
                      : networkQuality == NetworkQuality.cellular
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _StatusCard(
                  label: 'Channels',
                  value: '$activeChannels',
                  icon: Icons.hub,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _StatusCard(
                  label: 'Queued',
                  value: '$queuedMessages',
                  icon: Icons.queue,
                  color: queuedMessages > 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkOptimizationPanel(ThemeData theme) {
    final networkQuality = _subscriptionManager.networkQuality;

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
              Icon(
                Icons.network_check,
                color: const Color(0xFF10B981),
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Network Optimization',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _OptimizationRow(
            label: 'Connection Type',
            value: networkQuality == NetworkQuality.wifi
                ? 'WiFi'
                : networkQuality == NetworkQuality.cellular
                ? 'Cellular (4G/5G)'
                : 'Offline',
            isActive: true,
          ),
          _OptimizationRow(
            label: 'Subscription Strategy',
            value: networkQuality == NetworkQuality.cellular
                ? '5-second polling'
                : 'Real-time WebSocket',
            isActive: true,
          ),
          _OptimizationRow(
            label: 'Batch Window',
            value: '200ms (prevents duplicate subscriptions)',
            isActive: true,
          ),
          _OptimizationRow(
            label: 'Memory Leak Prevention',
            value: 'Auto-dispose on widget unmount',
            isActive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTips(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.vibrantYellow.withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.vibrantYellow.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.vibrantYellow, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Optimization Recommendations',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ..._getTips().map(
            (tip) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.vibrantYellow,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTips() {
    return [
      'Carousel libraries use deferred loading - only loaded when visible in viewport',
      'Subscriptions batched within 200ms window to prevent duplicate channels',
      'Cellular networks automatically switch to 5-second polling to save battery',
      'Offline messages queued with priority levels: critical → high → normal',
      'All subscriptions auto-disposed when widgets unmount to prevent memory leaks',
    ];
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.icon,
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
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
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

class _OptimizationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;

  const _OptimizationRow({
    required this.label,
    required this.value,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
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