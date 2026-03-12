import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SubscriptionTierCardWidget extends StatelessWidget {
  final Map<String, dynamic> tier;
  final bool isAnnual;
  final bool isProcessing;
  final VoidCallback onSubscribe;

  const SubscriptionTierCardWidget({
    super.key,
    required this.tier,
    required this.isAnnual,
    required this.isProcessing,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final price = isAnnual
        ? tier['annual_price'] as double
        : tier['monthly_price'] as double;
    final isPopular = tier['popular'] == true;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: isPopular
            ? Border.all(color: tier['color'] as Color, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: tier['color'] as Color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'star',
                    color: Colors.white,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: (tier['color'] as Color).withAlpha(26),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: CustomIconWidget(
                        iconName: tier['icon'] as String,
                        color: tier['color'] as Color,
                        size: 6.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier['name'] as String,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${tier['vp_multiplier']}x VP Multiplier',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: tier['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        Text(
                          isAnnual ? '/year' : '/month',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                ...((tier['features'] as List).map(
                  (feature) => Padding(
                    padding: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: Colors.green,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            feature as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: isProcessing ? null : onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tier['color'] as Color,
                    minimumSize: Size(double.infinity, 6.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          height: 4.w,
                          width: 4.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
