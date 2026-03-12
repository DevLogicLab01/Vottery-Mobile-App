import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/vp_service.dart';
import '../../services/gamification_service.dart';
import '../../widgets/custom_icon_widget.dart';

class VPDashboardWidget extends StatefulWidget {
  const VPDashboardWidget({super.key});

  @override
  State<VPDashboardWidget> createState() => _VPDashboardWidgetState();
}

class _VPDashboardWidgetState extends State<VPDashboardWidget>
    with TickerProviderStateMixin {
  late AnimationController _vpAnimationController;
  late Animation<double> _vpAnimation;

  final VPService _vpService = VPService.instance;
  final GamificationService _gamificationService = GamificationService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  int currentVP = 0;
  int targetVP = 0;
  Map<String, dynamic>? _levelData;
  StreamSubscription? _vpStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadVPData();
    _setupRealTimeVPUpdates();
  }

  @override
  void dispose() {
    _vpAnimationController.dispose();
    _vpStreamSubscription?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _vpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _vpAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _vpAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadVPData() async {
    final balanceData = await _vpService.getVPBalance();
    final levelData = await _gamificationService.getUserLevel();

    if (mounted) {
      setState(() {
        currentVP = 0;
        targetVP = balanceData?['available_vp'] as int? ?? 0;
        _levelData = levelData;
      });
      _vpAnimationController.forward(from: 0);
    }
  }

  void _setupRealTimeVPUpdates() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _vpStreamSubscription = _supabase
        .from('vp_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          _updateVPBalance();
        });
  }

  Future<void> _updateVPBalance() async {
    final balanceData = await _vpService.getVPBalance();
    if (mounted && balanceData != null) {
      setState(() {
        currentVP = targetVP;
        targetVP = balanceData['available_vp'] as int? ?? 0;
      });
      _vpAnimationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          children: [
            _buildVPHeader(),
            SizedBox(height: 2.h),
            _buildVPCounter(),
            SizedBox(height: 2.h),
            _buildLevelProgress(),
            SizedBox(height: 2.h),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVPHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text(
              'VP Balance',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const CustomIconWidget(
            iconName: 'refresh',
            color: Colors.white,
            size: 20,
          ),
          onPressed: _loadVPData,
        ),
      ],
    );
  }

  Widget _buildVPCounter() {
    return AnimatedBuilder(
      animation: _vpAnimation,
      builder: (context, child) {
        final animatedValue =
            (currentVP + (targetVP - currentVP) * _vpAnimation.value).round();

        return Column(
          children: [
            Text(
              '$animatedValue VP',
              style: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Vottery Points',
              style: TextStyle(fontSize: 12.sp, color: Colors.white70),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelProgress() {
    if (_levelData == null) {
      return const SizedBox.shrink();
    }

    final currentLevel = _levelData!['current_level'] as int? ?? 1;
    final currentXP = _levelData!['current_xp'] as int? ?? 0;
    final levelTitle = _levelData!['level_title'] as String? ?? 'Novice';
    final vpMultiplier = _levelData!['vp_multiplier'] as double? ?? 1.0;

    final nextLevelTier = GamificationService.levelTiers.firstWhere(
      (tier) => tier['level'] as int > currentLevel,
      orElse: () => GamificationService.levelTiers.last,
    );
    final nextLevelXP = nextLevelTier['xp_required'] as int;
    final progress = nextLevelXP > 0 ? currentXP / nextLevelXP : 1.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $currentLevel - $levelTitle',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${vpMultiplier.toStringAsFixed(2)}x VP',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.yellowAccent,
              ),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '$currentXP / $nextLevelXP XP',
            style: TextStyle(fontSize: 10.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: 'add_circle',
          label: 'Earn',
          onTap: () => _navigateToEarn(),
        ),
        _buildActionButton(
          icon: 'shopping_cart',
          label: 'Spend',
          onTap: () => _navigateToSpend(),
        ),
        _buildActionButton(
          icon: 'history',
          label: 'History',
          onTap: () => _navigateToHistory(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            CustomIconWidget(iconName: icon, color: Colors.white, size: 24),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEarn() {
    Navigator.pushNamed(context, '/vp-economy');
  }

  void _navigateToSpend() {
    Navigator.pushNamed(context, '/vp-economy');
  }

  void _navigateToHistory() {
    Navigator.pushNamed(context, '/vp-economy');
  }
}
