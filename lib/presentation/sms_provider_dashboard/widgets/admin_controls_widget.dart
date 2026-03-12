import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdminControlsWidget extends StatelessWidget {
  final String currentProvider;
  final Function(String) onSwitchProvider;

  const AdminControlsWidget({
    super.key,
    required this.currentProvider,
    required this.onSwitchProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manual Provider Controls',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        Text(
          'Instantly switch SMS providers with zero downtime',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 3.h),

        // Switch to Telnyx
        _buildProviderCard(
          context,
          'Telnyx',
          'Primary SMS provider with full feature support',
          Colors.blue,
          currentProvider == 'telnyx',
          () => onSwitchProvider('telnyx'),
        ),
        SizedBox(height: 2.h),

        // Switch to Twilio
        _buildProviderCard(
          context,
          'Twilio',
          'Fallback provider (gamification SMS will be blocked)',
          Colors.orange,
          currentProvider == 'twilio',
          () => onSwitchProvider('twilio'),
        ),
        SizedBox(height: 3.h),

        // Warning card
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.amber.shade700, size: 20.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Gamification SMS (lottery winners, prizes, contests) are automatically blocked when using Twilio fallback and will be queued for resend when Telnyx is restored.',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    String name,
    String description,
    Color color,
    bool isActive,
    VoidCallback onSwitch,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withAlpha(26),
                child: Icon(Icons.sms, color: color, size: 20.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isActive) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(26),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isActive) ...[
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSwitch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Switch to $name',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
