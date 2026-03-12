import 'package:flutter/material.dart';

import '../../services/nft_achievement_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/wallet_status_header_widget.dart';
import './widgets/tier_progression_dashboard_widget.dart';
import './widgets/nft_badge_gallery_widget.dart';
import './widgets/minting_center_widget.dart';
import './widgets/achievement_leaderboard_widget.dart';

/// NFT Achievement System Hub
/// Comprehensive blockchain-verified achievement management with Ethereum integration
class NFTAchievementSystemHub extends StatefulWidget {
  const NFTAchievementSystemHub({super.key});

  @override
  State<NFTAchievementSystemHub> createState() =>
      _NFTAchievementSystemHubState();
}

class _NFTAchievementSystemHubState extends State<NFTAchievementSystemHub>
    with SingleTickerProviderStateMixin {
  final NFTAchievementService _nftService = NFTAchievementService.instance;

  late TabController _tabController;
  Map<String, dynamic> _walletStatus = {};
  Map<String, dynamic> _currentTier = {};
  List<Map<String, dynamic>> _nftBadges = [];
  Map<String, dynamic> _mintingQueue = {};
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final walletStatus = await _nftService.getWalletStatus();
    final tier = await _nftService.getUserTier();
    final badges = await _nftService.getUserNFTBadges();
    final queue = await _nftService.getMintingQueueStatus();
    final leaderboard = await _nftService.getTopBadgeCollectors(limit: 20);

    if (mounted) {
      setState(() {
        _walletStatus = walletStatus;
        _currentTier = tier;
        _nftBadges = badges;
        _mintingQueue = queue;
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'NFTAchievementSystemHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'NFT Achievement System',
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.onPrimary),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    // Wallet status header
                    WalletStatusHeaderWidget(
                      walletStatus: _walletStatus,
                      currentTier: _currentTier,
                      mintingQueue: _mintingQueue,
                    ),

                    // Tab bar
                    Container(
                      color: theme.colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        indicatorColor: theme.colorScheme.primary,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Tier Progress'),
                          Tab(text: 'NFT Gallery'),
                          Tab(text: 'Mint Center'),
                          Tab(text: 'Leaderboard'),
                        ],
                      ),
                    ),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tier Progression
                          TierProgressionDashboardWidget(
                            currentTier: _currentTier,
                            onRefresh: _refreshData,
                          ),

                          // NFT Badge Gallery
                          NFTBadgeGalleryWidget(
                            badges: _nftBadges,
                            onRefresh: _refreshData,
                          ),

                          // Minting Center
                          MintingCenterWidget(onMintComplete: _refreshData),

                          // Leaderboard
                          AchievementLeaderboardWidget(
                            leaderboard: _leaderboard,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
