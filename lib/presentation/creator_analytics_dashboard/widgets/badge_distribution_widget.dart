import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class BadgeDistributionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badges;

  const BadgeDistributionWidget({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Badge Collection',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${badges.length} Badges',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildRarityDistribution(theme),
          SizedBox(height: 2.h),
          _buildBadgeGrid(theme),
        ],
      ),
    );
  }

  Widget _buildRarityDistribution(ThemeData theme) {
    final rarityCount = {
      'common': badges.where((b) => b['rarity'] == 'common').length,
      'rare': badges.where((b) => b['rarity'] == 'rare').length,
      'epic': badges.where((b) => b['rarity'] == 'epic').length,
      'legendary': badges.where((b) => b['rarity'] == 'legendary').length,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildRarityChip('Common', rarityCount['common']!, Colors.grey, theme),
        _buildRarityChip('Rare', rarityCount['rare']!, Colors.blue, theme),
        _buildRarityChip('Epic', rarityCount['epic']!, Colors.purple, theme),
        _buildRarityChip(
          'Legendary',
          rarityCount['legendary']!,
          Colors.orange,
          theme,
        ),
      ],
    );
  }

  Widget _buildRarityChip(
    String label,
    int count,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid(ThemeData theme) {
    if (badges.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.h),
          child: Text(
            'No badges earned yet',
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeCard(badge, theme);
      },
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, ThemeData theme) {
    final rarity = badge['rarity'] as String? ?? 'common';
    final rarityColor = _getRarityColor(rarity);
    final unlockedAt = badge['unlocked_at'] != null
        ? DateTime.parse(badge['unlocked_at'])
        : DateTime.now();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [rarityColor.withAlpha(51), rarityColor.withAlpha(26)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: rarityColor, width: 2.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getBadgeIcon(badge['badge_name'] as String? ?? ''),
            size: 24.sp,
            color: rarityColor,
          ),
          SizedBox(height: 1.h),
          Text(
            badge['badge_name'] ?? 'Badge',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            timeago.format(unlockedAt),
            style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getBadgeIcon(String badgeName) {
    if (badgeName.contains('Voter')) return Icons.how_to_vote;
    if (badgeName.contains('Creator')) return Icons.video_library;
    if (badgeName.contains('Social')) return Icons.groups;
    if (badgeName.contains('Streak')) return Icons.local_fire_department;
    return Icons.stars;
  }
}
