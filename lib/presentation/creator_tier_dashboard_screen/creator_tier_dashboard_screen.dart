import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/achievement_service.dart';
import '../../services/tier_calculation_service.dart';
import '../../theme/app_theme.dart';
import './widgets/achievement_grid_widget.dart';
import './widgets/tier_benefits_widget.dart';
import './widgets/tier_progress_widget.dart';

class CreatorTierDashboardScreen extends StatefulWidget {
  const CreatorTierDashboardScreen({super.key});

  @override
  State<CreatorTierDashboardScreen> createState() =>
      _CreatorTierDashboardScreenState();
}

class _CreatorTierDashboardScreenState
    extends State<CreatorTierDashboardScreen> {
  final TierCalculationService _tierService = TierCalculationService.instance;
  final AchievementService _achievementService = AchievementService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _tierInfo = {};
  Map<String, dynamic> _progress = {};
  List<Map<String, dynamic>> _allTiers = [];
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _userAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final tierInfo = await _tierService.getUserTierInfo();
      final progress = await _tierService.getProgressToNextTier();
      final allTiers = await _tierService.getAllTierConfigs();
      final achievements = await _achievementService.getAllAchievements();
      final userAchievements = await _achievementService.getUserAchievements();

      setState(() {
        _tierInfo = tierInfo;
        _progress = progress;
        _allTiers = allTiers;
        _achievements = achievements;
        _userAchievements = userAchievements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Creator Tier Dashboard',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Tier Badge
                    _buildCurrentTierSection(),
                    SizedBox(height: 3.h),

                    // Progress to Next Tier
                    if (!(_progress['is_max_tier'] ?? false)) ...[
                      TierProgressWidget(progress: _progress),
                      SizedBox(height: 3.h),
                    ],

                    // Current Benefits
                    TierBenefitsWidget(tierInfo: _tierInfo),
                    SizedBox(height: 3.h),

                    // Achievements
                    AchievementGridWidget(
                      achievements: _achievements,
                      userAchievements: _userAchievements,
                      onAchievementTap: _showAchievementDetails,
                    ),
                    SizedBox(height: 3.h),

                    // All Tiers Comparison
                    _buildTierComparison(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentTierSection() {
    final currentTier = _tierInfo['current_tier'] as String? ?? 'bronze';
    final tierColor = _getTierColor(currentTier);
    final vpMultiplier = _tierInfo['vp_multiplier'] as double? ?? 1.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(_getTierIcon(currentTier), size: 20.w, color: Colors.white),
          SizedBox(height: 1.h),
          Text(
            currentTier.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'VP Multiplier: ${vpMultiplier.toStringAsFixed(1)}x',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Tiers',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ..._allTiers.map((tier) => _buildTierComparisonCard(tier)),
      ],
    );
  }

  Widget _buildTierComparisonCard(Map<String, dynamic> tier) {
    final tierLevel = tier['tier_level'] as String;
    final tierName = tier['tier_name'] as String;
    final earningsReq = (tier['earnings_requirement'] as num).toDouble();
    final vpReq = tier['vp_requirement'] as int;
    final vpMultiplier = (tier['vp_multiplier'] as num).toDouble();
    final features = tier['features'] as List? ?? [];
    final isCurrent = tierLevel == (_tierInfo['current_tier'] ?? 'bronze');

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isCurrent
            ? _getTierColor(tierLevel).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isCurrent ? _getTierColor(tierLevel) : Colors.grey.shade300,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTierIcon(tierLevel),
                color: _getTierColor(tierLevel),
                size: 12.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'VP Multiplier: ${vpMultiplier.toStringAsFixed(1)}x',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getTierColor(tierLevel),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    'CURRENT',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Requirements:',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '• \$${earningsReq.toStringAsFixed(0)} lifetime earnings',
            style: GoogleFonts.inter(fontSize: 10.sp),
          ),
          Text(
            '• ${vpReq.toString()} VP earned',
            style: GoogleFonts.inter(fontSize: 10.sp),
          ),
          if (features.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              'Features:',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 0.5.h),
            ...features
                .take(3)
                .map(
                  (f) => Text(
                    '• ${_formatFeature(f.toString())}',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    final colors = {
      'bronze': Color(0xFFCD7F32),
      'silver': Color(0xFFC0C0C0),
      'gold': Color(0xFFFFD700),
      'platinum': Color(0xFFE5E4E2),
      'elite': Color(0xFF9B59B6),
    };
    return colors[tier] ?? AppTheme.primaryLight;
  }

  IconData _getTierIcon(String tier) {
    final icons = {
      'bronze': Icons.workspace_premium,
      'silver': Icons.military_tech,
      'gold': Icons.emoji_events,
      'platinum': Icons.diamond,
      'elite': Icons.stars,
    };
    return icons[tier] ?? Icons.workspace_premium;
  }

  String _formatFeature(String feature) {
    return feature
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    final isUnlocked = _userAchievements.any(
      (ua) => ua['achievement_id'] == achievement['id'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement['title'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement['description'] ?? ''),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.stars, color: Colors.amber, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Reward: ${achievement['vp_reward']} VP',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.check_circle : Icons.lock,
                  color: isUnlocked ? Colors.green : Colors.grey,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  isUnlocked ? 'Unlocked' : 'Locked',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: isUnlocked ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
