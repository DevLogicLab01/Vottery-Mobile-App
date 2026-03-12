import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TierProgressionWidget extends StatelessWidget {
  final String currentTier;
  final int totalJolts;

  const TierProgressionWidget({
    super.key,
    required this.currentTier,
    required this.totalJolts,
  });

  @override
  Widget build(BuildContext context) {
    final tiers = [
      {'name': 'Bronze Creator', 'min': 0, 'max': 10, 'multiplier': 1.0},
      {'name': 'Silver Creator', 'min': 10, 'max': 50, 'multiplier': 1.5},
      {'name': 'Gold Creator', 'min': 50, 'max': 100, 'multiplier': 2.0},
      {'name': 'Platinum Creator', 'min': 100, 'max': null, 'multiplier': 3.0},
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Creator Tier Progression',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        ...tiers.map((tier) => _buildTierCard(tier)),
      ],
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final isCurrentTier = tier['name'] == currentTier;
    final isUnlocked = totalJolts >= (tier['min'] as int);

    return Card(
      color: isCurrentTier ? Colors.blue.shade50 : null,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(
              isUnlocked ? Icons.check_circle : Icons.lock,
              color: isUnlocked ? Colors.green : Colors.grey,
              size: 8.w,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier['name'] as String,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${tier['min']}-${tier['max'] ?? '∞'} videos',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${tier['multiplier']}x VP',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
