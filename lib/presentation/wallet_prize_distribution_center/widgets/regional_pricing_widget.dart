import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RegionalPricingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> zoneFeeStructure;

  const RegionalPricingWidget({super.key, required this.zoneFeeStructure});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: zoneFeeStructure.length,
      itemBuilder: (context, index) {
        final zone = zoneFeeStructure[index];
        final zoneName = zone['zone_name'] ?? 'Unknown Zone';
        final baseMultiplier = zone['base_multiplier'] ?? 1.0;
        final transactionFee = zone['transaction_fee_percentage'] ?? 0.0;
        final minimumFee = zone['minimum_fee'] ?? 0.0;
        final maximumFee = zone['maximum_fee'] ?? 0.0;
        final currencies = zone['supported_currencies'] ?? [];

        return Container(
          margin: EdgeInsets.only(bottom: 3.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.public,
                      color: AppTheme.primaryLight,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      zoneName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getMultiplierColor(
                        baseMultiplier,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '${(baseMultiplier * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _getMultiplierColor(baseMultiplier),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              SizedBox(height: 2.h),
              _buildInfoRow(
                'Transaction Fee',
                '${transactionFee.toStringAsFixed(2)}%',
                theme,
              ),
              SizedBox(height: 1.h),
              _buildInfoRow(
                'Minimum Fee',
                '\$${minimumFee.toStringAsFixed(2)}',
                theme,
              ),
              SizedBox(height: 1.h),
              _buildInfoRow(
                'Maximum Fee',
                '\$${maximumFee.toStringAsFixed(2)}',
                theme,
              ),
              SizedBox(height: 2.h),
              Text(
                'Supported Currencies',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: currencies.map<Widget>((currency) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      currency.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getMultiplierColor(double multiplier) {
    if (multiplier >= 1.0) {
      return AppTheme.errorLight;
    } else if (multiplier >= 0.7) {
      return AppTheme.warningLight;
    } else {
      return AppTheme.accentLight;
    }
  }
}
