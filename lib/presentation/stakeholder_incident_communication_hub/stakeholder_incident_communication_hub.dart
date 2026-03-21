import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

class StakeholderIncidentCommunicationHub extends StatefulWidget {
  const StakeholderIncidentCommunicationHub({super.key});

  @override
  State<StakeholderIncidentCommunicationHub> createState() =>
      _StakeholderIncidentCommunicationHubState();
}

class _StakeholderIncidentCommunicationHubState
    extends State<StakeholderIncidentCommunicationHub>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'StakeholderIncidentCommunicationHub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Stakeholder Communication Hub',
          variant: CustomAppBarVariant.withBack,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryLight,
                unselectedLabelColor: Colors.grey.shade700,
                indicatorColor: AppTheme.primaryLight,
                tabs: const [
                  Tab(text: 'Dashboard'),
                  Tab(text: 'Channels'),
                  Tab(text: 'Stakeholders'),
                  Tab(text: 'Tracking'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildChannelsTab(),
                  _buildStakeholdersTab(),
                  _buildTrackingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _metricCard('Total Communications', '0', Icons.send),
        SizedBox(height: 1.5.h),
        _metricCard('Delivery Rate', '0%', Icons.check_circle_outline),
        SizedBox(height: 1.5.h),
        _metricCard('Avg Response Time', '0s', Icons.schedule),
      ],
    );
  }

  Widget _buildChannelsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _sectionCard(
          title: 'Multi-channel Notifications',
          subtitle: 'Email, SMS, and in-app communication orchestration.',
          icon: Icons.campaign_outlined,
        ),
        SizedBox(height: 1.5.h),
        _sectionCard(
          title: 'Critical SMS Alerts',
          subtitle: 'Priority broadcast for incident escalation events.',
          icon: Icons.sms_outlined,
        ),
      ],
    );
  }

  Widget _buildStakeholdersTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        _sectionCard(
          title: 'Stakeholder Groups',
          subtitle: 'Manage communication targets by role and incident type.',
          icon: Icons.groups_outlined,
        ),
        SizedBox(height: 1.5.h),
        _sectionCard(
          title: 'Message Composer',
          subtitle: 'Compose and route incident updates by audience.',
          icon: Icons.edit_note_outlined,
        ),
      ],
    );
  }

  Widget _buildTrackingTab() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Text(
          'Delivery analytics and response tracking will appear here as communication records are generated.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryLight),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryLight),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
