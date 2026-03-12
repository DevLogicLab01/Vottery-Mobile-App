import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/gamification_service.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/daily_challenge_card_widget.dart';
import './widgets/feed_leaderboard_widget.dart';
import './widgets/feed_progression_widget.dart';
import './widgets/mini_game_card_widget.dart';
import './widgets/quest_completion_popup_widget.dart';

/// Feed Quest Dashboard
/// Complete feed gamification hub with daily challenges, progress bars,
/// mini-games, leaderboards, and animated quest completion popups
class FeedQuestDashboard extends StatefulWidget {
  const FeedQuestDashboard({super.key});

  @override
  State<FeedQuestDashboard> createState() => _FeedQuestDashboardState();
}

class _FeedQuestDashboardState extends State<FeedQuestDashboard>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _client = SupabaseService.instance.client;
  final AuthService _authService = AuthService.instance;
  final VPService _vpService = VPService.instance;
  final GamificationService _gamificationService = GamificationService.instance;

  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _dailyChallenges = [];
  List<Map<String, dynamic>> _userProgress = [];
  Map<String, dynamic>? _feedProgression;
  Map<String, dynamic>? _feedStreak;
  Map<String, dynamic>? _vpBalance;
  List<Map<String, dynamic>> _leaderboardData = [];
  List<Map<String, dynamic>> _miniGames = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFeedQuestData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedQuestData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final results = await Future.wait<dynamic>([
        _loadDailyChallenges(),
        _loadUserProgress(userId),
        _loadFeedProgression(userId),
        _loadFeedStreak(userId),
        _vpService.getVPBalance(),
        _loadLeaderboard(),
        _loadMiniGames(),
      ]);

      setState(() {
        _dailyChallenges = results[0] as List<Map<String, dynamic>>;
        _userProgress = results[1] as List<Map<String, dynamic>>;
        _feedProgression = results[2] as Map<String, dynamic>?;
        _feedStreak = results[3] as Map<String, dynamic>?;
        _vpBalance = results[4] as Map<String, dynamic>?;
        _leaderboardData = results[5] as List<Map<String, dynamic>>;
        _miniGames = results[6] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load feed quest data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadDailyChallenges() async {
    final response = await _client
        .from('feed_quests')
        .select()
        .eq('is_active', true)
        .eq('quest_frequency', 'daily')
        .order('vp_reward', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadUserProgress(String userId) async {
    final response = await _client
        .from('user_feed_quest_progress')
        .select('*, feed_quests(*)')
        .eq('user_id', userId)
        .eq('quest_date', DateTime.now().toIso8601String().split('T')[0])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> _loadFeedProgression(String userId) async {
    final response = await _client
        .from('feed_progression_levels')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // Initialize if not exists
    if (response == null) {
      await _client.from('feed_progression_levels').insert({
        'user_id': userId,
        'level_tier': 'bronze_explorer',
        'total_interactions': 0,
        'vp_multiplier': 1.00,
      });
      return {
        'level_tier': 'bronze_explorer',
        'total_interactions': 0,
        'vp_multiplier': 1.00,
      };
    }

    return response;
  }

  Future<Map<String, dynamic>?> _loadFeedStreak(String userId) async {
    final response = await _client
        .from('feed_streaks')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // Initialize if not exists
    if (response == null) {
      await _client.from('feed_streaks').insert({
        'user_id': userId,
        'current_streak': 0,
        'longest_streak': 0,
      });
      return {'current_streak': 0, 'longest_streak': 0};
    }

    return response;
  }

  Future<List<Map<String, dynamic>>> _loadLeaderboard() async {
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final response = await _client
        .from('feed_leaderboards')
        .select('*, users!inner(email, full_name)')
        .eq('leaderboard_type', 'weekly')
        .gte('period_start', weekStart.toIso8601String().split('T')[0])
        .order('total_vp_earned', ascending: false)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadMiniGames() async {
    return [
      {
        'id': '1',
        'game_type': 'quick_poll',
        'title': 'Quick Poll',
        'description': 'Vote in a quick poll',
        'vp_reward': 5,
        'icon': Icons.poll,
      },
      {
        'id': '2',
        'game_type': 'trivia_quiz',
        'title': 'Trivia Quiz',
        'description': 'Answer trivia questions',
        'vp_reward': 10,
        'icon': Icons.quiz,
      },
      {
        'id': '3',
        'game_type': 'prediction_card',
        'title': 'Prediction Card',
        'description': 'Make a prediction',
        'vp_reward': 20,
        'icon': Icons.trending_up,
      },
    ];
  }

  Future<void> _completeQuest(Map<String, dynamic> quest) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Update quest progress
      await _client.from('user_feed_quest_progress').upsert({
        'user_id': userId,
        'quest_id': quest['id'],
        'current_progress': quest['target_count'],
        'target_count': quest['target_count'],
        'is_completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'quest_date': DateTime.now().toIso8601String().split('T')[0],
        'vp_earned': quest['vp_reward'],
      });

      // Award VP
      await _vpService.awardChallengeVP(
        quest['vp_reward'] as int,
        quest['id'] as String,
      );

      // Show animated completion popup
      if (mounted) {
        _showQuestCompletionPopup(quest);
      }

      // Reload data
      await _loadFeedQuestData();
    } catch (e) {
      debugPrint('Complete quest error: $e');
    }
  }

  void _showQuestCompletionPopup(Map<String, dynamic> quest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestCompletionPopupWidget(
        questTitle: quest['title'] as String,
        vpEarned: quest['vp_reward'] as int,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'FeedQuestDashboard',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(
          title: 'Feed Quest Dashboard',
          actions: [
            // VP Balance
            Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
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
                  // Feed Progression Header
                  FeedProgressionWidget(
                    feedProgression: _feedProgression,
                    feedStreak: _feedStreak,
                  ),

                  // Tabs
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF6A11CB),
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFF6A11CB),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Daily Quests'),
                        Tab(text: 'Mini-Games'),
                        Tab(text: 'Leaderboard'),
                        Tab(text: 'Progress'),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDailyChallengesTab(),
                        _buildMiniGamesTab(),
                        _buildLeaderboardTab(),
                        _buildProgressTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDailyChallengesTab() {
    return RefreshIndicator(
      onRefresh: _loadFeedQuestData,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _dailyChallenges.length,
        itemBuilder: (context, index) {
          final challenge = _dailyChallenges[index];
          final progress = _userProgress.firstWhere(
            (p) => p['quest_id'] == challenge['id'],
            orElse: () => {
              'current_progress': 0,
              'target_count': challenge['target_count'],
              'is_completed': false,
            },
          );

          return DailyChallengeCardWidget(
            challenge: challenge,
            progress: progress,
            onComplete: () => _completeQuest(challenge),
          );
        },
      ),
    );
  }

  Widget _buildMiniGamesTab() {
    return GridView.builder(
      padding: EdgeInsets.all(2.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.w,
        childAspectRatio: 1.1,
      ),
      itemCount: _miniGames.length,
      itemBuilder: (context, index) {
        return MiniGameCardWidget(
          game: _miniGames[index],
          onPlay: () {
            // Navigate to mini-game
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Mini-game: ${_miniGames[index]['title']} coming soon!',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return FeedLeaderboardWidget(
      leaderboardData: _leaderboardData,
      currentUserId: _authService.currentUser?.id,
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feed Progression Levels
          _buildProgressCard(
            title: 'Feed Progression',
            child: Column(
              children: [
                _buildLevelTier(
                  'Bronze Feed Explorer',
                  '0-500 interactions',
                  '1.0x multiplier',
                  _feedProgression?['level_tier'] == 'bronze_explorer',
                ),
                SizedBox(height: 1.h),
                _buildLevelTier(
                  'Silver Engager',
                  '500-2000 interactions',
                  '1.5x multiplier',
                  _feedProgression?['level_tier'] == 'silver_engager',
                ),
                SizedBox(height: 1.h),
                _buildLevelTier(
                  'Gold Influencer',
                  '2000+ interactions',
                  '2.0x multiplier',
                  _feedProgression?['level_tier'] == 'gold_influencer',
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Feed Streaks
          _buildProgressCard(
            title: 'Feed Streaks',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Streak',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${_feedStreak?['current_streak'] ?? 0} days',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A11CB),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Longest Streak',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${_feedStreak?['longest_streak'] ?? 0} days',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                if ((_feedStreak?['current_streak'] ?? 0) >= 7) ...[
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            '7-Day Streak Bonus: 2x VP Unlocked!',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Total Stats
          _buildProgressCard(
            title: 'Total Stats',
            child: Column(
              children: [
                _buildStatRow(
                  'Total Interactions',
                  '${_feedProgression?['total_interactions'] ?? 0}',
                ),
                SizedBox(height: 1.h),
                _buildStatRow(
                  'VP Multiplier',
                  '${_feedProgression?['vp_multiplier'] ?? 1.00}x',
                ),
                SizedBox(height: 1.h),
                _buildStatRow(
                  'Quests Completed',
                  '${_userProgress.where((p) => p['is_completed'] == true).length}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({required String title, required Widget child}) {
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

  Widget _buildLevelTier(
    String title,
    String range,
    String multiplier,
    bool isActive,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF6A11CB).withAlpha(26)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF6A11CB) : Colors.grey[300]!,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            color: isActive ? const Color(0xFF6A11CB) : Colors.grey[400],
            size: 24,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF6A11CB)
                        : Colors.grey[700],
                  ),
                ),
                Text(
                  '$range • $multiplier',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
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
            color: const Color(0xFF6A11CB),
          ),
        ),
      ],
    );
  }
}
