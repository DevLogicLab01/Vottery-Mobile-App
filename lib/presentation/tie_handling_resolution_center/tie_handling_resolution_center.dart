import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tie_resolution_service.dart';
import '../../theme/app_theme.dart';
import './widgets/active_tie_card_widget.dart';
import './widgets/runoff_scheduler_widget.dart';
import './widgets/tie_analytics_widget.dart';
import './widgets/tie_prevention_widget.dart';
import './widgets/manual_resolution_dialog_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

/// Tie Handling & Resolution Center
/// Manages tied election outcomes with automated detection and resolution workflows
class TieHandlingResolutionCenter extends StatefulWidget {
  const TieHandlingResolutionCenter({super.key});

  @override
  State<TieHandlingResolutionCenter> createState() =>
      _TieHandlingResolutionCenterState();
}

class _TieHandlingResolutionCenterState
    extends State<TieHandlingResolutionCenter>
    with SingleTickerProviderStateMixin {
  final TieResolutionService _tieService = TieResolutionService.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _activeTies = [];
  List<Map<String, dynamic>> _tieAnalytics = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Statistics
  int _activeTiesCount = 0;
  int _pendingRunoffsCount = 0;
  int _totalResolutionsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTieData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTieData() async {
    setState(() => _isLoading = true);

    try {
      final activeTies = await _tieService.getActiveTies();
      final analytics = await _tieService.getTieAnalytics();

      setState(() {
        _activeTies = activeTies;
        _tieAnalytics = analytics;
        _activeTiesCount = activeTies.length;
        _pendingRunoffsCount = activeTies
            .where((t) => t['resolution_status'] == 'runoff_scheduled')
            .length;
        _totalResolutionsCount = analytics.fold<int>(
          0,
          (sum, item) =>
              sum +
              ((item['runoff_resolutions'] ?? 0) as int) +
              ((item['manual_resolutions'] ?? 0) as int) +
              ((item['lottery_resolutions'] ?? 0) as int),
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load tie data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadTieData();
    setState(() => _isRefreshing = false);
  }

  void _showManualResolutionDialog(Map<String, dynamic> tieResult) {
    showDialog(
      context: context,
      builder: (context) => ManualResolutionDialogWidget(
        tieResult: tieResult,
        onResolved: () async {
          await _refreshData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Tie resolved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  void _showRunoffScheduler(Map<String, dynamic> tieResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RunoffSchedulerWidget(
        tieResult: tieResult,
        onScheduled: () async {
          await _refreshData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🗳️ Runoff election scheduled'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'TieHandlingResolutionCenter',
      onRetry: _loadTieData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryLight,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Tie Handling & Resolution',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(14.h),
            child: Column(
              children: [
                // Statistics Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '🤝 Active Ties',
                        _activeTiesCount.toString(),
                        Colors.orange,
                      ),
                      _buildStatCard(
                        '🗳️ Pending Runoffs',
                        _pendingRunoffsCount.toString(),
                        Colors.blue,
                      ),
                      _buildStatCard(
                        '✅ Resolutions',
                        _totalResolutionsCount.toString(),
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Active Ties'),
                    Tab(text: 'Analytics'),
                    Tab(text: 'Prevention'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _activeTies.isEmpty
            ? NoDataEmptyState(
                title: 'No Tie Situations',
                description:
                    'Elections with tie results will appear here for resolution.',
                onRefresh: _loadTieData,
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: AppTheme.primaryLight,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTiesTab(),
                    _buildAnalyticsTab(),
                    _buildPreventionTab(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTiesTab() {
    if (_activeTies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60.0,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'No Active Ties',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All elections have clear winners',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _activeTies.length,
      itemBuilder: (context, index) {
        final tie = _activeTies[index];
        return ActiveTieCardWidget(
          tieResult: tie,
          onScheduleRunoff: () => _showRunoffScheduler(tie),
          onManualResolve: () => _showManualResolutionDialog(tie),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: TieAnalyticsWidget(analyticsData: _tieAnalytics),
    );
  }

  Widget _buildPreventionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: const TiePreventionWidget(),
    );
  }
}
