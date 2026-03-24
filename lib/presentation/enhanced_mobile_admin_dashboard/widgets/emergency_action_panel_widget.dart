import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../config/batch1_route_allowlist.dart';
import '../../../routes/app_routes.dart';
import '../../../services/admin_management_service.dart';

class EmergencyActionPanelWidget extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback onAuthRequired;
  final VoidCallback onRefresh;

  const EmergencyActionPanelWidget({
    super.key,
    required this.isAuthenticated,
    required this.onAuthRequired,
    required this.onRefresh,
  });

  @override
  State<EmergencyActionPanelWidget> createState() =>
      _EmergencyActionPanelWidgetState();
}

class _EmergencyActionPanelWidgetState
    extends State<EmergencyActionPanelWidget> {
  final AdminManagementService _adminService = AdminManagementService.instance;
  String? _lastAction;
  DateTime? _lastActionTime;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isAuthenticated) _buildAuthWarning(),
          if (!widget.isAuthenticated) SizedBox(height: 2.h),
          _buildAdminQuickLinks(),
          SizedBox(height: 2.h),
          _buildEmergencyActions(),
          SizedBox(height: 2.h),
          _buildFraudResponseActions(),
          SizedBox(height: 2.h),
          _buildSystemOverrideActions(),
          if (_lastAction != null) SizedBox(height: 2.h),
          if (_lastAction != null) _buildUndoCard(),
        ],
      ),
    );
  }

  Widget _buildAuthWarning() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24.sp),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric Authentication Required',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Critical operations require biometric verification',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminQuickLinks() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin tools',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        Batch1RouteAllowlist.isAllowed(
                          AppRoutes.contentModerationControlCenter,
                        )
                        ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.contentModerationControlCenter,
                          )
                        : null,
                    icon: const Icon(Icons.shield_outlined, size: 20),
                    label: const Text('Content Moderation'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      side: const BorderSide(color: Colors.indigo),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: Batch1RouteAllowlist.isAllowed(
                          AppRoutes.bulkManagementScreen,
                        )
                        ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.bulkManagementScreen,
                          )
                        : null,
                    icon: const Icon(Icons.layers, size: 20),
                    label: const Text('Bulk Management'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        Batch1RouteAllowlist.isAllowed(
                          AppRoutes.contentDistributionControlCenter,
                        )
                        ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.contentDistributionControlCenter,
                          )
                        : null,
                    icon: const Icon(Icons.pie_chart_outline, size: 20),
                    label: const Text('Content Distribution'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        Batch1RouteAllowlist.isAllowed(
                          AppRoutes.participationFeeControls,
                        )
                        ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.participationFeeControls,
                          )
                        : null,
                    icon: const Icon(Icons.payments_outlined, size: 20),
                    label: const Text('Participation Fees'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Controls',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildLargeActionButton(
                    'Pause Campaign',
                    Icons.pause_circle,
                    Colors.orange,
                    () => _executeAction('pause_campaign'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildLargeActionButton(
                    'Resume Campaign',
                    Icons.play_circle,
                    Colors.green,
                    () => _executeAction('resume_campaign'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudResponseActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fraud Response',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildLargeActionButton(
              'Freeze Account',
              Icons.block,
              Colors.red,
              () => _executeAction('freeze_account'),
              fullWidth: true,
            ),
            SizedBox(height: 2.h),
            _buildLargeActionButton(
              'Block Transaction',
              Icons.money_off,
              Colors.red.shade700,
              () => _executeAction('block_transaction'),
              fullWidth: true,
            ),
            SizedBox(height: 2.h),
            _buildLargeActionButton(
              'Escalate to Security',
              Icons.security,
              Colors.purple,
              () => _executeAction('escalate_security'),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverrideActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Override',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildLargeActionButton(
              'Disable Feature',
              Icons.toggle_off,
              Colors.grey,
              () => _executeAction('disable_feature'),
              fullWidth: true,
            ),
            SizedBox(height: 2.h),
            _buildLargeActionButton(
              'Bulk User Suspend',
              Icons.people_outline,
              Colors.orange.shade700,
              () => _executeAction('bulk_suspend'),
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 60,
      child: ElevatedButton(
        onPressed: widget.isAuthenticated ? onPressed : widget.onAuthRequired,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24.sp),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUndoCard() {
    final remainingSeconds =
        10 - DateTime.now().difference(_lastActionTime!).inSeconds;

    if (remainingSeconds <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(Icons.undo, color: Colors.blue, size: 20.sp),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action: $_lastAction',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Undo available for $remainingSeconds seconds',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _undoLastAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Undo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeAction(String action) async {
    HapticFeedback.heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text('Are you sure you want to execute: $action?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _lastAction = action;
        _lastActionTime = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action executed: $action'),
            backgroundColor: Colors.green,
            action: SnackBarAction(label: 'Undo', onPressed: _undoLastAction),
          ),
        );
      }

      widget.onRefresh();
    }
  }

  void _undoLastAction() {
    HapticFeedback.mediumImpact();

    setState(() {
      _lastAction = null;
      _lastActionTime = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Action undone'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
