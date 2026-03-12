import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RewardCardWidget extends StatelessWidget {
  final Map<String, dynamic> reward;
  final int currentVP;
  final VoidCallback onRedeem;

  const RewardCardWidget({
    super.key,
    required this.reward,
    required this.currentVP,
    required this.onRedeem,
  });

  IconData _getIconData() {
    final iconName = reward['icon_name'] as String;
    switch (iconName) {
      case 'block':
        return Icons.block;
      case 'palette':
        return Icons.palette;
      case 'trending_up':
        return Icons.trending_up;
      case 'cloud_upload':
        return Icons.cloud_upload;
      case 'how_to_vote':
        return Icons.how_to_vote;
      case 'confirmation_number':
        return Icons.confirmation_number;
      case 'add_circle':
        return Icons.add_circle;
      case 'verified':
        return Icons.verified;
      case 'groups':
        return Icons.groups;
      case 'campaign':
        return Icons.campaign;
      case 'person_add':
        return Icons.person_add;
      case 'emoji_emotions':
        return Icons.emoji_emotions;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'event':
        return Icons.event;
      case 'new_releases':
        return Icons.new_releases;
      case 'currency_bitcoin':
        return Icons.currency_bitcoin;
      case 'military_tech':
        return Icons.military_tech;
      case 'flag':
        return Icons.flag;
      default:
        return Icons.redeem;
    }
  }

  bool _canAfford() {
    return currentVP >= (reward['vp_cost'] as int);
  }

  @override
  Widget build(BuildContext context) {
    final vpCost = reward['vp_cost'] as int;
    final title = reward['title'] as String;
    final description = reward['description'] as String;
    final cashEquivalent = reward['cash_equivalent'] as double?;
    final durationDays = reward['duration_days'] as int?;
    final canAfford = _canAfford();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: canAfford ? Colors.purple.shade200 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: canAfford
                    ? Colors.purple.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                _getIconData(),
                size: 28.sp,
                color: canAfford ? Colors.purple : Colors.grey,
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
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (durationDays != null) ...[
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12.sp, color: Colors.orange),
                        SizedBox(width: 1.w),
                        Text(
                          '$durationDays days',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (cashEquivalent != null && cashEquivalent > 0) ...[
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 12.sp,
                          color: Colors.green,
                        ),
                        Text(
                          '\$${cashEquivalent.toStringAsFixed(2)} value',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: canAfford ? Colors.purple : Colors.grey,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '$vpCost VP',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                ElevatedButton(
                  onPressed: canAfford ? onRedeem : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? Colors.purple : Colors.grey,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Redeem',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
