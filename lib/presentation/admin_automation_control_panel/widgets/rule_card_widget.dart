import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/admin_automation_rules_service.dart';

class RuleCardWidget extends StatelessWidget {
  final AutomationRule rule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExecuteNow;
  final VoidCallback onOverride;

  const RuleCardWidget({
    super.key,
    required this.rule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onExecuteNow,
    required this.onOverride,
  });

  Color _getTypeColor(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return Colors.purple.shade600;
      case AutomationRuleType.fraudProneRegionPause:
        return Colors.red.shade600;
      case AutomationRuleType.retentionCampaign:
        return Colors.blue.shade600;
      case AutomationRuleType.dynamicPricing:
        return Colors.green.shade600;
      case AutomationRuleType.maintenanceMode:
        return Colors.orange.shade600;
    }
  }

  IconData _getTypeIcon(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return Icons.celebration;
      case AutomationRuleType.fraudProneRegionPause:
        return Icons.block;
      case AutomationRuleType.retentionCampaign:
        return Icons.campaign;
      case AutomationRuleType.dynamicPricing:
        return Icons.price_change;
      case AutomationRuleType.maintenanceMode:
        return Icons.build;
    }
  }

  String _getTypeLabel(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return 'Festival Mode';
      case AutomationRuleType.fraudProneRegionPause:
        return 'Region Pause';
      case AutomationRuleType.retentionCampaign:
        return 'Retention';
      case AutomationRuleType.dynamicPricing:
        return 'Dynamic Pricing';
      case AutomationRuleType.maintenanceMode:
        return 'Maintenance';
    }
  }

  bool get _isOverrideActive =>
      rule.overrideUntil != null && rule.overrideUntil!.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(rule.type);
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: rule.isEnabled
              ? typeColor.withAlpha(77)
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getTypeIcon(rule.type),
                    color: typeColor,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.ruleName,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.2.h,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _getTypeLabel(rule.type),
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_isOverrideActive) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'OVERRIDE',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled && !_isOverrideActive,
                  onChanged: _isOverrideActive ? null : onToggle,
                  activeThumbColor: typeColor,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.schedule, size: 12.sp, color: Colors.grey.shade500),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    'Schedule: ${rule.schedule.isEmpty ? "Manual" : rule.schedule}',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (rule.lastExecuted != null) ...[
              SizedBox(height: 0.3.h),
              Row(
                children: [
                  Icon(Icons.history, size: 12.sp, color: Colors.grey.shade500),
                  SizedBox(width: 1.w),
                  Text(
                    'Last run: ${_formatTime(rule.lastExecuted!)}',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExecuteNow,
                    icon: Icon(Icons.play_arrow, size: 12.sp),
                    label: Text(
                      'Run Now',
                      style: GoogleFonts.inter(fontSize: 10.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: typeColor,
                      side: BorderSide(color: typeColor),
                      padding: EdgeInsets.symmetric(vertical: 0.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOverride,
                    icon: Icon(Icons.pause_circle, size: 12.sp),
                    label: Text(
                      'Override',
                      style: GoogleFonts.inter(fontSize: 10.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade600,
                      side: BorderSide(color: Colors.orange.shade400),
                      padding: EdgeInsets.symmetric(vertical: 0.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: 16.sp,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
