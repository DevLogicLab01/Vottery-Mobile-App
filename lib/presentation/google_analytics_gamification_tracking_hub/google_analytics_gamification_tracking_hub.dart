import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../services/ga4_analytics_service.dart';
import './widgets/event_tracking_overview_widget.dart';
import './widgets/cohort_analysis_widget.dart';
import './widgets/retention_correlation_widget.dart';
import './widgets/custom_dimensions_widget.dart';
import './widgets/funnel_analysis_widget.dart';

class GoogleAnalyticsGamificationTrackingHub extends StatefulWidget {
  const GoogleAnalyticsGamificationTrackingHub({super.key});

  @override
  State<GoogleAnalyticsGamificationTrackingHub> createState() =>
      _GoogleAnalyticsGamificationTrackingHubState();
}

class _GoogleAnalyticsGamificationTrackingHubState
    extends State<GoogleAnalyticsGamificationTrackingHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GA4AnalyticsService _ga4Service = GA4AnalyticsService.instance;
  bool _isLoading = true;
  Map<String, dynamic> _trackingData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTrackingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrackingData() async {
    setState(() => _isLoading = true);

    try {
      // Load GA4 tracking data from Supabase
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        final response = await supabase
            .from('ga4_gamification_events')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(100);

        setState(() {
          _trackingData = {
            'events': response,
            'total_events': response.length,
            'vp_earned_events': response
                .where((e) => e['event_name'] == 'vp_earned')
                .length,
            'vp_spent_events': response
                .where((e) => e['event_name'] == 'vp_spent')
                .length,
            'badge_unlocked_events': response
                .where((e) => e['event_name'] == 'badge_unlocked')
                .length,
            'streak_milestone_events': response
                .where((e) => e['event_name'] == 'streak_milestone')
                .length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load tracking data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadTrackingData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'GA4 Gamification Tracking',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: ErrorBoundaryWrapper(
        screenName: 'GA4 Gamification Tracking Hub',
        child: Column(
          children: [
            _buildTrackingStatusHeader(theme),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.colorScheme.primary,
              labelStyle: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Event Tracking'),
                Tab(text: 'Cohort Analysis'),
                Tab(text: 'Retention'),
                Tab(text: 'Custom Dimensions'),
                Tab(text: 'Funnel Analysis'),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? ShimmerSkeletonLoader(child: Container())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        EventTrackingOverviewWidget(
                          trackingData: _trackingData,
                        ),
                        CohortAnalysisWidget(trackingData: _trackingData),
                        RetentionCorrelationWidget(trackingData: _trackingData),
                        CustomDimensionsWidget(trackingData: _trackingData),
                        FunnelAnalysisWidget(trackingData: _trackingData),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingStatusHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withAlpha(204),
            theme.colorScheme.secondary.withAlpha(204),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.analytics, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking Status: Active',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_trackingData['total_events'] ?? 0} events tracked',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16.sp),
                SizedBox(width: 1.w),
                Text(
                  'Live',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
