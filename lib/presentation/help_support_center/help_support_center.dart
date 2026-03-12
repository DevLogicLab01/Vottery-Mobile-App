import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/error_boundary_wrapper.dart';
import './widgets/help_center_tab_widget.dart';
import './widgets/support_inbox_tab_widget.dart';
import './widgets/report_problem_tab_widget.dart';
import './widgets/terms_policies_tab_widget.dart';

/// Help & Support Center providing comprehensive user assistance through
/// integrated help resources, support ticketing, and feedback systems.
/// Features tabbed interface with Help Center, Support Inbox, Report Problem, and Terms sections.
class HelpSupportCenter extends StatefulWidget {
  const HelpSupportCenter({super.key});

  @override
  State<HelpSupportCenter> createState() => _HelpSupportCenterState();
}

class _HelpSupportCenterState extends State<HelpSupportCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'HelpSupportCenter',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: Text(
            'Help & Support',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
              alpha: 0.6,
            ),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
            unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 13.sp,
            ),
            tabs: const [
              Tab(text: 'Help Center'),
              Tab(text: 'Support Inbox'),
              Tab(text: 'Report Problem'),
              Tab(text: 'Terms & Policies'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            HelpCenterTabWidget(),
            SupportInboxTabWidget(),
            ReportProblemTabWidget(),
            TermsPoliciesTabWidget(),
          ],
        ),
      ),
    );
  }
}
