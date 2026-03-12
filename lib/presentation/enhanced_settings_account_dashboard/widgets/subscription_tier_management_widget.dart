import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/subscription_service.dart';
import '../../../theme/app_theme.dart';

class SubscriptionTierManagementWidget extends StatelessWidget {
  final Map<String, dynamic>? currentSubscription;
  final Function(String) onUpgrade;
  final Function(String) onDowngrade;

  const SubscriptionTierManagementWidget({
    super.key,
    this.currentSubscription,
    required this.onUpgrade,
    required this.onDowngrade,
  });

  @override
  Widget build(BuildContext context) {
    final currentTier = currentSubscription?['tier'] ?? 'free';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Tiers',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...SubscriptionService.tiers.entries.map((entry) {
          final tierId = entry.key;
          final tierData = entry.value;
          final isCurrent = tierId == currentTier;

          return _buildTierCard(context, tierId, tierData, isCurrent);
        }),
      ],
    );
  }

  Widget _buildTierCard(
    BuildContext context,
    String tierId,
    Map<String, dynamic> tierData,
    bool isCurrent,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primaryLight.withAlpha(26) : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryLight : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierData['name'],
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      '\$${tierData['price_monthly']}/month',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          ...((tierData['features'] as List?) ?? []).map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isCurrent) ...[
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleTierChange(context, tierId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  _isUpgrade(tierId) ? 'Upgrade' : 'Downgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
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

  bool _isUpgrade(String targetTier) {
    final currentTier = currentSubscription?['tier'] ?? 'free';
    final tierOrder = ['free', 'basic', 'pro', 'elite'];
    final currentIndex = tierOrder.indexOf(currentTier);
    final targetIndex = tierOrder.indexOf(targetTier);
    return targetIndex > currentIndex;
  }

  void _handleTierChange(BuildContext context, String tierId) {
    if (_isUpgrade(tierId)) {
      onUpgrade(tierId);
    } else {
      onDowngrade(tierId);
    }
  }
}
