import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/error_boundary_wrapper.dart';

class GitHubActionsCiCdPipelineDashboard extends StatefulWidget {
  const GitHubActionsCiCdPipelineDashboard({super.key});

  @override
  State<GitHubActionsCiCdPipelineDashboard> createState() =>
      _GitHubActionsCiCdPipelineDashboardState();
}

class _GitHubActionsCiCdPipelineDashboardState
    extends State<GitHubActionsCiCdPipelineDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _workflows = [
    {
      'name': 'Flutter CI Enhanced',
      'status': 'success',
      'environment': 'CI',
      'lastRun': '2 hours ago',
      'duration': '8m 32s',
      'branch': 'main',
    },
    {
      'name': 'Flutter CD Enhanced - Staging',
      'status': 'running',
      'environment': 'staging',
      'lastRun': '5 minutes ago',
      'duration': '12m 15s',
      'branch': 'develop',
    },
    {
      'name': 'Flutter CD Enhanced - Production',
      'status': 'success',
      'environment': 'production',
      'lastRun': '1 day ago',
      'duration': '15m 48s',
      'branch': 'main',
    },
    {
      'name': 'Security Scan',
      'status': 'success',
      'environment': 'CI',
      'lastRun': '6 hours ago',
      'duration': '4m 22s',
      'branch': 'main',
    },
  ];

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
      screenName: 'GitHubActionsCiCdPipelineDashboard',
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF24292E),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CI/CD Pipeline Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'GitHub Actions Deployment Automation',
                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2EA44F),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'CI Pipeline'),
              Tab(text: 'CD Staging'),
              Tab(text: 'CD Production'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildCIPipelineTab(),
                  _buildCDStagingTab(),
                  _buildCDProductionTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPipelineStatusOverview(),
          SizedBox(height: 2.h),
          _buildDeploymentHealthSection(),
          SizedBox(height: 2.h),
          _buildRecentWorkflowsSection(),
        ],
      ),
    );
  }

  Widget _buildPipelineStatusOverview() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pipeline Status Overview',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetricCard(
                  'Active Workflows',
                  '4',
                  Icons.play_circle_outline,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatusMetricCard(
                  'Success Rate',
                  '98.5%',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusMetricCard(
                  'Avg Duration',
                  '10m 12s',
                  Icons.timer_outlined,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatusMetricCard(
                  'Failed Today',
                  '0',
                  Icons.error_outline,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentHealthSection() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deployment Health',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildEnvironmentHealthCard(
            'Staging',
            'Healthy',
            Colors.green,
            'Last deployed 5 minutes ago',
          ),
          SizedBox(height: 1.h),
          _buildEnvironmentHealthCard(
            'Production',
            'Healthy',
            Colors.green,
            'Last deployed 1 day ago (10% rollout)',
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentHealthCard(
    String environment,
    String status,
    Color statusColor,
    String lastDeployed,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 3.w,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  environment,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  lastDeployed,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkflowsSection() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Workflows',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ..._workflows.map((workflow) => _buildWorkflowCard(workflow)),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(Map<String, dynamic> workflow) {
    final statusColor = workflow['status'] == 'success'
        ? Colors.green
        : workflow['status'] == 'running'
        ? Colors.blue
        : Colors.red;

    final statusIcon = workflow['status'] == 'success'
        ? Icons.check_circle
        : workflow['status'] == 'running'
        ? Icons.sync
        : Icons.error;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  workflow['name'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  workflow['status'],
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                workflow['lastRun'],
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.timer, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                workflow['duration'],
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.code_outlined, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                workflow['branch'],
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCIPipelineTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCIPipelineCard(
            'Test Suite',
            'Running unit and integration tests',
            'success',
            '245 tests passed',
          ),
          SizedBox(height: 1.h),
          _buildCIPipelineCard(
            'Code Analysis',
            'Flutter analyzer and formatting checks',
            'success',
            'No issues found',
          ),
          SizedBox(height: 1.h),
          _buildCIPipelineCard(
            'Security Scan',
            'Dependency audit and secret scanning',
            'success',
            'No vulnerabilities detected',
          ),
          SizedBox(height: 1.h),
          _buildCIPipelineCard(
            'Build Verification',
            'Android and Web build checks',
            'success',
            'All builds successful',
          ),
        ],
      ),
    );
  }

  Widget _buildCIPipelineCard(
    String title,
    String description,
    String status,
    String result,
  ) {
    final statusColor = status == 'success' ? Colors.green : Colors.red;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: statusColor, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              result,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCDStagingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeploymentCard(
            'Firebase Distribution',
            'Deploying to testers group',
            'running',
            '75% complete',
          ),
          SizedBox(height: 1.h),
          _buildDeploymentCard(
            'Build APK',
            'Building staging release',
            'success',
            'Completed in 8m 32s',
          ),
        ],
      ),
    );
  }

  Widget _buildCDProductionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhaseRolloutCard(),
          SizedBox(height: 2.h),
          _buildDeploymentCard(
            'Play Store',
            'Staged rollout to 10% of users',
            'success',
            'Deployed 1 day ago',
          ),
          SizedBox(height: 1.h),
          _buildRollbackSection(),
        ],
      ),
    );
  }

  Widget _buildPhaseRolloutCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phased Rollout Progress',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '10% of users',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Current rollout',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: const Text('Increase to 25%'),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: 0.1,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildRollbackSection() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red, size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Emergency Controls',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showRollbackConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              icon: const Icon(Icons.restore, color: Colors.white),
              label: const Text(
                'Rollback to Previous Version',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeploymentCard(
    String title,
    String description,
    String status,
    String result,
  ) {
    final statusColor = status == 'success'
        ? Colors.green
        : status == 'running'
        ? Colors.blue
        : Colors.red;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'running' ? Icons.sync : Icons.check_circle,
                color: statusColor,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            result,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showRollbackConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rollback'),
        content: const Text(
          'Are you sure you want to rollback to the previous version? This action will affect all users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rollback initiated'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Rollback'),
          ),
        ],
      ),
    );
  }
}
