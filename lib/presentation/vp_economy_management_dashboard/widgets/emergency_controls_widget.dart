import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmergencyControlsWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const EmergencyControlsWidget({super.key, required this.onRefresh});

  @override
  State<EmergencyControlsWidget> createState() =>
      _EmergencyControlsWidgetState();
}

class _EmergencyControlsWidgetState extends State<EmergencyControlsWidget> {
  bool _isVPFrozen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'emergency',
                color: theme.colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Emergency Controls',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Platform-Wide VP Transaction Suspension & Crisis Management',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          _buildFreezeStatusCard(theme),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleVPFreeze,
                  icon: Icon(_isVPFrozen ? Icons.play_arrow : Icons.block),
                  label: Text(_isVPFrozen ? 'Unfreeze VP' : 'Freeze VP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVPFrozen
                        ? Colors.green
                        : theme.colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showBulkAdjustmentDialog,
                  icon: const Icon(Icons.tune),
                  label: const Text('Bulk Adjust'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeStatusCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _isVPFrozen
            ? theme.colorScheme.error.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isVPFrozen ? Icons.block : Icons.check_circle,
            color: _isVPFrozen ? theme.colorScheme.error : Colors.green,
            size: 24.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isVPFrozen
                      ? 'VP Transactions Frozen'
                      : 'VP Transactions Active',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isVPFrozen
                        ? theme.colorScheme.error
                        : Colors.green[700],
                  ),
                ),
                Text(
                  _isVPFrozen
                      ? 'All VP earning and spending is suspended'
                      : 'VP economy is operating normally',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVPFreeze() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isVPFrozen ? 'Unfreeze VP Economy?' : 'Freeze VP Economy?',
        ),
        content: Text(
          _isVPFrozen
              ? 'This will resume all VP transactions platform-wide.'
              : 'This will suspend all VP earning and spending platform-wide. Use only in emergency situations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _isVPFrozen = !_isVPFrozen);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isVPFrozen
                        ? 'VP economy frozen successfully'
                        : 'VP economy unfrozen successfully',
                  ),
                  backgroundColor: _isVPFrozen ? Colors.red : Colors.green,
                ),
              );
              widget.onRefresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isVPFrozen ? Colors.green : Colors.red,
            ),
            child: Text(_isVPFrozen ? 'Unfreeze' : 'Freeze'),
          ),
        ],
      ),
    );
  }

  void _showBulkAdjustmentDialog() {
    // TODO: Implement bulk VP adjustment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk VP adjustment feature coming soon')),
    );
  }
}
