import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RegionalPricingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> pricingData;
  final String currentZone;

  const RegionalPricingWidget({
    super.key,
    required this.pricingData,
    required this.currentZone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentZoneCard(),
          SizedBox(height: 3.h),
          Text(
            'Regional Pricing Structure',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (pricingData.isEmpty)
            _buildEmptyState()
          else
            ...pricingData.map((pricing) => _buildPricingCard(pricing)),
        ],
      ),
    );
  }

  Widget _buildCurrentZoneCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.public, color: Colors.white, size: 10.w),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Purchasing Power Zone',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                Text(
                  _formatZoneName(currentZone),
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(Map<String, dynamic> pricing) {
    final vpAmount = pricing['vp_amount'] ?? 0;
    final localPrice = pricing['local_price'] ?? 0.0;
    final currencyCode = pricing['currency_code'] ?? 'USD';
    final discount = pricing['discount_percentage'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              '$vpAmount VP',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currencyCode ${localPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                if (discount > 0)
                  Text(
                    '${discount.toStringAsFixed(0)}% regional discount',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 6.w),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Column(
          children: [
            Icon(Icons.price_change, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No pricing data available',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatZoneName(String zone) {
    return zone
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
