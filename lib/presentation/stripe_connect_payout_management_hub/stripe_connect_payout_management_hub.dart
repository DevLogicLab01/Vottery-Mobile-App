import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/payout_management_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/bulk_payout_processor_widget.dart';
import './widgets/failed_payout_retry_widget.dart';
import './widgets/payout_analytics_dashboard_widget.dart';
import './widgets/payout_history_table_widget.dart';
import './widgets/payout_scheduling_widget.dart';

class StripeConnectPayoutManagementHub extends StatefulWidget {
  const StripeConnectPayoutManagementHub({super.key});

  @override
  State<StripeConnectPayoutManagementHub> createState() =>
      _StripeConnectPayoutManagementHubState();
}

class _StripeConnectPayoutManagementHubState
    extends State<StripeConnectPayoutManagementHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  void _loadData() {
    setState(() {
      // Trigger rebuild to reload all tab content
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'StripeConnectPayoutManagementHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Payout Management Hub',
        ),
        body: Column(
          children: [
            Container(
              color: AppTheme.primaryLight,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Schedule'),
                  Tab(text: 'Failed Payouts'),
                  Tab(text: 'History'),
                  Tab(text: 'Analytics'),
                  Tab(text: 'Bulk Process'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  PayoutSchedulingWidget(),
                  FailedPayoutRetryWidget(),
                  PayoutHistoryTableWidget(),
                  PayoutAnalyticsDashboardWidget(),
                  BulkPayoutProcessorWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
