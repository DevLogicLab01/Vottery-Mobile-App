import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import './widgets/ml_click_prediction_widget.dart';
import './widgets/micro_interaction_tracking_widget.dart';
import './widgets/engagement_hotspot_detection_widget.dart';
import './widgets/conversion_zone_analysis_widget.dart';
import './widgets/interactive_heatmap_overlay_widget.dart';
import './widgets/automated_optimization_engine_widget.dart';

class AdvancedBehavioralHeatmapsMlAnalyticsHub extends StatefulWidget {
  const AdvancedBehavioralHeatmapsMlAnalyticsHub({super.key});

  @override
  State<AdvancedBehavioralHeatmapsMlAnalyticsHub> createState() =>
      _AdvancedBehavioralHeatmapsMlAnalyticsHubState();
}

class _AdvancedBehavioralHeatmapsMlAnalyticsHubState
    extends State<AdvancedBehavioralHeatmapsMlAnalyticsHub> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _analytics = AnalyticsService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _heatmapStatus = {};
  List<Map<String, dynamic>> _activeTrackingSessions = [];
  RealtimeChannel? _heatmapChannel;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
    _subscribeToHeatmapUpdates();
    _trackScreenView();
  }

  @override
  void dispose() {
    _heatmapChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _trackScreenView() async {
    await _analytics.trackUserEngagement(
      action: 'view_heatmap_analytics',
      screen: 'advanced_behavioral_heatmaps',
    );
  }

  Future<void> _loadHeatmapData() async {
    setState(() => _isLoading = true);

    try {
      final statusResponse = await _client
          .from('heatmap_tracking_status')
          .select('*')
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      final sessionsResponse = await _client
          .from('heatmap_tracking_sessions')
          .select('*')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(10);

      if (mounted) {
        setState(() {
          _heatmapStatus =
              statusResponse ??
              {
                'active_sessions': 0,
                'ml_model_accuracy': 0.0,
                'total_interactions': 0,
                'screens_tracked': 0,
              };
          _activeTrackingSessions = List<Map<String, dynamic>>.from(
            sessionsResponse,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load heatmap data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToHeatmapUpdates() {
    _heatmapChannel = _client
        .channel('heatmap_updates_${_auth.currentUser!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'heatmap_tracking_sessions',
          callback: (payload) {
            _loadHeatmapData();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Behavioral Heatmaps & ML Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.analytics,
                    size: 12.w,
                    color: theme.colorScheme.onPrimary,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Heatmap Analytics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
              selected: _selectedTab == 0,
              onTap: () {
                setState(() => _selectedTab = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('ML Predictions'),
              selected: _selectedTab == 1,
              onTap: () {
                setState(() => _selectedTab = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.touch_app),
              title: const Text('Micro-Interactions'),
              selected: _selectedTab == 2,
              onTap: () {
                setState(() => _selectedTab = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.whatshot),
              title: const Text('Hotspot Detection'),
              selected: _selectedTab == 3,
              onTap: () {
                setState(() => _selectedTab = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Optimization'),
              selected: _selectedTab == 4,
              onTap: () {
                setState(() => _selectedTab = 4);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(theme),
                  SizedBox(height: 3.h),
                  _buildTabContent(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusOverview(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: theme.colorScheme.onPrimary,
                size: 8.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Heatmap Status Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  theme,
                  'Active Sessions',
                  '${_heatmapStatus['active_sessions'] ?? 0}',
                  Icons.track_changes,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatusMetric(
                  theme,
                  'ML Accuracy',
                  '${((_heatmapStatus['ml_model_accuracy'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                  Icons.psychology,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetric(
                  theme,
                  'Interactions',
                  '${_heatmapStatus['total_interactions'] ?? 0}',
                  Icons.touch_app,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatusMetric(
                  theme,
                  'Screens Tracked',
                  '${_heatmapStatus['screens_tracked'] ?? 178}',
                  Icons.screen_search_desktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onPrimary, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    switch (_selectedTab) {
      case 1:
        return const MlClickPredictionWidget();
      case 2:
        return const MicroInteractionTrackingWidget();
      case 3:
        return const EngagementHotspotDetectionWidget();
      case 4:
        return const AutomatedOptimizationEngineWidget();
      default:
        return Column(
          children: [
            const InteractiveHeatmapOverlayWidget(),
            SizedBox(height: 3.h),
            const ConversionZoneAnalysisWidget(),
          ],
        );
    }
  }
}
