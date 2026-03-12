import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class PrizeTypeSelectorWidget extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const PrizeTypeSelectorWidget({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prize Type',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        _buildPrizeTypeOption(
          'monetary',
          'Monetary Prize',
          'Fixed amount in USD, EUR, GBP, etc.',
          Icons.attach_money,
        ),
        SizedBox(height: 1.h),
        _buildPrizeTypeOption(
          'non_monetary',
          'Non-Monetary Prize',
          'Vouchers, coupons, physical prizes',
          Icons.card_giftcard,
        ),
        SizedBox(height: 1.h),
        _buildPrizeTypeOption(
          'revenue_sharing',
          'Revenue Sharing',
          'Percentage of content generated revenue',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildPrizeTypeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = selectedType == value;

    return GestureDetector(
      onTap: () => onTypeChanged(value),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withAlpha(26)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20.sp,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}
