import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/feature_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../admin_feature_toggle_panel/widgets/feature_toggle_card_widget.dart';

class AdminGamificationTogglePanel extends StatefulWidget {
  const AdminGamificationTogglePanel({super.key});

  @override
  State<AdminGamificationTogglePanel> createState() =>
      _AdminGamificationTogglePanelState();
}

class _AdminGamificationTogglePanelState
    extends State<AdminGamificationTogglePanel> {
  final FeatureManagementService _featureService =
      FeatureManagementService.instance;

  StreamSubscription? _featureFlagsSubscription;
  List<Map<String, dynamic>> _gamificationFeatures = [];
  bool _isLoading = true;
  bool _masterToggle = true;

  final List<String> _gamificationFeatureNames = [
    'vp_system',
    'progression_levels',
    'badges_achievements',
    'streaks_system',
    'leaderboards',
    'prediction_pools',
    'daily_weekly_challenges',
    'rewards_shop',
    'feed_gamification',
    'ad_gamification',
    'jolts_gamification',
  ];

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _featureFlagsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _featureFlagsSubscription = _featureService.streamFeatureFlags().listen((
      features,
    ) {
      if (mounted) {
        final gamificationFeatures = features
            .where((f) => f['category'] == 'gamification')
            .toList();

        setState(() {
          _gamificationFeatures = gamificationFeatures;
          _updateMasterToggle();
          _isLoading = false;
        });
      }
    });
  }

  void _updateMasterToggle() {
    if (_gamificationFeatures.isEmpty) {
      _masterToggle = false;
      return;
    }

    final allEnabled = _gamificationFeatures.every(
      (f) => f['is_enabled'] == true,
    );
    _masterToggle = allEnabled;
  }

  Future<void> _handleMasterToggle(bool value) async {
    final confirmed = await _showMasterToggleConfirmation(value);
    if (!confirmed) return;

    for (final feature in _gamificationFeatures) {
      await _featureService.updateFeatureFlag(
        featureId: feature['id'] as String,
        isEnabled: value,
        reason: 'Master gamification toggle ${value ? "enabled" : "disabled"}',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All gamification features ${value ? "enabled" : "disabled"}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<bool> _showMasterToggleConfirmation(bool enable) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${enable ? "Enable" : "Disable"} All Gamification'),
        content: Text(
          'This will ${enable ? "enable" : "disable"} all 11 gamification features including VP system, levels, badges, streaks, leaderboards, prediction pools, challenges, rewards shop, and feed/ad/jolts gamification.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: enable ? Colors.green : Colors.red,
            ),
            child: Text(enable ? 'Enable All' : 'Disable All'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleFeatureToggle({
    required String featureId,
    required String featureName,
    required bool currentStatus,
    List<dynamic>? dependencies,
  }) async {
    // Check dependencies if enabling
    if (!currentStatus && dependencies != null && dependencies.isNotEmpty) {
      final disabledDeps = <String>[];
      for (final depName in dependencies) {
        final dep = _gamificationFeatures.firstWhere(
          (f) => f['feature_name'] == depName,
          orElse: () => <String, dynamic>{},
        );
        if (dep.isNotEmpty && dep['is_enabled'] == false) {
          disabledDeps.add(depName);
        }
      }

      if (disabledDeps.isNotEmpty) {
        _showEnableDependenciesDialog(featureName, disabledDeps);
        return;
      }
    }

    final success = await _featureService.updateFeatureFlag(
      featureId: featureId,
      isEnabled: !currentStatus,
      reason: 'Manual toggle by admin',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Feature ${!currentStatus ? "enabled" : "disabled"} successfully'
                : 'Failed to update feature',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showEnableDependenciesDialog(
    String featureName,
    List<String> disabledDeps,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Missing Dependencies'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable "$featureName", you must first enable:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ...disabledDeps.map(
              (dep) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16.sp, color: Colors.orange),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        dep.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Admin Gamification Toggle Panel',
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Admin Gamification Toggle Panel'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMasterToggleCard(),
                    SizedBox(height: 2.h),
                    Text(
                      'Individual Feature Controls',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Toggle individual gamification features below. Some features depend on others and must be enabled in order.',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ..._gamificationFeatures.map(
                      (feature) => FeatureToggleCardWidget(
                        feature: feature,
                        onToggle: _handleFeatureToggle,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMasterToggleCard() {
    final enabledCount = _gamificationFeatures
        .where((f) => f['is_enabled'] == true)
        .length;
    final totalCount = _gamificationFeatures.length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Master Gamification Toggle',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '$enabledCount of $totalCount features enabled',
                      style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _masterToggle,
                onChanged: _handleMasterToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Enable or disable all gamification features at once. This includes VP system, progression levels, badges, streaks, leaderboards, prediction pools, challenges, rewards shop, and feed/ad/jolts gamification.',
            style: TextStyle(fontSize: 11.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
