import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/ab_testing_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/experiment_dashboard_widget.dart';
import './widgets/test_builder_widget.dart';
import './widgets/results_analytics_widget.dart';
import './widgets/experiment_history_widget.dart';

/// Advanced A/B Testing Center
/// Multi-variant experiment management with statistical significance tracking
class AdvancedABTestingCenter extends StatefulWidget {
  const AdvancedABTestingCenter({super.key});

  @override
  State<AdvancedABTestingCenter> createState() =>
      _AdvancedABTestingCenterState();
}

class _AdvancedABTestingCenterState extends State<AdvancedABTestingCenter>
    with SingleTickerProviderStateMixin {
  final ABTestingService _abTestingService = ABTestingService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _activeExperiments = [];
  List<Map<String, dynamic>> _experimentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final active = await _abTestingService.getExperiments(status: 'active');
    final history = await _abTestingService.getExperiments(status: 'completed');

    if (mounted) {
      setState(() {
        _activeExperiments = active;
        _experimentHistory = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showCreateExperimentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TestBuilderWidget(onExperimentCreated: _refreshData),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AdvancedABTestingCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'A/B Testing Center',
          actions: [
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: theme.colorScheme.onPrimary,
              ),
              onPressed: _showCreateExperimentDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    // Status overview header
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildStatCard(
                            context,
                            'Active Tests',
                            _activeExperiments.length.toString(),
                            Icons.science,
                          ),
                          SizedBox(width: 3.w),
                          _buildStatCard(
                            context,
                            'Completed',
                            _experimentHistory.length.toString(),
                            Icons.check_circle,
                          ),
                          SizedBox(width: 3.w),
                          _buildStatCard(
                            context,
                            'Avg Confidence',
                            '94.2%',
                            Icons.trending_up,
                          ),
                        ],
                      ),
                    ),

                    // Tab bar
                    Container(
                      color: theme.colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor:
                            theme.colorScheme.onSurfaceVariant,
                        indicatorColor: theme.colorScheme.primary,
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Dashboard'),
                          Tab(text: 'Analytics'),
                          Tab(text: 'History'),
                        ],
                      ),
                    ),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Experiment Dashboard
                          ExperimentDashboardWidget(
                            experiments: _activeExperiments,
                            onRefresh: _refreshData,
                          ),

                          // Results Analytics
                          ResultsAnalyticsWidget(
                            experiments: _activeExperiments,
                          ),

                          // Experiment History
                          ExperimentHistoryWidget(history: _experimentHistory),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateExperimentDialog,
          icon: const Icon(Icons.add),
          label: const Text('New Test'),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimary, size: 24),
            SizedBox(height: 1.h),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
