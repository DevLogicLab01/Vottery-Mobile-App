import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/blue_green_deployment_panel_widget.dart';
import './widgets/feature_flag_control_panel_widget.dart';
import './widgets/release_management_panel_widget.dart';
import './widgets/rollback_procedures_panel_widget.dart';
import './widgets/staged_rollout_panel_widget.dart';

class ProductionDeploymentHub extends StatefulWidget {
  const ProductionDeploymentHub({super.key});

  @override
  State<ProductionDeploymentHub> createState() =>
      _ProductionDeploymentHubState();
}

class _ProductionDeploymentHubState extends State<ProductionDeploymentHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: CustomAppBar(
        title: 'Production Deployment Hub',
        variant: CustomAppBarVariant.withBack,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Slack notifications active for #vottery-deployments',
                  ),
                  backgroundColor: Color(0xFF6366F1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: const Color(0xFF6366F1),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Releases'),
                Tab(text: 'Blue-Green'),
                Tab(text: 'Feature Flags'),
                Tab(text: 'Rollback'),
                Tab(text: 'Staged Rollout'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ReleaseManagementPanelWidget(),
                BlueGreenDeploymentPanelWidget(),
                FeatureFlagControlPanelWidget(),
                RollbackProceduresPanelWidget(),
                StagedRolloutPanelWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}