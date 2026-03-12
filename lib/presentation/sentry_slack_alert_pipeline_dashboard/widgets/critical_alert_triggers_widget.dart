import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CriticalAlertTriggersWidget extends StatelessWidget {
  final int crashThreshold;
  final int aiFailureThreshold;
  final Map<String, dynamic> errorStats;
  final Function(int) onCrashThresholdChanged;
  final Function(int) onAiThresholdChanged;

  const CriticalAlertTriggersWidget({
    super.key,
    required this.crashThreshold,
    required this.aiFailureThreshold,
    required this.errorStats,
    required this.onCrashThresholdChanged,
    required this.onAiThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final triggers = [
      {
        'title': 'App Crash Rate',
        'description': 'Triggers when crash rate exceeds threshold per hour',
        'threshold': crashThreshold,
        'unit': 'crashes/hour',
        'current': (errorStats['critical_count'] as num?)?.toInt() ?? 0,
        'severity': 'CRITICAL',
        'color': Colors.red,
        'icon': Icons.error_outline,
        'active': true,
      },
      {
        'title': 'AI Service Failures',
        'description': 'Triggers when AI service failures exceed threshold',
        'threshold': aiFailureThreshold,
        'unit': 'failures/hour',
        'current': (errorStats['high_count'] as num?)?.toInt() ?? 0,
        'severity': 'HIGH',
        'color': Colors.orange,
        'icon': Icons.psychology_outlined,
        'active': true,
      },
      {
        'title': 'API Latency Spike',
        'description': 'Triggers when p95 latency exceeds 3000ms',
        'threshold': 3000,
        'unit': 'ms p95',
        'current': 342,
        'severity': 'HIGH',
        'color': Colors.amber,
        'icon': Icons.speed,
        'active': true,
      },
      {
        'title': 'Memory Leak Detection',
        'description': 'Triggers when memory usage exceeds 500MB',
        'threshold': 500,
        'unit': 'MB',
        'current': 245,
        'severity': 'MEDIUM',
        'color': Colors.blue,
        'icon': Icons.memory,
        'active': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurable Alert Triggers',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Configure thresholds that trigger Slack notifications to #vottery-errors',
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
        ),
        SizedBox(height: 2.h),
        ...triggers.map((trigger) => _buildTriggerCard(trigger)),
        SizedBox(height: 2.h),
        _buildDeduplicationCard(),
        SizedBox(height: 2.h),
        _buildEscalationCard(),
      ],
    );
  }

  Widget _buildTriggerCard(Map<String, dynamic> trigger) {
    final color = trigger['color'] as Color;
    final current = trigger['current'] as int;
    final threshold = trigger['threshold'] as int;
    final isTriggered = current >= threshold;
    final isActive = trigger['active'] as bool;

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isTriggered && isActive
              ? color.withAlpha(150)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trigger['icon'] as IconData, color: color, size: 18),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trigger['title'] as String,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      trigger['description'] as String,
                      style: GoogleFonts.inter(
                        color: Colors.white54,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      trigger['severity'] as String,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Switch(
                    value: isActive,
                    onChanged: (_) {},
                    activeThumbColor: color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: $current ${trigger['unit']}',
                          style: GoogleFonts.inter(
                            color: isTriggered ? color : Colors.white70,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Threshold: $threshold ${trigger['unit']}',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: LinearProgressIndicator(
                        value: threshold > 0
                            ? (current / threshold).clamp(0.0, 1.0)
                            : 0.0,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isTriggered ? color : color.withAlpha(150),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isTriggered && isActive) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_active, color: color, size: 14),
                  SizedBox(width: 1.w),
                  Text(
                    'ALERT TRIGGERED — Slack notification sent',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeduplicationCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 2.w),
              Text(
                'Alert Deduplication',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  'ENABLED',
                  style: GoogleFonts.inter(
                    color: Colors.green,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildDedupeRow('Cooldown Period', '15 minutes'),
          _buildDedupeRow('Max Alerts/Hour', '10 per channel'),
          _buildDedupeRow('Grouping Strategy', 'By error type + feature'),
        ],
      ),
    );
  }

  Widget _buildDedupeRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.escalator_warning, color: Colors.red, size: 18),
              SizedBox(width: 2.w),
              Text(
                'Escalation Workflow',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildEscalationStep(
            '1',
            'Slack #vottery-errors',
            '0 min',
            Colors.red,
            true,
          ),
          _buildEscalationStep(
            '2',
            'Twilio SMS to on-call',
            '5 min',
            Colors.orange,
            true,
          ),
          _buildEscalationStep(
            '3',
            'Resend email to team',
            '10 min',
            Colors.yellow,
            false,
          ),
          _buildEscalationStep(
            '4',
            'PagerDuty incident',
            '15 min',
            Colors.purple,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationStep(
    String step,
    String action,
    String delay,
    Color color,
    bool active,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color.withAlpha(30) : Colors.white12,
              border: Border.all(color: active ? color : Colors.white24),
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.inter(
                  color: active ? color : Colors.white38,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              action,
              style: GoogleFonts.inter(
                color: active ? Colors.white : Colors.white38,
                fontSize: 10.sp,
              ),
            ),
          ),
          Text(
            delay,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 9.sp),
          ),
        ],
      ),
    );
  }
}
