import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

import '../../services/vp_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/reward_card_widget.dart';
import './widgets/redemption_confirmation_modal_widget.dart';

class RewardsShopHub extends StatefulWidget {
  const RewardsShopHub({super.key});

  @override
  State<RewardsShopHub> createState() => _RewardsShopHubState();
}

class _RewardsShopHubState extends State<RewardsShopHub>
    with SingleTickerProviderStateMixin {
  final VPService _vpService = VPService.instance;
  final _supabase = SupabaseService.instance.client;

  late TabController _tabController;
  StreamSubscription? _vpBalanceSubscription;
  int _currentVP = 0;
  int _recentPurchases = 0;
  List<Map<String, dynamic>> _allRewards = [];
  final Map<String, List<Map<String, dynamic>>> _rewardsByCategory = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showConfetti = false;

  final List<String> _categories = [
    'platform_perks',
    'election_enhancements',
    'social_rewards',
    'real_world_rewards',
    'vip_tiers',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vpBalanceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadVPBalance(),
      _loadRewards(),
      _loadRecentPurchases(),
    ]);
    _setupVPBalanceStream();
  }

  Future<void> _loadVPBalance() async {
    final balance = await _vpService.getVPBalance();
    if (mounted && balance != null) {
      setState(() {
        _currentVP = balance['available_vp'] as int;
      });
    }
  }

  void _setupVPBalanceStream() {
    _vpBalanceSubscription = _supabase
        .from('vp_balance')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (mounted && data.isNotEmpty) {
            setState(() {
              _currentVP = data.first['available_vp'] as int;
            });
          }
        });
  }

  Future<void> _loadRewards() async {
    try {
      final response = await _supabase
          .from('rewards_shop_items')
          .select()
          .eq('is_available', true)
          .order('display_order');

      if (mounted) {
        setState(() {
          _allRewards = List<Map<String, dynamic>>.from(response);
          _organizeRewardsByCategory();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRecentPurchases() async {
    try {
      final response = await _supabase
          .from('vp_redemptions')
          .select('id')
          .gte(
            'redeemed_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          );

      if (mounted) {
        setState(() {
          _recentPurchases = (response as List).length;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _organizeRewardsByCategory() {
    _rewardsByCategory.clear();
    for (final category in _categories) {
      _rewardsByCategory[category] = _allRewards
          .where((r) => r['category'] == category)
          .where((r) {
            if (_searchQuery.isEmpty) return true;
            final title = (r['title'] as String).toLowerCase();
            final description = (r['description'] as String).toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || description.contains(query);
          })
          .toList();
    }
  }

  String _getCategoryDisplayName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Future<void> _handleRedemption(Map<String, dynamic> reward) async {
    final vpCost = reward['vp_cost'] as int;

    if (_currentVP < vpCost) {
      _showInsufficientVPDialog(vpCost);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => RedemptionConfirmationModalWidget(
        reward: reward,
        currentVP: _currentVP,
      ),
    );

    if (confirmed == true) {
      await _processRedemption(reward);
    }
  }

  Future<void> _processRedemption(Map<String, dynamic> reward) async {
    try {
      final response = await _supabase.rpc(
        'process_vp_redemption',
        params: {
          'p_user_id': _supabase.auth.currentUser!.id,
          'p_item_id': reward['id'],
        },
      );

      if (response['success'] == true) {
        setState(() => _showConfetti = true);
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _showConfetti = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${reward['title']} redeemed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadVPBalance();
        await _loadRecentPurchases();
      } else {
        _showErrorDialog(response['error'] as String);
      }
    } catch (e) {
      _showErrorDialog('Failed to process redemption');
    }
  }

  void _showInsufficientVPDialog(int required) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient VP'),
        content: Text(
          'You need $required VP to redeem this reward.\n\nCurrent balance: $_currentVP VP\nNeeded: ${required - _currentVP} more VP',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redemption Failed'),
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
    return ErrorBoundaryWrapper(
      screenName: 'RewardsShopHub',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Rewards Shop',
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                // Navigate to redemption history
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildPaymentAuditBanner(),
                _buildSearchBar(),
                _buildTabBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: _categories.map((category) {
                            final rewards = _rewardsByCategory[category] ?? [];
                            return _buildRewardsList(category, rewards);
                          }).toList(),
                        ),
                ),
              ],
            ),
            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset(
                    'https://assets10.lottiefiles.com/packages/lf20_rovf9gzu.json',
                    repeat: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAuditBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Cash-equivalent redemptions use Stripe or bank transfer. All redemptions are logged on-chain for auditability.',
              style: TextStyle(fontSize: 11.sp, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your VP Balance',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '$_currentVP VP',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_recentPurchases',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Recent Purchases',
                      style: TextStyle(fontSize: 10.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search rewards...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _organizeRewardsByCategory();
          });
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.purple,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.purple,
      tabs: _categories.map((category) {
        return Tab(text: _getCategoryDisplayName(category));
      }).toList(),
    );
  }

  Widget _buildRewardsList(
    String category,
    List<Map<String, dynamic>> rewards,
  ) {
    if (rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No rewards available',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRewards,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          return RewardCardWidget(
            reward: rewards[index],
            currentVP: _currentVP,
            onRedeem: () => _handleRedemption(rewards[index]),
          );
        },
      ),
    );
  }
}
