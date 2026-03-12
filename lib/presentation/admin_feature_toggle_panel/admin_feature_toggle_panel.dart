import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/feature_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/feature_category_section_widget.dart';
import './widgets/feature_audit_log_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../services/carousel_creator_tiers_service.dart';

/// Admin Feature Toggle Panel providing centralized feature enable/disable controls
/// with real-time activation, dependency checking, and audit logging.
class AdminFeatureTogglePanel extends StatefulWidget {
  const AdminFeatureTogglePanel({super.key});

  @override
  State<AdminFeatureTogglePanel> createState() =>
      _AdminFeatureTogglePanelState();
}

class _AdminFeatureTogglePanelState extends State<AdminFeatureTogglePanel>
    with SingleTickerProviderStateMixin {
  final FeatureManagementService _featureService =
      FeatureManagementService.instance;
  final CarouselCreatorTiersService _carouselTiersService =
      CarouselCreatorTiersService.instance;

  late TabController _tabController;
  StreamSubscription? _featureFlagsSubscription;
  List<Map<String, dynamic>> _allFeatures = [];
  final Map<String, List<Map<String, dynamic>>> _featuresByCategory = {};
  bool _isLoading = true;
  String? _selectedCategory;

  final List<String> _categories = [
    'platform',
    'voting_methods',
    'gamification',
    'payments',
    'social',
    'analytics',
    'notifications',
    'authentication',
    'content_moderation',
    'admin_tools',
    'carousel_features',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _featureFlagsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _featureFlagsSubscription = _featureService.streamFeatureFlags().listen((
      features,
    ) {
      if (mounted) {
        setState(() {
          _allFeatures = features;
          _organizeFeaturesByCategory();
          _isLoading = false;
        });
      }
    });

    // Also stream carousel feature flags
    _carouselTiersService.streamFeatureFlags().listen((carouselFlags) {
      if (mounted) {
        setState(() {
          // Merge carousel flags into all features
          final carouselFeatures = carouselFlags.map((flag) {
            return {
              ...flag,
              'category': 'carousel_features',
              'is_enabled': flag['enabled_globally'],
            };
          }).toList();

          // Remove old carousel features and add new ones
          _allFeatures.removeWhere((f) => f['category'] == 'carousel_features');
          _allFeatures.addAll(carouselFeatures);
          _organizeFeaturesByCategory();
        });
      }
    });
  }

  void _organizeFeaturesByCategory() {
    _featuresByCategory.clear();
    for (final category in _categories) {
      _featuresByCategory[category] = _allFeatures
          .where((f) => f['category'] == category)
          .toList();
    }
  }

  Future<void> _handleFeatureToggle({
    required String featureId,
    required String featureName,
    required bool currentStatus,
    List<dynamic>? dependencies,
  }) async {
    // Check dependencies if disabling
    if (currentStatus) {
      final dependentFeatures = _allFeatures
          .where(
            (f) =>
                f['dependencies'] != null &&
                (f['dependencies'] as List).contains(featureName) &&
                f['is_enabled'] == true,
          )
          .toList();

      if (dependentFeatures.isNotEmpty) {
        _showDependencyWarning(featureName, dependentFeatures);
        return;
      }
    }

    // Check if dependencies are enabled when enabling
    if (!currentStatus && dependencies != null && dependencies.isNotEmpty) {
      final disabledDeps = <String>[];
      for (final depName in dependencies) {
        final dep = _allFeatures.firstWhere(
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

    // Show confirmation for critical features
    final isCritical = [
      'stripe_payments',
      'biometric_voting',
      'passkey_auth',
    ].contains(featureName);

    if (isCritical) {
      final confirmed = await _showCriticalFeatureDialog(
        featureName,
        !currentStatus,
      );
      if (!confirmed) return;
    }

    // Update feature
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

  void _showDependencyWarning(
    String featureName,
    List<Map<String, dynamic>> dependentFeatures,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Disable Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The following features depend on "$featureName":',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ...dependentFeatures.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, size: 16.sp),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        f['feature_name'].toString().replaceAll('_', ' '),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please disable dependent features first.',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
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
              style: TextStyle(fontWeight: FontWeight.w600),
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

  Future<bool> _showCriticalFeatureDialog(
    String featureName,
    bool enabling,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24.sp),
            SizedBox(width: 2.w),
            const Text('Critical Feature'),
          ],
        ),
        content: Text(
          'You are about to ${enabling ? "enable" : "disable"} "$featureName". '
          'This is a critical feature that affects core platform functionality. '
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: enabling ? Colors.green : Colors.red,
            ),
            child: Text(enabling ? 'Enable' : 'Disable'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleBulkAction(String category, bool enable) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk ${enable ? "Enable" : "Disable"}'),
        content: Text(
          'Are you sure you want to ${enable ? "enable" : "disable"} all features in "${category.replaceAll('_', ' ')}" category?',
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

    if (confirmed != true) return;

    final success = await _featureService.bulkUpdateByCategory(
      category: category,
      isEnabled: enable,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Bulk action completed successfully'
                : 'Bulk action failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AdminFeatureTogglePanel',
      onRetry: () {
        setState(() => _isLoading = true);
        _setupRealtimeSubscription();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Feature Toggle Panel',
            variant: CustomAppBarVariant.standard,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, size: 24.sp),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _setupRealtimeSubscription();
                },
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [_buildFeaturesTab(), _buildAuditLogTab()],
              ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(),
          SizedBox(height: 3.h),
          ..._categories.map((category) {
            final features = _featuresByCategory[category] ?? [];
            if (features.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                FeatureCategorySectionWidget(
                  category: category,
                  features: features,
                  onFeatureToggle: _handleFeatureToggle,
                  onBulkAction: _handleBulkAction,
                ),
                SizedBox(height: 2.h),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final totalFeatures = _allFeatures.length;
    final enabledFeatures = _allFeatures
        .where((f) => f['is_enabled'] == true)
        .length;
    final disabledFeatures = totalFeatures - enabledFeatures;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Features',
            totalFeatures.toString(),
            Icons.flag,
            Colors.blue,
          ),
          _buildStatItem(
            'Enabled',
            enabledFeatures.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildStatItem(
            'Disabled',
            disabledFeatures.toString(),
            Icons.cancel,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAuditLogTab() {
    return FeatureAuditLogWidget();
  }
}
