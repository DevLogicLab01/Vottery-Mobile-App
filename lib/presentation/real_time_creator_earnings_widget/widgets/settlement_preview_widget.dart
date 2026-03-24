import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../config/batch1_route_allowlist.dart';
import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../services/creator_earnings_service.dart';

class SettlementPreviewWidget extends StatelessWidget {
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;

  SettlementPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _earningsService.getSettlementPreview(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final preview = snapshot.data ?? {};
        final canWithdraw = preview['can_withdraw'] ?? false;
        final availableUsd = preview['available_balance_usd'] ?? 0.0;
        final settlementDate = preview['estimated_settlement_date'] != null
            ? DateTime.parse(preview['estimated_settlement_date'])
            : DateTime.now().add(Duration(days: 7));

        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: canWithdraw ? AppTheme.accentLight : AppTheme.borderLight,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'account_balance',
                    size: 6.w,
                    color: AppTheme.primaryLight,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Settlement Preview',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              _buildInfoRow(
                'Available Balance',
                '\$${availableUsd.toStringAsFixed(2)}',
                AppTheme.accentLight,
              ),
              SizedBox(height: 1.h),
              _buildInfoRow(
                'Pending Balance',
                '\$${(preview['pending_balance_usd'] ?? 0.0).toStringAsFixed(2)}',
                AppTheme.textSecondaryLight,
              ),
              SizedBox(height: 1.h),
              _buildInfoRow(
                'Next Settlement',
                _formatSettlementDate(settlementDate),
                AppTheme.primaryLight,
              ),
              SizedBox(height: 2.h),
              Divider(color: AppTheme.borderLight),
              SizedBox(height: 2.h),
              if (canWithdraw)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: Batch1RouteAllowlist.isAllowed(
                          AppRoutes.creatorPayoutDashboard,
                        )
                        ? () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.creatorPayoutDashboard,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentLight,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                    child: Text(
                      'Request Withdrawal',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        size: 5.w,
                        color: AppTheme.warningLight,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Minimum \$50.00 required for withdrawal. Current: \$${availableUsd.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryLight),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatSettlementDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
