import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/ad_mini_game_widget.dart';
import './widgets/ad_streak_widget.dart';
import './widgets/campaign_quest_chain_widget.dart';

/// Participatory Ads Gamification Center
/// Enhances sponsored election engagement through ad mini-games, campaign quest chains,
/// and hybrid reward systems for advertiser ROI optimization
class ParticipatoryAdsGamificationCenter extends StatefulWidget {
  const ParticipatoryAdsGamificationCenter({super.key});

  @override
  State<ParticipatoryAdsGamificationCenter> createState() =>
      _ParticipatoryAdsGamificationCenterState();
}

class _ParticipatoryAdsGamificationCenterState
    extends State<ParticipatoryAdsGamificationCenter>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = SupabaseService.instance.client;
  final AuthService _authService = AuthService.instance;
  final VPService _vpService = VPService.instance;

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _adMiniGames = [];
  List<Map<String, dynamic>> _campaignQuestChains = [];
  List<Map<String, dynamic>> _userQuestProgress = [];
  List<Map<String, dynamic>> _adLeaderboards = [];
  List<Map<String, dynamic>> _csrImpactMeters = [];
  Map<String, dynamic>? _adStreak;
  Map<String, dynamic>? _vpBalance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAdGamificationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdGamificationData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait<dynamic>([
        _loadAdMiniGames(),
        _loadCampaignQuestChains(),
        _loadUserQuestProgress(userId),
        _loadAdLeaderboards(),
        _loadCSRImpactMeters(),
        _loadAdStreak(userId),
        _vpService.getVPBalance(),
      ]);

      setState(() {
        _adMiniGames = results[0] as List<Map<String, dynamic>>;
        _campaignQuestChains = results[1] as List<Map<String, dynamic>>;
        _userQuestProgress = results[2] as List<Map<String, dynamic>>;
        _adLeaderboards = results[3] as List<Map<String, dynamic>>;
        _csrImpactMeters = results[4] as List<Map<String, dynamic>>;
        _adStreak = results[5] as Map<String, dynamic>?;
        _vpBalance = results[6] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load ad gamification data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadAdMiniGames() async {
    final response = await _client
        .from('ad_mini_games')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadCampaignQuestChains() async {
    final response = await _client
        .from('campaign_quest_chains')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadUserQuestProgress(
    String userId,
  ) async {
    final response = await _client
        .from('user_campaign_quest_progress')
        .select('*, campaign_quest_chains(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadAdLeaderboards() async {
    final today = DateTime.now();
    final monthStart = DateTime(today.year, today.month, 1);

    final response = await _client
        .from('ad_leaderboards')
        .select('*, users!inner(email, full_name)')
        .gte('period_start', monthStart.toIso8601String().split('T')[0])
        .order('prediction_accuracy', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadCSRImpactMeters() async {
    final response = await _client
        .from('csr_impact_meters')
        .select()
        .eq('is_active', true)
        .order('goal_percentage', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> _loadAdStreak(String userId) async {
    final response = await _client
        .from('ad_streaks')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // Initialize if not exists
    if (response == null) {
      await _client.from('ad_streaks').insert({
        'user_id': userId,
        'current_streak': 0,
        'longest_streak': 0,
        'streak_multiplier': 2.00,
      });
      return {
        'current_streak': 0,
        'longest_streak': 0,
        'streak_multiplier': 2.00,
      };
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ParticipatoryAdsGamificationCenter',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(
          title: 'Ads Gamification Center',
          actions: [
            // VP Balance
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 18),
                  SizedBox(width: 1.w),
                  Text(
                    '${_vpBalance?['available_vp'] ?? 0} VP',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Ad Streak Header
                  AdStreakWidget(adStreak: _adStreak),

                  // Tabs
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFFFF6B6B),
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFFFF6B6B),
                      isScrollable: true,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Mini-Games'),
                        Tab(text: 'Quest Chains'),
                        Tab(text: 'Leaderboards'),
                        Tab(text: 'CSR Impact'),
                        Tab(text: 'Analytics'),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMiniGamesTab(),
                        _buildQuestChainsTab(),
                        _buildLeaderboardsTab(),
                        _buildCSRImpactTab(),
                        _buildAnalyticsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMiniGamesTab() {
    if (_adMiniGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.games, size: 60, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No active ad mini-games',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdGamificationData,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _adMiniGames.length,
        itemBuilder: (context, index) {
          return AdMiniGameWidget(
            game: _adMiniGames[index],
            onPlay: () => _playMiniGame(_adMiniGames[index]),
          );
        },
      ),
    );
  }

  Widget _buildQuestChainsTab() {
    return RefreshIndicator(
      onRefresh: _loadAdGamificationData,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _campaignQuestChains.length,
        itemBuilder: (context, index) {
          final questChain = _campaignQuestChains[index];
          final progress = _userQuestProgress.firstWhere(
            (p) => p['quest_chain_id'] == questChain['id'],
            orElse: () => {
              'ads_voted_count': 0,
              'required_votes': questChain['required_ad_votes'],
              'is_completed': false,
            },
          );

          return CampaignQuestChainWidget(
            questChain: questChain,
            progress: progress,
            onVote: () => _voteInQuestChain(questChain),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: const Color(0xFFFF6B6B),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFFFF6B6B),
              labelStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Movie Ads'),
                Tab(text: 'Product Ads'),
                Tab(text: 'CSR Ads'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildLeaderboardList('movie'),
                _buildLeaderboardList('product'),
                _buildLeaderboardList('csr'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(String category) {
    final filteredData = _adLeaderboards
        .where((l) => l['ad_category'] == category)
        .toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          'No leaderboard data available',
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final entry = filteredData[index];
        final isCurrentUser = entry['user_id'] == _authService.currentUser?.id;

        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? const Color(0xFFFF6B6B).withAlpha(26)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentUser
                ? Border.all(color: const Color(0xFFFF6B6B), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                '#${index + 1}',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['users']?['full_name'] ?? 'Anonymous',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Accuracy: ${entry['prediction_accuracy'] ?? 0}%',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCSRImpactTab() {
    return RefreshIndicator(
      onRefresh: _loadAdGamificationData,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _csrImpactMeters.length,
        itemBuilder: (context, index) {
          final impactMeter = _csrImpactMeters[index];
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  impactMeter['campaign_name'] ?? 'CSR Campaign',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  impactMeter['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2.h),
                ElevatedButton(
                  onPressed: () => _voteCSRCampaign(impactMeter),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                  ),
                  child: Text(
                    'Support This Cause',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsCard(
            title: 'Ad Engagement Overview',
            child: Column(
              children: [
                _buildStatRow('Total Ad Votes', '${_userQuestProgress.length}'),
                SizedBox(height: 1.h),
                _buildStatRow(
                  'Quests Completed',
                  '${_userQuestProgress.where((p) => p['is_completed'] == true).length}',
                ),
                SizedBox(height: 1.h),
                _buildStatRow(
                  'Current Streak',
                  '${_adStreak?['current_streak'] ?? 0} days',
                ),
                SizedBox(height: 1.h),
                _buildStatRow(
                  'Streak Multiplier',
                  '${_adStreak?['streak_multiplier'] ?? 2.00}x',
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          _buildAnalyticsCard(
            title: 'VP Distribution Efficiency',
            child: Column(
              children: [
                _buildStatRow('Total VP Earned from Ads', '1,250 VP'),
                SizedBox(height: 1.h),
                _buildStatRow('Average VP per Ad', '42 VP'),
                SizedBox(height: 1.h),
                _buildStatRow('Participation Rate', '87.5%'),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          _buildAnalyticsCard(
            title: 'Hybrid Rewards Summary',
            child: Column(
              children: [
                _buildStatRow('Product Samples Won', '3'),
                SizedBox(height: 1.h),
                _buildStatRow('Discount Codes Earned', '5'),
                SizedBox(height: 1.h),
                _buildStatRow('Early Access Unlocked', '2'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFF6B6B),
          ),
        ),
      ],
    );
  }

  Future<void> _playMiniGame(Map<String, dynamic> game) async {
    // Simulate mini-game play
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final vpEarned =
        (game['min_vp_reward'] as int) +
        (random %
            ((game['max_vp_reward'] as int) - (game['min_vp_reward'] as int)));

    try {
      // Record game result
      await _client.from('user_ad_mini_game_results').insert({
        'user_id': _authService.currentUser!.id,
        'ad_mini_game_id': game['id'],
        'game_result': {'score': random, 'vp_earned': vpEarned},
        'vp_earned': vpEarned,
      });

      // Award VP
      await _vpService.awardSocialVP('ad_mini_game', game['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 You earned $vpEarned VP!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadAdGamificationData();
    } catch (e) {
      debugPrint('Play mini-game error: $e');
    }
  }

  Future<void> _voteInQuestChain(Map<String, dynamic> questChain) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Update quest progress
      await _client.from('user_campaign_quest_progress').upsert({
        'user_id': userId,
        'quest_chain_id': questChain['id'],
        'ads_voted_count': 1,
        'required_votes': questChain['required_ad_votes'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quest progress updated!'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      await _loadAdGamificationData();
    } catch (e) {
      debugPrint('Vote in quest chain error: $e');
    }
  }

  Future<void> _voteCSRCampaign(Map<String, dynamic> impactMeter) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Record CSR contribution
      await _client.from('user_csr_contributions').upsert({
        'user_id': userId,
        'csr_impact_meter_id': impactMeter['id'],
        'votes_contributed': 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for supporting this cause!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadAdGamificationData();
    } catch (e) {
      debugPrint('Vote CSR campaign error: $e');
    }
  }
}
