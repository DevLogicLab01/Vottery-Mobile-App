import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/nft_achievement_service.dart';
import '../../../services/voting_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

class MintingCenterWidget extends StatefulWidget {
  final VoidCallback onMintComplete;

  const MintingCenterWidget({super.key, required this.onMintComplete});

  @override
  State<MintingCenterWidget> createState() => _MintingCenterWidgetState();
}

class _MintingCenterWidgetState extends State<MintingCenterWidget> {
  final NFTAchievementService _nftService = NFTAchievementService.instance;
  final VotingService _votingService = VotingService.instance;

  List<Map<String, dynamic>> _availableMilestones = [];
  Map<String, dynamic> _userProgress = {};
  bool _isLoading = true;
  bool _isMinting = false;

  @override
  void initState() {
    super.initState();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    setState(() => _isLoading = true);

    // Get user's vote count
    final voteHistory = await _votingService.getUserVoteHistory();
    final voteCount = voteHistory.length;

    // Mock creator and advertiser counts (in production, fetch from database)
    final creatorCount = 0;
    final advertiserCount = 0;

    final progress = {
      'votes': voteCount,
      'elections_created': creatorCount,
      'ad_campaigns': advertiserCount,
    };

    // Filter milestones that are achievable
    final milestones = NFTAchievementService.milestoneAchievements;

    if (mounted) {
      setState(() {
        _availableMilestones = milestones;
        _userProgress = progress;
        _isLoading = false;
      });
    }
  }

  Future<void> _mintBadge(Map<String, dynamic> milestone) async {
    setState(() => _isMinting = true);

    final achievementKey = milestone['key'] as String;
    final badgeType = milestone['badge_type'] as String;

    int currentCount = 0;
    if (badgeType == 'milestone') {
      currentCount = _userProgress['votes'] ?? 0;
    } else if (badgeType == 'creator') {
      currentCount = _userProgress['elections_created'] ?? 0;
    } else if (badgeType == 'advertiser') {
      currentCount = _userProgress['ad_campaigns'] ?? 0;
    }

    final result = await _nftService.checkAndMintMilestone(
      achievementKey: achievementKey,
      currentCount: currentCount,
    );

    if (mounted) {
      setState(() => _isMinting = false);

      if (result['success']) {
        _showSuccessDialog(result);
        widget.onMintComplete();
      } else {
        _showErrorDialog(result['message'] as String);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    final theme = Theme.of(context);
    final nftData = result['nft_data'] as Map<String, dynamic>;
    final gasEstimate = result['gas_estimate'] as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.tertiary,
              size: 32,
            ),
            SizedBox(width: 2.w),
            const Text('NFT Minted!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your achievement badge has been minted on the blockchain.',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Text(
              'Gas Fee: ${gasEstimate['estimated_cost_eth']} ETH (\$${gasEstimate['estimated_cost_usd']})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minting Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SkeletonDashboard();
    }

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Header
        Text(
          'Available Milestones',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Complete achievements to mint NFT badges',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 3.h),

        // Milestone cards
        ..._availableMilestones.map((milestone) {
          final title = milestone['title'] as String;
          final description = milestone['description'] as String;
          final requirement = milestone['requirement'] as int;
          final badgeType = milestone['badge_type'] as String;

          int currentCount = 0;
          String progressLabel = '';

          if (badgeType == 'milestone') {
            currentCount = _userProgress['votes'] ?? 0;
            progressLabel = 'votes';
          } else if (badgeType == 'creator') {
            currentCount = _userProgress['elections_created'] ?? 0;
            progressLabel = 'elections';
          } else if (badgeType == 'advertiser') {
            currentCount = _userProgress['ad_campaigns'] ?? 0;
            progressLabel = 'campaigns';
          }

          final isCompleted = currentCount >= requirement;
          final progress = currentCount / requirement;

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isCompleted
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isCompleted ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted ? Icons.check : Icons.workspace_premium,
                          color: isCompleted
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.outline,
                          size: 24,
                        ),
                      ),
                    ),

                    SizedBox(width: 3.w),

                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$currentCount / $requirement $progressLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(progress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (isCompleted) ...[
                  SizedBox(height: 2.h),

                  // Mint button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isMinting
                          ? null
                          : () => _mintBadge(milestone),
                      icon: _isMinting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isMinting ? 'Minting...' : 'Mint NFT Badge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: theme.colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
