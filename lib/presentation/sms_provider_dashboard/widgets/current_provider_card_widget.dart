import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CurrentProviderCardWidget extends StatelessWidget {
  final String currentProvider;
  final Map<String, dynamic> deliveryStats;

  const CurrentProviderCardWidget({
    super.key,
    required this.currentProvider,
    required this.deliveryStats,
  });

  @override
  Widget build(BuildContext context) {
    final isOperational = currentProvider == 'telnyx';
    final totalSent = deliveryStats['total_sent'] ?? 0;
    final successRate = deliveryStats['success_rate'] ?? '0.0';

    return Container(
      margin: EdgeInsets.all(3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOperational
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOperational ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Provider',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withAlpha(204),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currentProvider.toUpperCase(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  isOperational ? 'OPERATIONAL' : 'FALLBACK',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Divider(color: Colors.white.withAlpha(77)),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(child: _buildStat('Total Sent', '$totalSent')),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(child: _buildStat('Success Rate', '$successRate%')),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _buildStat(
                  'Telnyx',
                  '${deliveryStats['telnyx_count'] ?? 0}',
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withAlpha(77),
              ),
              Expanded(
                child: _buildStat(
                  'Twilio',
                  '${deliveryStats['twilio_count'] ?? 0}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white.withAlpha(204)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
