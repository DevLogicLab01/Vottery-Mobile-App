import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TierProgressionTrackerWidget extends StatelessWidget {
  final Map<String, dynamic> tierData;
  final double totalEarnings;

  const TierProgressionTrackerWidget({
    super.key,
    required this.tierData,
    required this.totalEarnings,
  });

  @override
  Widget build(BuildContext context) {
    final currentTier = tierData['current_tier'] ?? 'Bronze';
    final currentTierIndex = _getTierIndex(currentTier);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tier Progression',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'Unlock exclusive benefits as you advance',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 3.h),
          _buildTierTimeline(context, currentTierIndex),
          SizedBox(height: 3.h),
          _buildCurrentTierBenefits(context, currentTier),
          SizedBox(height: 2.h),
          _buildNextTierRequirements(context, currentTierIndex),
        ],
      ),
    );
  }

  Widget _buildTierTimeline(BuildContext context, int currentIndex) {
    final tiers = [
      {
        'name': 'Bronze',
        'icon': Icons.workspace_premium,
        'color': Colors.brown,
      },
      {'name': 'Silver', 'icon': Icons.workspace_premium, 'color': Colors.grey},
      {'name': 'Gold', 'icon': Icons.workspace_premium, 'color': Colors.amber},
      {
        'name': 'Platinum',
        'icon': Icons.workspace_premium,
        'color': Colors.cyan,
      },
      {
        'name': 'Diamond',
        'icon': Icons.workspace_premium,
        'color': Colors.blue,
      },
      {
        'name': 'Elite Master',
        'icon': Icons.military_tech,
        'color': Colors.purple,
      },
    ];

    return SizedBox(
      height: 12.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tiers.length,
        itemBuilder: (context, index) {
          final tier = tiers[index];
          final isUnlocked = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? (tier['color'] as Color)
                          : Colors.grey[300],
                      border: Border.all(
                        color: isCurrent
                            ? (tier['color'] as Color)
                            : Colors.transparent,
                        width: 3.0,
                      ),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: (tier['color'] as Color).withAlpha(77),
                                blurRadius: 8.0,
                                spreadRadius: 2.0,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      tier['icon'] as IconData,
                      color: isUnlocked ? Colors.white : Colors.grey[500],
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    tier['name'] as String,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isUnlocked ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      margin: EdgeInsets.only(top: 0.5.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: (tier['color'] as Color).withAlpha(51),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: tier['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (index < tiers.length - 1)
                Container(
                  width: 8.w,
                  height: 2.0,
                  margin: EdgeInsets.only(bottom: 6.h),
                  color: isUnlocked
                      ? (tier['color'] as Color)
                      : Colors.grey[300],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentTierBenefits(BuildContext context, String tier) {
    final benefits = _getTierBenefits(tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Tier Benefits',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ...benefits.map(
          (benefit) => Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(benefit, style: TextStyle(fontSize: 12.sp)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextTierRequirements(BuildContext context, int currentIndex) {
    if (currentIndex >= 5) {
      return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.purple.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.purple, size: 24.sp),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Congratulations! You\'ve reached the highest tier!',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final nextTier = _getTierName(currentIndex + 1);
    final requirements = _getTierRequirements(nextTier);
    final progress = tierData['next_milestone_progress'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next Tier: $nextTier',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% Complete',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8.0,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Requirements:',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ...requirements.map(
          (req) => Padding(
            padding: EdgeInsets.only(bottom: 0.8.h),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey,
                  size: 14.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    req,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _getTierIndex(String tier) {
    const tiers = [
      'Bronze',
      'Silver',
      'Gold',
      'Platinum',
      'Diamond',
      'Elite Master',
    ];
    return tiers.indexOf(tier);
  }

  String _getTierName(int index) {
    const tiers = [
      'Bronze',
      'Silver',
      'Gold',
      'Platinum',
      'Diamond',
      'Elite Master',
    ];
    return tiers[index];
  }

  List<String> _getTierBenefits(String tier) {
    final benefitsMap = {
      'Bronze': [
        'Basic creator dashboard access',
        '1.0x VP multiplier on earnings',
        'Standard payout schedule (weekly)',
      ],
      'Silver': [
        'Advanced analytics dashboard',
        '1.2x VP multiplier on earnings',
        'Priority customer support',
        'Early access to new features',
      ],
      'Gold': [
        'Premium analytics with AI insights',
        '1.5x VP multiplier on earnings',
        'Dedicated account manager',
        'Custom branding options',
        'Reduced platform fees (8%)',
      ],
      'Platinum': [
        'Enterprise analytics suite',
        '2.0x VP multiplier on earnings',
        'VIP support with 1-hour response',
        'Advanced API access',
        'Reduced platform fees (5%)',
        'Featured creator badge',
      ],
      'Diamond': [
        'Full platform analytics access',
        '2.5x VP multiplier on earnings',
        '24/7 priority support',
        'White-label options',
        'Reduced platform fees (3%)',
        'Exclusive partnership opportunities',
        'Revenue share negotiations',
      ],
      'Elite Master': [
        'Unlimited analytics and insights',
        '3.0x VP multiplier on earnings',
        'Dedicated success team',
        'Custom contract terms',
        'Minimum platform fees (1%)',
        'Strategic partnership priority',
        'Platform governance participation',
        'Exclusive events and networking',
      ],
    };

    return benefitsMap[tier] ?? [];
  }

  List<String> _getTierRequirements(String tier) {
    final requirementsMap = {
      'Silver': [
        'Earn \$1,000 total revenue',
        'Create 10 successful elections',
        'Maintain 4.0+ creator rating',
      ],
      'Gold': [
        'Earn \$5,000 total revenue',
        'Create 50 successful elections',
        'Maintain 4.5+ creator rating',
        '1,000+ total participants',
      ],
      'Platinum': [
        'Earn \$25,000 total revenue',
        'Create 200 successful elections',
        'Maintain 4.7+ creator rating',
        '10,000+ total participants',
      ],
      'Diamond': [
        'Earn \$100,000 total revenue',
        'Create 500 successful elections',
        'Maintain 4.8+ creator rating',
        '50,000+ total participants',
        'Complete KYC verification',
      ],
      'Elite Master': [
        'Earn \$500,000 total revenue',
        'Create 1,000+ successful elections',
        'Maintain 4.9+ creator rating',
        '250,000+ total participants',
        'Strategic partnership agreement',
      ],
    };

    return requirementsMap[tier] ?? [];
  }
}
