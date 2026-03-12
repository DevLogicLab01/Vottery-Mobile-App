import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/investigation_card_widget.dart';

class EnhancedFraudInvestigationWorkflowsHub extends StatefulWidget {
  const EnhancedFraudInvestigationWorkflowsHub({super.key});

  @override
  State<EnhancedFraudInvestigationWorkflowsHub> createState() =>
      _EnhancedFraudInvestigationWorkflowsHubState();
}

class _EnhancedFraudInvestigationWorkflowsHubState
    extends State<EnhancedFraudInvestigationWorkflowsHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _newInvestigations = [];
  List<Map<String, dynamic>> _inProgressInvestigations = [];
  List<Map<String, dynamic>> _needsReviewInvestigations = [];
  List<Map<String, dynamic>> _resolvedInvestigations = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInvestigations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestigations() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final results = await Future.wait<List<Map<String, dynamic>>>([
        supabase
            .from('fraud_investigations')
            .select()
            .eq('status', 'pending_review')
            .order('created_at', ascending: false),
        supabase
            .from('fraud_investigations')
            .select()
            .eq('status', 'investigating')
            .order('created_at', ascending: false),
        supabase
            .from('fraud_investigations')
            .select()
            .inFilter('status', ['action_taken', 'escalated'])
            .order('created_at', ascending: false),
        supabase
            .from('fraud_investigations')
            .select()
            .eq('status', 'resolved')
            .order('resolved_at', ascending: false)
            .limit(20),
      ]);

      // Calculate stats
      final allInvestigations = await supabase
          .from('fraud_investigations')
          .select();
      final activeCases = allInvestigations
          .where(
            (i) => i['status'] != 'resolved' && i['status'] != 'false_positive',
          )
          .length;
      final pendingReviews = allInvestigations
          .where((i) => i['status'] == 'pending_review')
          .length;
      final resolvedToday = allInvestigations.where((i) {
        if (i['resolved_at'] == null) return false;
        final resolvedAt = DateTime.parse(i['resolved_at']);
        return resolvedAt.isAfter(DateTime.now().subtract(Duration(days: 1)));
      }).length;

      setState(() {
        _newInvestigations = List<Map<String, dynamic>>.from(results[0]);
        _inProgressInvestigations = List<Map<String, dynamic>>.from(results[1]);
        _needsReviewInvestigations = List<Map<String, dynamic>>.from(
          results[2],
        );
        _resolvedInvestigations = List<Map<String, dynamic>>.from(results[3]);
        _stats = {
          'active_cases': activeCases,
          'pending_reviews': pendingReviews,
          'resolved_today': resolvedToday,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading investigations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedFraudInvestigationWorkflowsHub',
      onRetry: _loadInvestigations,
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
          title: 'Fraud Investigation Hub',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadInvestigations,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  // Stats overview
                  Container(
                    padding: EdgeInsets.all(4.w),
                    color: AppTheme.surfaceLight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Active Cases',
                          _stats['active_cases'].toString(),
                          AppTheme.errorLight,
                        ),
                        _buildStatCard(
                          'Pending Review',
                          _stats['pending_reviews'].toString(),
                          AppTheme.warningLight,
                        ),
                        _buildStatCard(
                          'Resolved Today',
                          _stats['resolved_today'].toString(),
                          AppTheme.accentLight,
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  Container(
                    color: AppTheme.surfaceLight,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryLight,
                      unselectedLabelColor: AppTheme.textSecondaryLight,
                      indicatorColor: AppTheme.primaryLight,
                      labelStyle: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: 'New (${_newInvestigations.length})'),
                        Tab(
                          text:
                              'In Progress (${_inProgressInvestigations.length})',
                        ),
                        Tab(
                          text:
                              'Needs Review (${_needsReviewInvestigations.length})',
                        ),
                        Tab(text: 'Resolved'),
                      ],
                    ),
                  ),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInvestigationList(_newInvestigations),
                        _buildInvestigationList(_inProgressInvestigations),
                        _buildInvestigationList(_needsReviewInvestigations),
                        _buildInvestigationList(_resolvedInvestigations),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildInvestigationList(List<Map<String, dynamic>> investigations) {
    if (investigations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No investigations in this category',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: investigations.length,
      itemBuilder: (context, index) {
        return InvestigationCardWidget(
          investigation: investigations[index],
          onTap: () => _openInvestigationDetail(investigations[index]),
          onAssign: () => _showAssignDialog(investigations[index]),
        );
      },
    );
  }

  void _openInvestigationDetail(Map<String, dynamic> investigation) {
    Navigator.pushNamed(
      context,
      '/investigation-detail',
      arguments: investigation,
    );
  }

  void _showAssignDialog(Map<String, dynamic> investigation) {
    // Show assign investigator dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Investigator'),
        content: Text('Assign investigation to team member'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadInvestigations();
            },
            child: Text('Assign'),
          ),
        ],
      ),
    );
  }
}
