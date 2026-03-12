import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/dispute_resolution_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Marketplace Dispute Resolution Hub
/// End-to-end dispute management with Claude AI arbitration and escrow workflows
class MarketplaceDisputeResolutionHub extends StatefulWidget {
  const MarketplaceDisputeResolutionHub({super.key});

  @override
  State<MarketplaceDisputeResolutionHub> createState() =>
      _MarketplaceDisputeResolutionHubState();
}

class _MarketplaceDisputeResolutionHubState
    extends State<MarketplaceDisputeResolutionHub>
    with SingleTickerProviderStateMixin {
  final DisputeResolutionService _disputeService =
      DisputeResolutionService.instance;
  final AuthService _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isAdmin = false;

  List<Map<String, dynamic>> _myDisputes = [];
  List<Map<String, dynamic>> _allDisputes = [];
  List<Map<String, dynamic>> _resolvedDisputes = [];
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminStatus();
    _loadDisputeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isAdmin = false);
        return;
      }

      final userProfile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _isAdmin = [
          'admin',
          'super_admin',
        ].contains(userProfile?['role'] as String?);
      });
    } catch (e) {
      setState(() => _isAdmin = false);
    }
  }

  Future<void> _loadDisputeData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _disputeService.getDisputes(adminView: false),
        _isAdmin
            ? _disputeService.getDisputes(adminView: true)
            : Future.value([]),
        _disputeService.getDisputeAnalytics(),
      ]);

      if (mounted) {
        setState(() {
          _myDisputes = results[0] as List<Map<String, dynamic>>;
          _allDisputes = results[1] as List<Map<String, dynamic>>;
          _analytics = results[2] as Map<String, dynamic>;

          _resolvedDisputes = _myDisputes
              .where((d) => d['status'] == 'resolved')
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load dispute data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MarketplaceDisputeResolutionHub',
      onRetry: _loadDisputeData,
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
          title: 'Dispute Resolution',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadDisputeData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildAnalyticsHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMyDisputesTab(),
                        if (_isAdmin)
                          _buildAllDisputesTab()
                        else
                          _buildMyDisputesTab(),
                        _buildResolvedTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    final openDisputes = _analytics['open_disputes'] ?? 0;
    final avgResolution = _analytics['avg_resolution_hours'] ?? 0.0;
    final buyerWinRate = _analytics['buyer_win_rate'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Open Disputes',
              openDisputes.toString(),
              Icons.gavel,
              Colors.orange,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Avg Resolution',
              '${avgResolution.toStringAsFixed(1)}h',
              Icons.timer,
              Colors.blue,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              'Buyer Win Rate',
              '${buyerWinRate.toStringAsFixed(0)}%',
              Icons.trending_up,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: [
          const Tab(text: 'My Disputes'),
          Tab(text: _isAdmin ? 'All Disputes' : 'My Disputes'),
          const Tab(text: 'Resolved'),
        ],
      ),
    );
  }

  Widget _buildMyDisputesTab() {
    if (_myDisputes.isEmpty) {
      return _buildEmptyState('No active disputes', Icons.check_circle_outline);
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _myDisputes.length,
      itemBuilder: (context, index) {
        return _buildDisputeCard(_myDisputes[index]);
      },
    );
  }

  Widget _buildAllDisputesTab() {
    if (_allDisputes.isEmpty) {
      return _buildEmptyState(
        'No disputes to review',
        Icons.admin_panel_settings,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _allDisputes.length,
      itemBuilder: (context, index) {
        return _buildDisputeCard(_allDisputes[index], showAdminActions: true);
      },
    );
  }

  Widget _buildResolvedTab() {
    if (_resolvedDisputes.isEmpty) {
      return _buildEmptyState('No resolved disputes', Icons.history);
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _resolvedDisputes.length,
      itemBuilder: (context, index) {
        return _buildDisputeCard(_resolvedDisputes[index], isResolved: true);
      },
    );
  }

  Widget _buildDisputeCard(
    Map<String, dynamic> dispute, {
    bool showAdminActions = false,
    bool isResolved = false,
  }) {
    final order = dispute['marketplace_orders'];
    final service = order['marketplace_services'];
    final buyer = order['buyer'];
    final seller = order['seller'];

    final serviceTitle = service['title'] ?? 'Unknown Service';
    final buyerName = buyer['full_name'] ?? 'Unknown';
    final sellerName = seller['full_name'] ?? 'Unknown';
    final amount = order['total_amount'] ?? 0.0;
    final status = dispute['status'] ?? 'open';
    final raisedAt = dispute['raised_at'] != null
        ? DateTime.parse(dispute['raised_at'])
        : DateTime.now();

    final isUrgent =
        status == 'open' && DateTime.now().difference(raisedAt).inHours > 48;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isUrgent
              ? Colors.red.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isUrgent) Icon(Icons.warning, color: Colors.red, size: 5.w),
              if (isUrgent) SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  serviceTitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              CircleAvatar(
                radius: 4.w,
                backgroundImage: buyer['avatar_url'] != null
                    ? NetworkImage(buyer['avatar_url'])
                    : null,
                child: buyer['avatar_url'] == null
                    ? Icon(Icons.person, size: 4.w)
                    : null,
              ),
              SizedBox(width: 2.w),
              Text(buyerName, style: TextStyle(fontSize: 11.sp)),
              SizedBox(width: 2.w),
              Icon(Icons.arrow_forward, size: 4.w),
              SizedBox(width: 2.w),
              CircleAvatar(
                radius: 4.w,
                backgroundImage: seller['avatar_url'] != null
                    ? NetworkImage(seller['avatar_url'])
                    : null,
                child: seller['avatar_url'] == null
                    ? Icon(Icons.person, size: 4.w)
                    : null,
              ),
              SizedBox(width: 2.w),
              Text(sellerName, style: TextStyle(fontSize: 11.sp)),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeago.format(raisedAt),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          if (!isResolved) ...[
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewDisputeDetails(dispute),
                    icon: Icon(Icons.visibility, size: 4.w),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (showAdminActions) ...[
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _analyzeWithAI(dispute),
                      icon: Icon(Icons.psychology, size: 4.w),
                      label: const Text('AI Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.orange;
        label = 'Open';
        break;
      case 'under_review':
        color = Colors.blue;
        label = 'Under Review';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20.w, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _viewDisputeDetails(Map<String, dynamic> dispute) {
    // Navigate to dispute detail screen
    debugPrint('View dispute: ${dispute['dispute_id']}');
  }

  Future<void> _analyzeWithAI(Map<String, dynamic> dispute) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _disputeService.analyzeDispute(dispute['dispute_id']);

    if (mounted) {
      Navigator.pop(context);

      if (result != null) {
        _showAIAnalysisDialog(result);
        await _loadDisputeData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI analysis failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAIAnalysisDialog(Map<String, dynamic> analysis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Analysis Complete'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Recommended: ${analysis['recommended_resolution']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                'Confidence: ${(analysis['confidence_score'] * 100).toStringAsFixed(0)}%',
              ),
              SizedBox(height: 1.h),
              Text('Reasoning: ${analysis['reasoning']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
