import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/admin_automation_engine_service.dart';

class OverrideControlPanelWidget extends StatelessWidget {
  final List<AutomationRule> rules;
  final Function(String, Duration) onOverride;
  final VoidCallback onEmergencyStop;

  const OverrideControlPanelWidget({
    super.key,
    required this.rules,
    required this.onOverride,
    required this.onEmergencyStop,
  });

  @override
  Widget build(BuildContext context) {
    final activeRules = rules.where((r) => r.isEnabled).toList();
    final overriddenRules = rules.where((r) => r.isOverridden).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency Stop
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(13),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.red.withAlpha(77)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency, color: Colors.red),
                  SizedBox(width: 2.w),
                  Text(
                    'Emergency Controls',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                'Immediately disable all automation rules and send admin alert.',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmEmergencyStop(context),
                  icon: const Icon(Icons.stop_circle),
                  label: Text(
                    'EMERGENCY STOP ALL AUTOMATIONS',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        // Active Automations
        Text(
          'Active Automations (${activeRules.length})',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        if (activeRules.isEmpty)
          Center(
            child: Text(
              'No active automations',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeRules.length,
            itemBuilder: (context, index) {
              final rule = activeRules[index];
              return Card(
                margin: EdgeInsets.only(bottom: 1.h),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              rule.ruleName,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (rule.isOverridden)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(51),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                'OVERRIDDEN until ${_formatTime(rule.overrideUntil!)}',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Override Duration:',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          _overrideButton(
                            rule.ruleId,
                            const Duration(hours: 1),
                            '1h',
                          ),
                          SizedBox(width: 2.w),
                          _overrideButton(
                            rule.ruleId,
                            const Duration(hours: 6),
                            '6h',
                          ),
                          SizedBox(width: 2.w),
                          _overrideButton(
                            rule.ruleId,
                            const Duration(hours: 24),
                            '24h',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (overriddenRules.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Currently Overridden (${overriddenRules.length})',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 1.h),
          ...overriddenRules.map(
            (r) => Card(
              margin: EdgeInsets.only(bottom: 0.5.h),
              color: Colors.amber.withAlpha(13),
              child: ListTile(
                leading: const Icon(Icons.pause_circle, color: Colors.amber),
                title: Text(
                  r.ruleName,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Override expires: ${_formatTime(r.overrideUntil!)}',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _overrideButton(String ruleId, Duration duration, String label) {
    return OutlinedButton(
      onPressed: () => onOverride(ruleId, duration),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amber[800],
        side: BorderSide(color: Colors.amber.withAlpha(128)),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11.sp)),
    );
  }

  void _confirmEmergencyStop(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Emergency Stop',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        content: Text(
          'This will immediately disable ALL automation rules. Are you sure?',
          style: GoogleFonts.inter(fontSize: 12.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onEmergencyStop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('STOP ALL'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
