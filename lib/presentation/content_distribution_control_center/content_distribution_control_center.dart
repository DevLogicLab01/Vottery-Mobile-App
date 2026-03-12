import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/enhanced_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/content_ratio_sliders_widget.dart';
import './widgets/global_toggle_switches_widget.dart';
import './widgets/live_monitoring_dashboard_widget.dart';
import './widgets/preset_template_library_widget.dart';
import './widgets/real_time_adjustment_panel_widget.dart';

class ContentDistributionControlCenter extends StatefulWidget {
  const ContentDistributionControlCenter({super.key});

  @override
  State<ContentDistributionControlCenter> createState() =>
      _ContentDistributionControlCenterState();
}

class _ContentDistributionControlCenterState
    extends State<ContentDistributionControlCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Content distribution percentages
  double _electionContentPercentage = 50.0;
  double _socialContentPercentage = 30.0;
  double _adContentPercentage = 20.0;

  // Global toggles
  bool _electionContentEnabled = true;
  bool _socialContentEnabled = true;
  bool _adContentEnabled = true;
  bool _emergencyLockdownActive = false;

  // Monitoring metrics
  Map<String, dynamic> _engagementMetrics = {};
  Map<String, dynamic> _distributionEffectiveness = {};
  List<Map<String, dynamic>> _activeAdjustmentRules = [];

  // Preset templates
  final List<Map<String, dynamic>> _presetTemplates = [
    {
      'id': 'high_engagement',
      'name': 'High Engagement',
      'description': 'Optimized for maximum user engagement',
      'election': 40.0,
      'social': 45.0,
      'ad': 15.0,
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
    {
      'id': 'balanced_discovery',
      'name': 'Balanced Discovery',
      'description': 'Equal distribution for content discovery',
      'election': 33.0,
      'social': 34.0,
      'ad': 33.0,
      'icon': Icons.balance,
      'color': Colors.blue,
    },
    {
      'id': 'election_focused',
      'name': 'Election Focused',
      'description': 'Prioritize election content',
      'election': 60.0,
      'social': 25.0,
      'ad': 15.0,
      'icon': Icons.how_to_vote,
      'color': Colors.purple,
    },
    {
      'id': 'social_priority',
      'name': 'Social Priority',
      'description': 'Emphasize social interactions',
      'election': 25.0,
      'social': 60.0,
      'ad': 15.0,
      'icon': Icons.people,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDistributionData();
    _setupAutoRefresh();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'Content Distribution Control Center',
      screenClass: 'ContentDistributionControlCenter',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 10), (_) {
      if (mounted) {
        _loadDistributionData(silent: true);
      }
    });
  }

  Future<void> _loadDistributionData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      // Load current distribution settings
      final distributionConfig = await _fetchDistributionConfig();
      final metrics = await _fetchEngagementMetrics();
      final effectiveness = await _fetchDistributionEffectiveness();
      final rules = await _fetchActiveAdjustmentRules();

      if (mounted) {
        setState(() {
          _electionContentPercentage =
              distributionConfig['election']?.toDouble() ?? 50.0;
          _socialContentPercentage =
              distributionConfig['social']?.toDouble() ?? 30.0;
          _adContentPercentage = distributionConfig['ad']?.toDouble() ?? 20.0;
          _electionContentEnabled =
              distributionConfig['election_enabled'] ?? true;
          _socialContentEnabled = distributionConfig['social_enabled'] ?? true;
          _adContentEnabled = distributionConfig['ad_enabled'] ?? true;
          _engagementMetrics = metrics;
          _distributionEffectiveness = effectiveness;
          _activeAdjustmentRules = rules;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load distribution data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchDistributionConfig() async {
    // Simulated fetch - replace with actual Supabase query
    await Future.delayed(Duration(milliseconds: 500));
    return {
      'election': _electionContentPercentage,
      'social': _socialContentPercentage,
      'ad': _adContentPercentage,
      'election_enabled': _electionContentEnabled,
      'social_enabled': _socialContentEnabled,
      'ad_enabled': _adContentEnabled,
    };
  }

  Future<Map<String, dynamic>> _fetchEngagementMetrics() async {
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'user_satisfaction': 87.5,
      'engagement_rate': 72.3,
      'retention_rate': 84.1,
      'avg_session_duration': 18.5,
    };
  }

  Future<Map<String, dynamic>> _fetchDistributionEffectiveness() async {
    await Future.delayed(Duration(milliseconds: 300));
    return {
      'election_performance': 92.0,
      'social_performance': 88.5,
      'ad_performance': 76.2,
      'overall_health': 85.6,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchActiveAdjustmentRules() async {
    await Future.delayed(Duration(milliseconds: 300));
    return [
      {
        'id': '1',
        'name': 'Peak Hours Boost',
        'description': 'Increase election content during peak hours',
        'active': true,
        'impact': '+5% engagement',
      },
      {
        'id': '2',
        'name': 'Weekend Social Priority',
        'description': 'Boost social content on weekends',
        'active': true,
        'impact': '+8% retention',
      },
    ];
  }

  void _onRatioChanged(String contentType, double value) {
    setState(() {
      switch (contentType) {
        case 'election':
          _electionContentPercentage = value;
          break;
        case 'social':
          _socialContentPercentage = value;
          break;
        case 'ad':
          _adContentPercentage = value;
          break;
      }
    });
  }

  void _onToggleChanged(String contentType, bool enabled) {
    setState(() {
      switch (contentType) {
        case 'election':
          _electionContentEnabled = enabled;
          break;
        case 'social':
          _socialContentEnabled = enabled;
          break;
        case 'ad':
          _adContentEnabled = enabled;
          break;
      }
    });

    _showToggleConfirmation(contentType, enabled);
  }

  void _showToggleConfirmation(String contentType, bool enabled) {
    final action = enabled ? 'enabled' : 'disabled';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contentType.toUpperCase()} content $action'),
        backgroundColor: enabled ? Colors.green : Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _applyPresetTemplate(Map<String, dynamic> template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply Preset Template'),
        content: Text(
          'Apply "${template['name']}" template?\n\n'
          'Election: ${template['election']}%\n'
          'Social: ${template['social']}%\n'
          'Ads: ${template['ad']}%',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _electionContentPercentage = template['election'];
        _socialContentPercentage = template['social'];
        _adContentPercentage = template['ad'];
      });

      await _saveDistributionConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template "${template['name']}" applied successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _saveDistributionConfig() async {
    try {
      // Save to Supabase - implement actual save logic
      await Future.delayed(Duration(milliseconds: 500));

      EnhancedAnalyticsService.instance.trackUserEngagement(
        action: 'content_distribution_updated',
        screen: 'ContentDistributionControlCenter',
        additionalParams: {
          'election_percentage': _electionContentPercentage,
          'social_percentage': _socialContentPercentage,
          'ad_percentage': _adContentPercentage,
        },
      );
    } catch (e) {
      debugPrint('Save distribution config error: $e');
      rethrow;
    }
  }

  Future<void> _activateEmergencyLockdown() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 2.w),
            Text('Emergency Lockdown'),
          ],
        ),
        content: Text(
          'Activate emergency content distribution lockdown?\n\n'
          'This will:\n'
          '• Pause all content distribution\n'
          '• Enable crisis management protocols\n'
          '• Activate automated moderation\n\n'
          'This action requires admin approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Activate Lockdown'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _emergencyLockdownActive = true;
        _electionContentEnabled = false;
        _socialContentEnabled = false;
        _adContentEnabled = false;
      });

      EnhancedAnalyticsService.instance.trackUserEngagement(
        action: 'emergency_lockdown_activated',
        screen: 'ContentDistributionControlCenter',
        additionalParams: {'timestamp': DateTime.now().toIso8601String()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency lockdown activated'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deactivateEmergencyLockdown() async {
    setState(() {
      _emergencyLockdownActive = false;
      _electionContentEnabled = true;
      _socialContentEnabled = true;
      _adContentEnabled = true;
    });

    EnhancedAnalyticsService.instance.trackUserEngagement(
      action: 'emergency_lockdown_deactivated',
      screen: 'ContentDistributionControlCenter',
      additionalParams: {'timestamp': DateTime.now().toIso8601String()},
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emergency lockdown deactivated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ContentDistributionControlCenter',
      onRetry: _loadDistributionData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Content Distribution Control',
          actions: [
            IconButton(
              icon: Icon(
                _emergencyLockdownActive ? Icons.lock : Icons.lock_open,
                color: _emergencyLockdownActive ? Colors.red : null,
              ),
              onPressed: _emergencyLockdownActive
                  ? _deactivateEmergencyLockdown
                  : _activateEmergencyLockdown,
              tooltip: _emergencyLockdownActive
                  ? 'Deactivate Emergency Lockdown'
                  : 'Activate Emergency Lockdown',
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _loadDistributionData(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDistributionOverviewHeader(),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildControlsTab(),
                          _buildMonitoringTab(),
                          _buildPresetsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDistributionOverviewHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewMetric(
                'Election',
                '${_electionContentPercentage.toStringAsFixed(0)}%',
                Icons.how_to_vote,
                Colors.purple,
                _electionContentEnabled,
              ),
              _buildOverviewMetric(
                'Social',
                '${_socialContentPercentage.toStringAsFixed(0)}%',
                Icons.people,
                Colors.blue,
                _socialContentEnabled,
              ),
              _buildOverviewMetric(
                'Ads',
                '${_adContentPercentage.toStringAsFixed(0)}%',
                Icons.ads_click,
                Colors.green,
                _adContentEnabled,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricChip(
                'Active Rules',
                '${_activeAdjustmentRules.length}',
                Icons.rule,
              ),
              _buildMetricChip(
                'Engagement',
                '${_engagementMetrics['engagement_rate']?.toStringAsFixed(1) ?? '0'}%',
                Icons.trending_up,
              ),
              _buildMetricChip(
                'Health',
                '${_distributionEffectiveness['overall_health']?.toStringAsFixed(1) ?? '0'}%',
                Icons.health_and_safety,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    bool enabled,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
            size: 28,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 1.w),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: [
          Tab(icon: Icon(Icons.tune), text: 'Controls'),
          Tab(icon: Icon(Icons.monitor), text: 'Monitoring'),
          Tab(icon: Icon(Icons.dashboard_customize), text: 'Presets'),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        ContentRatioSlidersWidget(
          electionPercentage: _electionContentPercentage,
          socialPercentage: _socialContentPercentage,
          adPercentage: _adContentPercentage,
          onRatioChanged: _onRatioChanged,
          onSave: _saveDistributionConfig,
        ),
        SizedBox(height: 2.h),
        GlobalToggleSwitchesWidget(
          electionEnabled: _electionContentEnabled,
          socialEnabled: _socialContentEnabled,
          adEnabled: _adContentEnabled,
          onToggleChanged: _onToggleChanged,
        ),
        SizedBox(height: 2.h),
        RealTimeAdjustmentPanelWidget(
          activeRules: _activeAdjustmentRules,
          onRuleToggled: (ruleId, enabled) {
            // Handle rule toggle
          },
        ),
      ],
    );
  }

  Widget _buildMonitoringTab() {
    return LiveMonitoringDashboardWidget(
      engagementMetrics: _engagementMetrics,
      distributionEffectiveness: _distributionEffectiveness,
      onRefresh: () => _loadDistributionData(),
    );
  }

  Widget _buildPresetsTab() {
    return PresetTemplateLibraryWidget(
      templates: _presetTemplates,
      onTemplateApplied: _applyPresetTemplate,
    );
  }
}
