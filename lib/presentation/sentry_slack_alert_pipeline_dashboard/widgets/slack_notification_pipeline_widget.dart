import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SlackNotificationPipelineWidget extends StatelessWidget {
  final Map<String, dynamic> pipelineStatus;
  final String slackChannel;
  final bool isPipelineSuspended;
  final bool isSendingTest;
  final Function(String) onChannelChanged;
  final VoidCallback onSendTest;

  const SlackNotificationPipelineWidget({
    super.key,
    required this.pipelineStatus,
    required this.slackChannel,
    required this.isPipelineSuspended,
    required this.isSendingTest,
    required this.onChannelChanged,
    required this.onSendTest,
  });

  @override
  Widget build(BuildContext context) {
    final deliveryRate =
        (pipelineStatus['delivery_rate'] as num?)?.toDouble() ?? 98.5;
    final avgDeliveryMs =
        (pipelineStatus['avg_delivery_ms'] as num?)?.toInt() ?? 342;
    final totalSent = (pipelineStatus['total_sent_24h'] as num?)?.toInt() ?? 0;
    final failed = (pipelineStatus['failed_24h'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWebhookStatusCard(deliveryRate, avgDeliveryMs, totalSent, failed),
        SizedBox(height: 2.h),
        _buildChannelRoutingCard(context),
        SizedBox(height: 2.h),
        _buildMessageTemplateCard(),
        SizedBox(height: 2.h),
        _buildTestNotificationCard(),
      ],
    );
  }

  Widget _buildWebhookStatusCard(
    double rate,
    int avgMs,
    int total,
    int failed,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.webhook, color: Colors.green, size: 20),
              SizedBox(width: 2.w),
              Text(
                'Webhook Delivery Status',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: isPipelineSuspended
                      ? Colors.orange.withAlpha(30)
                      : Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  isPipelineSuspended ? 'SUSPENDED' : 'OPERATIONAL',
                  style: GoogleFonts.inter(
                    color: isPipelineSuspended ? Colors.orange : Colors.green,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildDeliveryMetric(
                  '${rate.toStringAsFixed(1)}%',
                  'Delivery Rate',
                  Colors.green,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildDeliveryMetric(
                  '${avgMs}ms',
                  'Avg Latency',
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildDeliveryMetric(
                  '$total',
                  'Sent (24h)',
                  Colors.purple,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildDeliveryMetric('$failed', 'Failed', Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryMetric(String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 8.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelRoutingCard(BuildContext context) {
    final channels = [
      {
        'channel': '#vottery-errors',
        'type': 'Critical Errors',
        'active': true,
        'color': Colors.red,
      },
      {
        'channel': '#vottery-alerts',
        'type': 'High Priority',
        'active': true,
        'color': Colors.orange,
      },
      {
        'channel': '#vottery-monitoring',
        'type': 'Performance',
        'active': true,
        'color': Colors.blue,
      },
    ];

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
          Text(
            'Channel Routing',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          ...channels.map(
            (ch) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: (ch['color'] as Color).withAlpha(15),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: (ch['color'] as Color).withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tag, color: ch['color'] as Color, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ch['channel'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ch['type'] as String,
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: ch['active'] as bool,
                    onChanged: (_) {},
                    activeThumbColor: ch['color'] as Color,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTemplateCard() {
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
          Text(
            'Message Template',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.5.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF6366F1).withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 Critical Alert: {{error_summary}}',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 9.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Affected Users: {{affected_users_count}}',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white70,
                    fontSize: 9.sp,
                  ),
                ),
                Text(
                  'Severity: {{severity_level}}',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white70,
                    fontSize: 9.sp,
                  ),
                ),
                Text(
                  'Sentry: {{sentry_issue_url}}',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF6366F1),
                    fontSize: 9.sp,
                  ),
                ),
                Text(
                  'Time: {{timestamp}}',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white54,
                    fontSize: 9.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Notification',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Send a test alert to verify the Slack pipeline is working correctly.',
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 10.sp),
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSendingTest ? null : onSendTest,
              icon: isSendingTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(
                isSendingTest
                    ? 'Sending...'
                    : 'Send Test Alert to $slackChannel',
                style: GoogleFonts.inter(fontSize: 10.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
