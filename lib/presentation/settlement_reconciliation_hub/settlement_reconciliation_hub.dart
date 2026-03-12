import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/reconciliation_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/discrepancy_alert_widget.dart';
import './widgets/automated_retry_timeline_widget.dart';
import './widgets/reconciliation_reports_widget.dart';

class SettlementReconciliationHub extends StatefulWidget {
  const SettlementReconciliationHub({super.key});

  @override
  State<SettlementReconciliationHub> createState() =>
      _SettlementReconciliationHubState();
}

class _SettlementReconciliationHubState
    extends State<SettlementReconciliationHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _discrepancies = [];
  Map<String, dynamic> _reconciliationSummary = {};

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

    try {
      final results = await Future.wait<dynamic>([
        ReconciliationService.instance.getPayoutTransactions(),
        ReconciliationService.instance.getReconciliationSummary(),
      ]);

      if (mounted) {
        setState(() {
          _discrepancies = results[0] as List<Map<String, dynamic>>;
          _reconciliationSummary = results[1] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Settlement Reconciliation Hub',
          variant: CustomAppBarVariant.withBack,
        ),
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _discrepancies.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header with key metrics
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? Center(
                          child: SizedBox(
                            height: 3.h,
                            width: 3.h,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'Total Discrepancies',
                                '${_reconciliationSummary['total_discrepancies'] ?? 0}',
                                Icons.warning_amber,
                                Colors.orange,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _buildMetricCard(
                                'Resolved',
                                '${_reconciliationSummary['matched'] ?? 0}',
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _buildMetricCard(
                                'Unresolved',
                                '${_reconciliationSummary['unmatched'] ?? 0}',
                                Icons.error_outline,
                                Colors.red,
                              ),
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
                    unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(
                      153,
                    ),
                    indicatorColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Discrepancy Alerts'),
                      Tab(text: 'Retry Timeline'),
                      Tab(text: 'Reports'),
                    ],
                  ),
                ),

                // Tab views
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            DiscrepancyAlertWidget(
                              discrepancies: _discrepancies,
                              onRefresh: _loadData,
                            ),
                            AutomatedRetryTimelineWidget(onRefresh: _loadData),
                            ReconciliationReportsWidget(
                              summary: _reconciliationSummary,
                              onRefresh: _loadData,
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSkeletonLoader() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 6,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSkeletonHeader(theme);
        }
        return _buildSkeletonCard(theme);
      },
    );
  }

  Widget _buildSkeletonHeader(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) {
              return Column(
                children: [
                  Container(
                    width: 15.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    width: 20.w,
                    height: 2.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50.w,
                      height: 2.5.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      width: 30.w,
                      height: 2.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'All Settlements Reconciled',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'No discrepancies found. All settlements are properly reconciled.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(
                Icons.refresh,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: Text(
                'Refresh Data',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.8.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
