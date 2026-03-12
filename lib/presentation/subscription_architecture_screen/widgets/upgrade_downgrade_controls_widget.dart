import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../routes/app_routes.dart';

class UpgradeDowngradeControlsWidget extends StatelessWidget {
  final String currentPlan;
  final VoidCallback onPlanChanged;

  const UpgradeDowngradeControlsWidget({
    super.key,
    required this.currentPlan,
    required this.onPlanChanged,
  });

  String? get _nextTier {
    switch (currentPlan.toLowerCase()) {
      case 'basic':
        return 'Pro';
      case 'pro':
        return 'Elite';
      default:
        return null;
    }
  }

  String? get _lowerTier {
    switch (currentPlan.toLowerCase()) {
      case 'elite':
        return 'Pro';
      case 'pro':
        return 'Basic';
      default:
        return null;
    }
  }

  void _showUpgradeDialog(BuildContext context, String targetPlan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Upgrade to $targetPlan'),
        content: Text(
          'You will be redirected to the billing portal to upgrade your plan to $targetPlan. '
          'Your VP multiplier will increase immediately upon upgrade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.premiumSubscriptionCenter);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showDowngradeDialog(BuildContext context, String targetPlan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Downgrade to $targetPlan'),
        content: Text(
          'Warning: Downgrading to $targetPlan will reduce your VP multiplier '
          'and you may lose access to premium features. This change takes effect '
          'at the end of your current billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, AppRoutes.premiumSubscriptionCenter);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Downgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextTier = _nextTier;
    final lowerTier = _lowerTier;

    if (nextTier == null && lowerTier == null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Color(0xFF7B2FF7),
                size: 32,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'You are on the Elite plan — the highest tier!',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Controls',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            if (nextTier != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpgradeDialog(context, nextTier),
                  icon: const Icon(Icons.arrow_upward),
                  label: Text(
                    'Upgrade to $nextTier',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            if (nextTier != null && lowerTier != null) SizedBox(height: 1.5.h),
            if (lowerTier != null)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showDowngradeDialog(context, lowerTier),
                  icon: const Icon(Icons.arrow_downward, color: Colors.red),
                  label: Text(
                    'Downgrade to $lowerTier',
                    style: TextStyle(fontSize: 13.sp, color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
