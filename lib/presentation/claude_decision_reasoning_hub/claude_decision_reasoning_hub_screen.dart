import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/appeal_workflow_panel_widget.dart';
import './widgets/dispute_resolution_panel_widget.dart';
import './widgets/fraud_investigation_panel_widget.dart';
import './widgets/policy_interpretation_panel_widget.dart';

class ClaudeDecisionReasoningHubScreen extends StatefulWidget {
  const ClaudeDecisionReasoningHubScreen({super.key});

  @override
  State<ClaudeDecisionReasoningHubScreen> createState() =>
      _ClaudeDecisionReasoningHubScreenState();
}

class _ClaudeDecisionReasoningHubScreenState
    extends State<ClaudeDecisionReasoningHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.psychology, size: 22),
            SizedBox(width: 2.w),
            Text(
              'Claude Decision Reasoning Hub',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.gavel, size: 16), text: 'Disputes'),
            Tab(icon: Icon(Icons.security, size: 16), text: 'Fraud'),
            Tab(icon: Icon(Icons.policy, size: 16), text: 'Policy'),
            Tab(icon: Icon(Icons.rate_review, size: 16), text: 'Appeals'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withAlpha(26),
                  Colors.purple.withAlpha(13),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extended Reasoning Active',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        'Claude analyzes evidence chains with confidence scoring',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.green.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Online',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(const DisputeResolutionPanelWidget()),
                _buildTabContent(const FraudInvestigationPanelWidget()),
                _buildTabContent(const PolicyInterpretationPanelWidget()),
                _buildTabContent(const AppealWorkflowPanelWidget()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Widget child) {
    return SingleChildScrollView(padding: EdgeInsets.all(4.w), child: child);
  }
}