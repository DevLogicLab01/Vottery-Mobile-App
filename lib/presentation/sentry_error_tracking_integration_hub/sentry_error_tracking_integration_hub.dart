import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_analytics_service.dart';
import '../../services/sentry_integration_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/error_incident_card_widget.dart';
import './widgets/error_rate_chart_widget.dart';
import './widgets/error_status_header_widget.dart';
import './widgets/feature_error_breakdown_widget.dart';
import './widgets/severity_filter_widget.dart';

class SentryErrorTrackingIntegrationHub extends StatefulWidget {
  const SentryErrorTrackingIntegrationHub({super.key});

  @override
  State<SentryErrorTrackingIntegrationHub> createState() =>
      _SentryErrorTrackingIntegrationHubState();
}

class _SentryErrorTrackingIntegrationHubState
    extends State<SentryErrorTrackingIntegrationHub>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SentryIntegrationService _sentryService =
      SentryIntegrationService.instance;

  late TabController _tabController;
  bool _isLoading = false;
  String? _selectedSeverity;
  Map<String, dynamic> _errorStats = {};
  List<Map<String, dynamic>> _errorIncidents = [];
  Map<String, int> _featureErrorCounts = {};
  Timer? _refreshTimer;

  final List<String> _severityLevels = ['critical', 'high', 'medium', 'low'];
  final List<String> _features = [
    'voting',
    'gamification',
    'payments',
    'social',
    'ai_services',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadErrorData();
    _setupAutoRefresh();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'Sentry Error Tracking Integration Hub',
      screenClass: 'SentryErrorTrackingIntegrationHub',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) {
        _loadErrorData(silent: true);
      }
    });
  }

  Future<void> _loadErrorData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _sentryService.getErrorRateStatistics(),
        _sentryService.getRecentErrorIncidents(
          severity: _selectedSeverity,
          limit: 50,
        ),
        _sentryService.getErrorIncidentsByFeatureCount(),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final incidents = results[1] as List<Map<String, dynamic>>;
      final featureCounts = results[2] as Map<String, int>;

      if (mounted) {
        setState(() {
          _errorStats = stats;
          _errorIncidents = incidents;
          _featureErrorCounts = featureCounts;
        });
      }
    } catch (e) {
      debugPrint('Load error data error: $e');
    } finally {
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'SentryErrorTrackingIntegrationHub',
      onRetry: _loadErrorData,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Sentry Error Tracking',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: theme.appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () => _loadErrorData(),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : _errorIncidents.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.onSurface.withAlpha(128),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No Errors Tracked',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Error incidents will appear here when detected.',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    ElevatedButton.icon(
                      onPressed: _loadErrorData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  ErrorStatusHeaderWidget(errorStats: _errorStats),
                  SeverityFilterWidget(
                    selectedSeverity: _selectedSeverity,
                    severityLevels: _severityLevels,
                    onSeverityChanged: (severity) {
                      setState(() => _selectedSeverity = severity);
                      _loadErrorData();
                    },
                  ),
                  _buildTabBar(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildErrorIncidentsTab(),
                        _buildErrorRateTab(),
                        _buildFeatureBreakdownTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.cardColor,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(153),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Incidents'),
          Tab(text: 'Error Rate'),
          Tab(text: 'By Feature'),
        ],
      ),
    );
  }

  Widget _buildErrorIncidentsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadErrorData(),
      child: _errorIncidents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green.withAlpha(128),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No error incidents',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _errorIncidents.length,
              itemBuilder: (context, index) {
                final incident = _errorIncidents[index];
                return ErrorIncidentCardWidget(
                  incident: incident,
                  onUpdateStatus: (incidentId, status) =>
                      _updateIncidentStatus(incidentId, status),
                );
              },
            ),
    );
  }

  Widget _buildErrorRateTab() {
    return RefreshIndicator(
      onRefresh: () => _loadErrorData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [ErrorRateChartWidget(errorStats: _errorStats)],
      ),
    );
  }

  Widget _buildFeatureBreakdownTab() {
    return RefreshIndicator(
      onRefresh: () => _loadErrorData(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          FeatureErrorBreakdownWidget(
            featureErrorCounts: _featureErrorCounts,
            features: _features,
          ),
        ],
      ),
    );
  }

  Future<void> _updateIncidentStatus(String incidentId, String status) async {
    try {
      final success = await _sentryService.updateErrorIncidentStatus(
        incidentId: incidentId,
        status: status,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incident status updated to $status'),
            backgroundColor: Colors.green,
          ),
        );
        _loadErrorData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update incident: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
