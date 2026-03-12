import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/realtime_dashboard_service.dart';
import '../../../theme/app_theme.dart';

class DashboardSubscriptionCardWidget extends StatefulWidget {
  final DashboardType dashboardType;
  final RealtimeDashboardService dashboardService;
  final VoidCallback onUpdate;

  const DashboardSubscriptionCardWidget({
    super.key,
    required this.dashboardType,
    required this.dashboardService,
    required this.onUpdate,
  });

  @override
  State<DashboardSubscriptionCardWidget> createState() =>
      _DashboardSubscriptionCardWidgetState();
}

class _DashboardSubscriptionCardWidgetState
    extends State<DashboardSubscriptionCardWidget> {
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  void _checkSubscription() {
    setState(() {
      _isSubscribed = widget.dashboardService.isAutoRefreshEnabled(
        widget.dashboardType,
      );
    });
  }

  Future<void> _toggleSubscription() async {
    setState(() => _isLoading = true);
    try {
      if (_isSubscribed) {
        await widget.dashboardService.disconnect(widget.dashboardType);
      } else {
        final interval = widget.dashboardService.config.getInterval(
          widget.dashboardType,
        );
        await widget.dashboardService.configureDashboardRefresh(
          dashboardType: widget.dashboardType,
          updateInterval: interval,
        );
      }
      setState(() => _isSubscribed = !_isSubscribed);
      widget.onUpdate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getDashboardName() {
    switch (widget.dashboardType) {
      case DashboardType.analytics:
        return 'Analytics Dashboard';
      case DashboardType.security:
        return 'Security Dashboard';
      case DashboardType.performance:
        return 'Performance Dashboard';
      case DashboardType.fraud:
        return 'Fraud Dashboard';
      case DashboardType.operations:
        return 'Operations Dashboard';
      case DashboardType.compliance:
        return 'Compliance Dashboard';
    }
  }

  IconData _getDashboardIcon() {
    switch (widget.dashboardType) {
      case DashboardType.analytics:
        return Icons.analytics;
      case DashboardType.security:
        return Icons.security;
      case DashboardType.performance:
        return Icons.speed;
      case DashboardType.fraud:
        return Icons.warning;
      case DashboardType.operations:
        return Icons.settings;
      case DashboardType.compliance:
        return Icons.verified_user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final interval = widget.dashboardService.config.getInterval(
      widget.dashboardType,
    );
    final viewers = widget.dashboardService.getActiveViewers(
      widget.dashboardType,
    );

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getDashboardIcon(), color: AppTheme.primaryLight),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _getDashboardName(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: _isSubscribed,
                  onChanged: _isLoading ? null : (_) => _toggleSubscription(),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  'Interval: ${interval.inSeconds}s',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(width: 3.w),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  '$viewers viewers',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            if (_isSubscribed) SizedBox(height: 1.h),
            if (_isSubscribed)
              StreamBuilder<Map<String, dynamic>>(
                stream: widget.dashboardService.getStream(widget.dashboardType),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Live updates active',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }
}
