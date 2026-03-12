import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

class AnalyticsTabWidget extends StatefulWidget {
  const AnalyticsTabWidget({super.key});

  @override
  State<AnalyticsTabWidget> createState() => _AnalyticsTabWidgetState();
}

class _AnalyticsTabWidgetState extends State<AnalyticsTabWidget> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Get creator journey steps
      final journeySteps = await _client
          .from('creator_journey_steps')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      // Get guide progress
      final guideProgress = await _client
          .from('guide_progress')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      // Get ticket stats
      final tickets = await _client
          .from('support_tickets')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      // Calculate onboarding funnel
      final funnelSteps = [
        'account_created',
        'profile_completed',
        'first_post',
        'first_election',
        'first_earning',
        'activated_creator',
      ];

      final funnelData = <String, bool>{};
      for (final step in funnelSteps) {
        funnelData[step] = journeySteps.any((j) => j['step_name'] == step);
      }

      setState(() {
        _analytics = {
          'journeySteps': journeySteps.length,
          'completedGuides': guideProgress
              .where((g) => g['completed'] == true)
              .length,
          'totalGuides': guideProgress.length,
          'totalTickets': tickets.length,
          'resolvedTickets': tickets
              .where((t) => t['status'] == 'resolved')
              .length,
          'funnelData': funnelData,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load analytics error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SkeletonList(itemCount: 6);
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Overview cards
          Text(
            'Your Progress',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Journey Steps',
                  '${_analytics['journeySteps']}/6',
                  Icons.flag,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Guides Completed',
                  '${_analytics['completedGuides']}/${_analytics['totalGuides']}',
                  Icons.school,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tickets',
                  _analytics['totalTickets'].toString(),
                  Icons.support,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Resolved',
                  _analytics['resolvedTickets'].toString(),
                  Icons.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Onboarding funnel
          Text(
            'Onboarding Funnel',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildOnboardingFunnel(),

          SizedBox(height: 4.h),

          // Guide completion chart
          Text(
            'Guide Completion',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          _buildGuideCompletionChart(),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Icon(icon, size: 32.sp, color: color),
            SizedBox(height: 1.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingFunnel() {
    final funnelData = _analytics['funnelData'] as Map<String, bool>? ?? {};
    final steps = [
      {'key': 'account_created', 'label': 'Account Created'},
      {'key': 'profile_completed', 'label': 'Profile Completed'},
      {'key': 'first_post', 'label': 'First Post'},
      {'key': 'first_election', 'label': 'First Election'},
      {'key': 'first_earning', 'label': 'First Earning'},
      {'key': 'activated_creator', 'label': 'Activated Creator'},
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: steps.map((step) {
            final isCompleted = funnelData[step['key']] ?? false;
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: isCompleted ? Colors.green : Colors.grey,
                    size: 24.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      step['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: isCompleted
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isCompleted ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGuideCompletionChart() {
    final completed = _analytics['completedGuides'] as int? ?? 0;
    final total = _analytics['totalGuides'] as int? ?? 1;
    final remaining = total - completed;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: completed.toDouble(),
                  title: 'Completed\n$completed',
                  color: Colors.green,
                  radius: 60,
                  titleStyle: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: remaining.toDouble(),
                  title: 'Remaining\n$remaining',
                  color: Colors.grey[300],
                  radius: 60,
                  titleStyle: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }
}
