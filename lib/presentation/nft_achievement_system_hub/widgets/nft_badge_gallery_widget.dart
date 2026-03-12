import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/nft_achievement_service.dart';

class NFTBadgeGalleryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  final VoidCallback onRefresh;

  const NFTBadgeGalleryWidget({
    super.key,
    required this.badges,
    required this.onRefresh,
  });

  Future<void> _openBlockchainExplorer(String txHash) async {
    final url = NFTAchievementService.instance.getBlockchainExplorerUrl(txHash);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareBadge(Map<String, dynamic> badge) async {
    final title = badge['title'] as String;
    final txHash = badge['transaction_hash'] as String;
    final explorerUrl = NFTAchievementService.instance.getBlockchainExplorerUrl(
      txHash,
    );

    await Share.share(
      'I just earned the "$title" NFT achievement badge on Vottery! 🏆\n\nVerify on blockchain: $explorerUrl',
      subject: 'Vottery NFT Achievement',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            SizedBox(height: 2.h),
            Text(
              'No NFT Badges Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Complete achievements to mint your first badge',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.75,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final title = badge['title'] as String;
        final tier = badge['tier'] as String;
        final rarity = badge['rarity'] as String;
        final badgeType = badge['badge_type'] as String;
        final txHash = badge['transaction_hash'] as String;
        final mintedAt = DateTime.parse(badge['minted_at'] as String);

        // Get tier color
        final tierData = NFTAchievementService.achievementTiers.firstWhere(
          (t) => t['tier'] == tier,
          orElse: () => NFTAchievementService.achievementTiers[0],
        );
        final tierColor = Color(tierData['color'] as int);

        return GestureDetector(
          onTap: () => _showBadgeDetails(context, badge),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: tierColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge image placeholder
                Container(
                  height: 20.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tierColor.withValues(alpha: 0.3),
                        tierColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14.0),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: tierColor,
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rarity badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          rarity,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tierColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      SizedBox(height: 1.h),

                      // Title
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 0.5.h),

                      // Minted date
                      Text(
                        'Minted ${_formatDate(mintedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      SizedBox(height: 1.h),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: IconButton(
                              icon: const Icon(Icons.link, size: 18),
                              onPressed: () => _openBlockchainExplorer(txHash),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: IconButton(
                              icon: const Icon(Icons.share, size: 18),
                              onPressed: () => _shareBadge(badge),
                              style: IconButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                foregroundColor: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBadgeDetails(BuildContext context, Map<String, dynamic> badge) {
    final theme = Theme.of(context);
    final title = badge['title'] as String;
    final description = badge['description'] as String;
    final tier = badge['tier'] as String;
    final rarity = badge['rarity'] as String;
    final txHash = badge['transaction_hash'] as String;
    final tokenId = badge['token_id'] as int;
    final contractAddress = badge['contract_address'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: 1.h),

            // Description
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 3.h),

            // Blockchain details
            _buildDetailRow(context, 'Tier', tier),
            _buildDetailRow(context, 'Rarity', rarity),
            _buildDetailRow(context, 'Token ID', '#$tokenId'),
            _buildDetailRow(
              context,
              'Contract',
              '${contractAddress.substring(0, 10)}...${contractAddress.substring(contractAddress.length - 8)}',
            ),

            const Spacer(),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openBlockchainExplorer(txHash);
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('View on Explorer'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _shareBadge(badge);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
