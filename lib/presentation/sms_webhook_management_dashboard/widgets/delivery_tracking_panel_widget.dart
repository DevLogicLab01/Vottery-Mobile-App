import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DeliveryTrackingPanelWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DeliveryTrackingPanelWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Statistics (24h)',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),

          // Telnyx Stats
          _buildProviderStats(
            context,
            'Telnyx',
            Colors.blue,
            stats['telnyx_sent'] as int? ?? 0,
            stats['telnyx_delivered'] as int? ?? 0,
            stats['telnyx_failed'] as int? ?? 0,
            stats['telnyx_delivery_rate'] as String? ?? '0.0',
          ),
          SizedBox(height: 2.h),

          // Twilio Stats
          _buildProviderStats(
            context,
            'Twilio',
            Colors.purple,
            stats['twilio_sent'] as int? ?? 0,
            stats['twilio_delivered'] as int? ?? 0,
            stats['twilio_failed'] as int? ?? 0,
            stats['twilio_delivery_rate'] as String? ?? '0.0',
          ),
        ],
      ),
    );
  }

  Widget _buildProviderStats(
    BuildContext context,
    String provider,
    Color color,
    int sent,
    int delivered,
    int failed,
    String deliveryRate,
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
                child: Icon(Icons.analytics, color: color, size: 20.sp),
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
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Sent', sent.toString(), Colors.blue),
              ),
              Expanded(
                child: _buildStatItem(
                  'Delivered',
                  delivered.toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem('Failed', failed.toString(), Colors.red),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Rate',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '$deliveryRate%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
