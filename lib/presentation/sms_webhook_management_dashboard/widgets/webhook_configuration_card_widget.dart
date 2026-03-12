import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class WebhookConfigurationCardWidget extends StatelessWidget {
  final Function(String) onManualFailover;

  const WebhookConfigurationCardWidget({
    super.key,
    required this.onManualFailover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const telnyxUrl =
        'https://your-project.supabase.co/functions/v1/sms-webhooks';
    const twilioUrl =
        'https://your-project.supabase.co/functions/v1/twilio-webhooks';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Webhook Endpoints',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),

          // Telnyx Configuration
          _buildProviderCard(context, 'Telnyx', telnyxUrl, Colors.blue, [
            'message.sent',
            'message.delivered',
            'message.failed',
            'message.received',
          ]),
          SizedBox(height: 2.h),

          // Twilio Configuration
          _buildProviderCard(context, 'Twilio', twilioUrl, Colors.purple, [
            'MessageStatus: sent',
            'MessageStatus: delivered',
            'MessageStatus: failed',
            'MessageStatus: undelivered',
          ]),
          SizedBox(height: 3.h),

          // Manual Failover Controls
          Text(
            'Manual Failover Controls',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onManualFailover('telnyx'),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch to Telnyx'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onManualFailover('twilio'),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch to Twilio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
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

  Widget _buildProviderCard(
    BuildContext context,
    String provider,
    String webhookUrl,
    Color color,
    List<String> events,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.webhook, color: color, size: 20.sp),
              ),
              SizedBox(width: 3.w),
              Text(
                provider,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 12.sp),
                    SizedBox(width: 1.w),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Webhook URL:',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    webhookUrl,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'monospace',
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: webhookUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Webhook URL copied')),
                    );
                  },
                  icon: Icon(Icons.copy, size: 16.sp, color: color),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Subscribed Events:',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: events
                .map(
                  (event) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withAlpha(51)),
                    ),
                    child: Text(
                      event,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
