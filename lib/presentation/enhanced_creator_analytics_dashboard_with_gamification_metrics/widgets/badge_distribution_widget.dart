import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';

class BadgeDistributionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const BadgeDistributionWidget({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final badgesByRarity = <String, List<Map<String, dynamic>>>{};
    for (var badge in badges) {
      final rarity = badge['badge_rarity'] as String? ?? 'common';
      badgesByRarity.putIfAbsent(rarity, () => []).add(badge);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryLight, AppTheme.accentLight],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Badges',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${badges.length}',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.emoji_events, color: Colors.white, size: 10.w),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Badges by rarity
          if (badgesByRarity.containsKey('legendary')) ...[
            _buildRaritySection(
              'Legendary',
              badgesByRarity['legendary']!,
              Colors.amber,
            ),
            SizedBox(height: 2.h),
          ],
          if (badgesByRarity.containsKey('epic')) ...[
            _buildRaritySection('Epic', badgesByRarity['epic']!, Colors.purple),
            SizedBox(height: 2.h),
          ],
          if (badgesByRarity.containsKey('rare')) ...[
            _buildRaritySection('Rare', badgesByRarity['rare']!, Colors.blue),
            SizedBox(height: 2.h),
          ],
          if (badgesByRarity.containsKey('common')) ...[
            _buildRaritySection(
              'Common',
              badgesByRarity['common']!,
              Colors.grey,
            ),
          ],

          if (badges.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 15.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No badges earned yet',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Complete achievements to earn badges',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRaritySection(
    String rarity,
    List<Map<String, dynamic>> rarityBadges,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 1.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '$rarity (${rarityBadges.length})',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.2,
          ),
          itemCount: rarityBadges.length,
          itemBuilder: (context, index) {
            return _buildBadgeCard(rarityBadges[index], color);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, Color rarityColor) {
    final unlockDate = badge['unlock_date'] != null
        ? DateFormat('MMM d, y').format(DateTime.parse(badge['unlock_date']))
        : 'Unknown';

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: rarityColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: rarityColor, size: 10.w),
          SizedBox(height: 1.h),
          Text(
            badge['badge_name'] as String? ?? 'Unknown Badge',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            unlockDate,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
