import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/tax_compliance_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/annual_report_widget.dart';
import './widgets/claude_tax_guidance_widget.dart';
import './widgets/compliance_status_header_widget.dart';
import './widgets/document_management_widget.dart';
import './widgets/expiration_tracking_widget.dart';
import './widgets/jurisdiction_compliance_widget.dart';
import './widgets/tax_notification_preferences_widget.dart';

/// Tax Compliance Dashboard
/// Comprehensive tax document management with automated form generation,
/// expiration tracking, and jurisdiction-specific compliance
class TaxComplianceDashboard extends StatefulWidget {
  const TaxComplianceDashboard({super.key});

  @override
  State<TaxComplianceDashboard> createState() => _TaxComplianceDashboardState();
}

class _TaxComplianceDashboardState extends State<TaxComplianceDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaxComplianceService _taxService = TaxComplianceService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _complianceStatus = {};
  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> _expiringDocs = [];
  List<Map<String, dynamic>> _jurisdictions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _taxService.getComplianceStatus(),
        _taxService.getTaxDocuments(),
        _taxService.getExpiringDocuments(daysThreshold: 90),
        _taxService.getJurisdictionRegistrations(),
      ]);

      if (mounted) {
        setState(() {
          _complianceStatus = results[0] as Map<String, dynamic>;
          _documents = results[1] as List<Map<String, dynamic>>;
          _expiringDocs = results[2] as List<Map<String, dynamic>>;
          _jurisdictions = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load dashboard data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: 'Tax Compliance',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              size: 6.w,
              color: AppTheme.primaryLight,
            ),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _documents.isEmpty && _jurisdictions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compliance Status Header
                    ComplianceStatusHeaderWidget(
                      complianceStatus: _complianceStatus,
                    ),
                    SizedBox(height: 3.h),

                    // Tabbed Content
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: AppTheme.primaryLight,
                            unselectedLabelColor: AppTheme.textSecondaryLight,
                            indicatorColor: AppTheme.primaryLight,
                            isScrollable: true,
                            tabs: [
                              Tab(text: 'Documents'),
                              Tab(text: 'Expiring'),
                              Tab(text: 'Jurisdictions'),
                              Tab(text: 'Reports'),
                              Tab(text: 'Notifications'),
                              Tab(text: 'AI Guidance'),
                            ],
                          ),
                          SizedBox(
                            height: 60.h,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                DocumentManagementWidget(
                                  documents: _documents,
                                  onRefresh: _refreshData,
                                ),
                                ExpirationTrackingWidget(
                                  expiringDocuments: _expiringDocs,
                                  onRefresh: _refreshData,
                                ),
                                JurisdictionComplianceWidget(
                                  jurisdictions: _jurisdictions,
                                  onRefresh: _refreshData,
                                ),
                                AnnualReportWidget(documents: _documents),
                                TaxNotificationPreferencesWidget(),
                                ClaudeTaxGuidanceWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSkeletonLoader() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 8,
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
          Container(
            width: 60.w,
            height: 2.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            width: 40.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 25.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                width: 25.w,
                height: 3.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
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
                child: CustomIconWidget(
                  iconName: 'description',
                  color: theme.colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No Tax Documents Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Upload your tax documents to ensure compliance and track expiration dates.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to document upload
              },
              icon: CustomIconWidget(
                iconName: 'upload_file',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: Text(
                'Upload Document',
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
}
