import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/feature_management_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/expandable_toggle_section_widget.dart';
import './widgets/toggle_history_panel_widget.dart';

class EnhancedAdminFeatureTogglePanel extends StatefulWidget {
  const EnhancedAdminFeatureTogglePanel({super.key});

  @override
  State<EnhancedAdminFeatureTogglePanel> createState() =>
      _EnhancedAdminFeatureTogglePanelState();
}

class _EnhancedAdminFeatureTogglePanelState
    extends State<EnhancedAdminFeatureTogglePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FeatureManagementService _featureService =
      FeatureManagementService.instance;

  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _toggleHistory = [];
  final Map<String, bool> _toggleStates = {};

  static const List<Map<String, dynamic>> _predictionPoolToggles = [
    {
      'toggle_name': 'enable_prediction_pools',
      'display_name': 'Enable Prediction Pools',
      'description': 'Allow users to predict election outcomes',
      'is_critical': true,
    },
    {
      'toggle_name': 'enable_private_pools',
      'display_name': 'Enable Private Pools',
      'description': 'Allow private prediction pools in groups',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_oracle_auto_resolution',
      'display_name': 'Enable Oracle Auto-Resolution',
      'description': 'Automatically resolve pools on election close',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_brier_scoring',
      'display_name': 'Enable Brier Scoring',
      'description': 'Use Brier score for prediction accuracy',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_prediction_leaderboards',
      'display_name': 'Enable Prediction Leaderboards',
      'description': 'Show prediction accuracy leaderboards',
      'is_critical': false,
    },
  ];

  static const List<Map<String, dynamic>> _adGamificationToggles = [
    {
      'toggle_name': 'enable_ad_mini_games',
      'display_name': 'Enable Ad Mini-Games',
      'description': 'Interactive mini-games in participatory ads',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_spin_wheel',
      'display_name': 'Enable Spin Wheel',
      'description': 'Spin wheel reward mechanic in ads',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_ad_quests',
      'display_name': 'Enable Ad Quests',
      'description': 'Quest chains tied to ad campaigns',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_campaign_chains',
      'display_name': 'Enable Campaign Chains',
      'description': 'Multi-ad campaign quest chains',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_impact_meters',
      'display_name': 'Enable Impact Meters',
      'description': 'CSR ad impact progress meters',
      'is_critical': false,
    },
  ];

  static const List<Map<String, dynamic>> _feedGamificationToggles = [
    {
      'toggle_name': 'enable_feed_quests',
      'display_name': 'Enable Feed Quests',
      'description': 'Daily/weekly quests in social feed',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_feed_progression_levels',
      'display_name': 'Enable Feed Progression Levels',
      'description': 'Level-up system for feed engagement',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_feed_streaks',
      'display_name': 'Enable Feed Streaks',
      'description': 'Daily feed engagement streaks',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_feed_power_ups',
      'display_name': 'Enable Feed Power-Ups',
      'description': 'VP-redeemable feed power-ups',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_adventure_paths',
      'display_name': 'Enable Adventure Paths',
      'description': 'AI-curated themed feed adventure paths',
      'is_critical': false,
    },
  ];

  static const List<Map<String, dynamic>> _vpRedemptionToggles = [
    {
      'toggle_name': 'platform_perks_redeemable',
      'display_name': 'Platform Perks Redeemable',
      'description': 'Allow VP redemption for platform perks',
      'is_critical': false,
    },
    {
      'toggle_name': 'election_enhancements_redeemable',
      'display_name': 'Election Enhancements Redeemable',
      'description': 'Allow VP redemption for election boosts',
      'is_critical': false,
    },
    {
      'toggle_name': 'social_rewards_redeemable',
      'display_name': 'Social Rewards Redeemable',
      'description': 'Allow VP redemption for social rewards',
      'is_critical': false,
    },
    {
      'toggle_name': 'real_world_rewards_redeemable',
      'display_name': 'Real-World Rewards Redeemable',
      'description': 'Allow VP redemption for real-world rewards',
      'is_critical': true,
    },
    {
      'toggle_name': 'vip_tiers_redeemable',
      'display_name': 'VIP Tiers Redeemable',
      'description': 'Allow VP redemption for VIP tier access',
      'is_critical': false,
    },
  ];

  static const List<Map<String, dynamic>> _questSystemToggles = [
    {
      'toggle_name': 'enable_daily_quests',
      'display_name': 'Enable Daily Quests',
      'description': 'Daily challenge quests for users',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_weekly_quests',
      'display_name': 'Enable Weekly Quests',
      'description': 'Weekly challenge quests for users',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_ai_quest_generation',
      'display_name': 'Enable AI Quest Generation',
      'description': 'OpenAI-powered personalized quest generation',
      'is_critical': false,
    },
    {
      'toggle_name': 'enable_quest_chains',
      'display_name': 'Enable Quest Chains',
      'description': 'Multi-step quest chain sequences',
      'is_critical': false,
    },
  ];

  List<Map<String, dynamic>> get _allSections => [
    {
      'name': 'Prediction Pools',
      'icon': Icons.pool,
      'color': Colors.blue,
      'toggles': _predictionPoolToggles,
    },
    {
      'name': 'Participatory Ads Gamification',
      'icon': Icons.campaign,
      'color': Colors.orange,
      'toggles': _adGamificationToggles,
    },
    {
      'name': 'Feed Gamification',
      'icon': Icons.dynamic_feed,
      'color': Colors.green,
      'toggles': _feedGamificationToggles,
    },
    {
      'name': 'VP Redemption Categories',
      'icon': Icons.redeem,
      'color': Colors.purple,
      'toggles': _vpRedemptionToggles,
    },
    {
      'name': 'Quest System',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
      'toggles': _questSystemToggles,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeToggles();
    _loadToggleHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeToggles() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseService.instance.client;
      final rows = await client
          .from('feature_toggles')
          .select()
          .order('toggle_name');
      final dbToggles = List<Map<String, dynamic>>.from(rows);
      final Map<String, bool> states = {};
      for (final row in dbToggles) {
        states[row['toggle_name'] as String] =
            row['is_enabled'] as bool? ?? true;
      }
      for (final section in _allSections) {
        for (final toggle in section['toggles'] as List<Map<String, dynamic>>) {
          final name = toggle['toggle_name'] as String;
          if (!states.containsKey(name)) states[name] = true;
        }
      }
      if (mounted) {
        setState(() {
          _toggleStates.addAll(states);
          _isLoading = false;
        });
      }
    } catch (e) {
      for (final section in _allSections) {
        for (final toggle in section['toggles'] as List<Map<String, dynamic>>) {
          _toggleStates[toggle['toggle_name'] as String] = true;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadToggleHistory() async {
    try {
      final logs = await _featureService.getFeatureAuditLogs(limit: 30);
      if (mounted) {
        setState(() {
          _toggleHistory = logs.map((log) {
            final newVal = log['new_value'] as Map?;
            final oldVal = log['old_value'] as Map?;
            return {
              'toggle_name': log['target_id'] as String? ?? '',
              'previous_state': oldVal?['is_enabled'] as bool? ?? false,
              'new_state': newVal?['is_enabled'] as bool? ?? false,
              'changed_by':
                  (log['user_profiles'] as Map?)?['name'] as String? ?? 'Admin',
              'timestamp': _formatTimestamp(log['timestamp'] as String? ?? ''),
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  String _formatTimestamp(String ts) {
    try {
      final dt = DateTime.parse(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return ts;
    }
  }

  Future<void> _setToggleState(String toggleName, bool value) async {
    final prevValue = _toggleStates[toggleName] ?? false;
    setState(() => _toggleStates[toggleName] = value);
    try {
      final client = SupabaseService.instance.client;
      final userId = AuthService.instance.currentUser?.id;
      await client.from('feature_toggles').upsert({
        'toggle_name': toggleName,
        'toggle_category': _getCategoryForToggle(toggleName),
        'is_enabled': value,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': userId,
      }, onConflict: 'toggle_name');
      setState(() {
        _toggleHistory.insert(0, {
          'toggle_name': toggleName,
          'previous_state': prevValue,
          'new_state': value,
          'changed_by': 'Admin',
          'timestamp': 'Just now',
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$toggleName ${value ? 'enabled' : 'disabled'}'),
            backgroundColor: value ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _toggleStates[toggleName] = prevValue);
    }
  }

  String _getCategoryForToggle(String toggleName) {
    for (final section in _allSections) {
      final toggles = section['toggles'] as List<Map<String, dynamic>>;
      if (toggles.any((t) => t['toggle_name'] == toggleName)) {
        return (section['name'] as String).toLowerCase().replaceAll(' ', '_');
      }
    }
    return 'general';
  }

  Future<void> _bulkUpdate(String category, bool value) async {
    final section = _allSections.firstWhere(
      (s) => s['name'] == category,
      orElse: () => <String, dynamic>{},
    );
    if (section.isEmpty) return;
    for (final toggle in section['toggles'] as List<Map<String, dynamic>>) {
      await _setToggleState(toggle['toggle_name'] as String, value);
    }
  }

  List<Map<String, dynamic>> _getFilteredToggles(
    List<Map<String, dynamic>> toggles,
  ) {
    if (_searchQuery.isEmpty) return toggles;
    return toggles
        .where(
          (t) =>
              (t['display_name'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              (t['description'] as String).toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  List<Map<String, dynamic>> _getTogglesWithState(
    List<Map<String, dynamic>> toggles,
  ) {
    return toggles
        .map(
          (t) => {...t, 'is_enabled': _toggleStates[t['toggle_name']] ?? true},
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Enhanced Admin Feature Toggle Panel',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Feature Toggle Panel',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.blue[700],
            unselectedLabelColor: Colors.grey[500],
            indicatorColor: Colors.blue[700],
            labelStyle: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Toggles'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildTogglesTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  Widget _buildTogglesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search toggles by name or category...',
              hintStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey[400],
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 16.sp,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 1.h),
            ),
            style: GoogleFonts.inter(fontSize: 11.sp),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(3.w),
            children: _allSections.map((section) {
              final rawToggles =
                  section['toggles'] as List<Map<String, dynamic>>;
              final filteredToggles = _getFilteredToggles(rawToggles);
              if (filteredToggles.isEmpty && _searchQuery.isNotEmpty) {
                return const SizedBox();
              }
              final togglesWithState = _getTogglesWithState(filteredToggles);
              return ExpandableToggleSectionWidget(
                categoryName: section['name'] as String,
                categoryIcon: section['icon'] as IconData,
                categoryColor: section['color'] as Color,
                toggles: togglesWithState,
                onToggleChanged: _setToggleState,
                onEnableAll: () => _bulkUpdate(section['name'] as String, true),
                onDisableAll: () =>
                    _bulkUpdate(section['name'] as String, false),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        ToggleHistoryPanelWidget(
          history: _toggleHistory,
          onExport: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exporting toggle history...')),
          ),
        ),
      ],
    );
  }
}
