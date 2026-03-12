import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/creator_revenue_service.dart';
import '../../services/creator_earnings_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/earnings_transparency_header_widget.dart';
import './widgets/current_split_display_widget.dart';
import './widgets/payout_preview_widget.dart';
import './widgets/split_change_history_widget.dart';
import './widgets/negotiation_interface_widget.dart';
import './widgets/grandfathering_controls_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Creator Revenue Transparency Hub providing comprehensive visibility into
/// country-specific revenue splits and earnings calculations
class CreatorRevenueTransparencyHub extends StatefulWidget {
  const CreatorRevenueTransparencyHub({super.key});

  @override
  State<CreatorRevenueTransparencyHub> createState() =>
      _CreatorRevenueTransparencyHubState();
}

class _CreatorRevenueTransparencyHubState
    extends State<CreatorRevenueTransparencyHub> {
  final CreatorRevenueService _revenueService = CreatorRevenueService.instance;
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;

  bool _isLoading = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _currentSplit = {};
  Map<String, dynamic> _earningsSummary = {};
  Map<String, dynamic> _payoutPreview = {};
  List<Map<String, dynamic>> _splitHistory = [];
  List<Map<String, dynamic>> _upcomingChanges = [];
  List<Map<String, dynamic>> _negotiations = [];
  Map<String, dynamic>? _splitPreferences;

  @override
  void initState() {
    super.initState();
    _loadTransparencyData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _loadTransparencyData(silent: true);
      }
    });
  }

  Future<void> _loadTransparencyData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _revenueService.getCreatorRevenueSplit(),
        _earningsService.getEarningsSummary(),
        _earningsService.getSettlementPreview(),
        _revenueService.getRevenueSplitHistory(),
        _revenueService.getUpcomingSplitChanges(),
        _revenueService.getSplitNegotiations(),
        _revenueService.getSplitPreferences(),
      ]);

      if (mounted) {
        setState(() {
          _currentSplit = results[0] as Map<String, dynamic>;
          _earningsSummary = results[1] as Map<String, dynamic>;
          _payoutPreview = results[2] as Map<String, dynamic>;
          _splitHistory = results[3] as List<Map<String, dynamic>>;
          _upcomingChanges = results[4] as List<Map<String, dynamic>>;
          _negotiations = results[5] as List<Map<String, dynamic>>;
          _splitPreferences = results[6] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load transparency data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadTransparencyData();
  }

  void _showNegotiationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NegotiationInterfaceWidget(
        currentSplit: _currentSplit,
        monthlyRevenue: _earningsSummary['total_usd_earned'] ?? 0.0,
        onSubmit: (data) async {
          final success = await _revenueService.submitSplitNegotiation(
            requestedCreatorPercentage: data['requested_percentage'],
            justification: data['justification'],
            monthlyRevenueUsd: data['monthly_revenue'],
            performanceMetrics: data['performance_metrics'],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Negotiation submitted successfully'
                      : 'Failed to submit negotiation',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );

            if (success) {
              Navigator.pop(context);
              _refreshData();
            }
          }
        },
      ),
    );
  }

  void _showGrandfatheringDialog() {
    if (_upcomingChanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No upcoming split changes to grandfather'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GrandfatheringControlsWidget(
        currentSplit: _currentSplit,
        upcomingChanges: _upcomingChanges,
        preferences: _splitPreferences,
        onOptIn: (grandfatheredPercentage) async {
          final success = await _revenueService.optIntoGrandfathering(
            grandfatheredSplitPercentage: grandfatheredPercentage,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Opted into 90-day grandfathering'
                      : 'Failed to opt into grandfathering',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );

            if (success) {
              Navigator.pop(context);
              _refreshData();
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorRevenueTransparencyHub',
      onRetry: () => _loadTransparencyData(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: CustomAppBar(
          title: 'Revenue Transparency',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Earnings Transparency Header
                      EarningsTransparencyHeaderWidget(
                        currentSplit: _currentSplit,
                        nextPayoutAmount:
                            _payoutPreview['available_balance_usd'] ?? 0.0,
                        upcomingChangesCount: _upcomingChanges.length,
                      ),
                      SizedBox(height: 2.h),

                      // Current Split Display
                      CurrentSplitDisplayWidget(
                        split: _currentSplit,
                        isGrandfathered:
                            _currentSplit['is_grandfathered'] ?? false,
                        grandfatheredUntil:
                            _currentSplit['grandfathered_until'],
                      ),
                      SizedBox(height: 2.h),

                      // Payout Preview
                      PayoutPreviewWidget(
                        payoutPreview: _payoutPreview,
                        currentSplit: _currentSplit,
                      ),
                      SizedBox(height: 2.h),

                      // Upcoming Split Changes (if any)
                      if (_upcomingChanges.isNotEmpty) ...[
                        _buildUpcomingChangesCard(),
                        SizedBox(height: 2.h),
                      ],

                      // Split Change History
                      SplitChangeHistoryWidget(history: _splitHistory),
                      SizedBox(height: 2.h),

                      // Negotiation Status (if eligible)
                      if ((_earningsSummary['total_usd_earned'] ?? 0.0) >=
                          10000) ...[
                        _buildNegotiationCard(),
                        SizedBox(height: 2.h),
                      ],

                      // Educational Section
                      _buildEducationalCard(),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildUpcomingChangesCard() {
    final nextChange = _upcomingChanges.first;
    final effectiveDate = DateTime.parse(nextChange['effective_date']);
    final daysUntil = effectiveDate.difference(DateTime.now()).inDays;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Upcoming Split Change',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Your revenue split will change in $daysUntil days:',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${nextChange['previous_creator_percentage']}%',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey.shade600),
              Text(
                'New: ${nextChange['new_creator_percentage']}%',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ElevatedButton(
            onPressed: _showGrandfatheringDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keep Current Rate for 90 Days',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationCard() {
    final hasActivenegotiation = _negotiations.any(
      (n) => n['status'] == 'pending',
    );

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: Colors.blue.shade700, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Custom Split Negotiation',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            hasActivenegotiation
                ? 'Your negotiation request is under review'
                : 'As a high-performing creator (>\$10k/month), you can request a custom revenue split',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 1.5.h),
          if (!hasActivenegotiation)
            ElevatedButton(
              onPressed: _showNegotiationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Request Custom Split',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending, color: Colors.blue.shade700, size: 16.sp),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Pending Admin Review',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEducationalCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'How Revenue Splits Work',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '• Revenue splits vary by country based on purchasing power and market conditions\n'
            '• You receive 30-day advance notice of any split changes\n'
            '• Grandfathering allows you to keep old rates for 90 days after changes\n'
            '• High-performing creators (>\$10k/month) can negotiate custom splits\n'
            '• All payouts are calculated using your country-specific split',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
