import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/admin_automation_engine_service.dart';

class AutomationRuleCardWidget extends StatelessWidget {
  final AutomationRule rule;
  final VoidCallback onToggle;
  final VoidCallback onExecuteNow;
  final Function(Duration) onOverride;

  const AutomationRuleCardWidget({
    super.key,
    required this.rule,
    required this.onToggle,
    required this.onExecuteNow,
    required this.onOverride,
  });

  Color get _typeColor {
    switch (rule.type) {
      case AutomationRuleType.festivalMode:
        return Colors.purple;
      case AutomationRuleType.fraudProneRegionPause:
        return Colors.red;
      case AutomationRuleType.retentionCampaign:
        return Colors.blue;
      case AutomationRuleType.dynamicPricing:
        return Colors.green;
      case AutomationRuleType.maintenanceMode:
        return Colors.orange;
    }
  }

  IconData get _typeIcon {
    switch (rule.type) {
      case AutomationRuleType.festivalMode:
        return Icons.celebration;
      case AutomationRuleType.fraudProneRegionPause:
        return Icons.block;
      case AutomationRuleType.retentionCampaign:
        return Icons.people;
      case AutomationRuleType.dynamicPricing:
        return Icons.attach_money;
      case AutomationRuleType.maintenanceMode:
        return Icons.build;
    }
  }

  String get _typeLabel {
    switch (rule.type) {
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: rule.isEnabled ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: rule.isEnabled
              ? _typeColor.withAlpha(102)
              : Colors.grey.withAlpha(51),
          width: rule.isEnabled ? 1.5 : 0.5,
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
                    color: _typeColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(_typeIcon, color: _typeColor, size: 20),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.ruleName,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.2.h,
                            ),
                            decoration: BoxDecoration(
                              color: _typeColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _typeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: _typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (rule.isOverridden) ...[
                            SizedBox(width: 1.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(51),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                'OVERRIDDEN',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  color: Colors.amber[800],
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
                  value: rule.isEnabled && !rule.isOverridden,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: _typeColor,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            // Schedule
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  'Schedule: ${rule.schedule}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
                if (rule.lastExecuted != null) ...[
                  const Spacer(),
                  Text(
                    'Last: ${_formatTime(rule.lastExecuted!)}',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 0.5.h),
            // Actions preview
            Wrap(
              spacing: 1.w,
              runSpacing: 0.3.h,
              children: rule.actions
                  .take(3)
                  .map(
                    (action) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w,
                        vertical: 0.2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        action.replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 1.h),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExecuteNow,
                    icon: const Icon(Icons.play_arrow, size: 14),
                    label: Text(
                      'Execute Now',
                      style: GoogleFonts.inter(fontSize: 10.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _typeColor,
                      side: BorderSide(color: _typeColor),
                      padding: EdgeInsets.symmetric(vertical: 0.8.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                PopupMenuButton<Duration>(
                  onSelected: onOverride,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: const Duration(hours: 1),
                      child: Text(
                        'Override 1h',
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                    PopupMenuItem(
                      value: const Duration(hours: 6),
                      child: Text(
                        'Override 6h',
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                    PopupMenuItem(
                      value: const Duration(hours: 24),
                      child: Text(
                        'Override 24h',
                        style: GoogleFonts.inter(fontSize: 11.sp),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pause_circle_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Override',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
