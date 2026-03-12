import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/support_ticket_service.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/tickets_tab_widget.dart';
import './widgets/guides_tab_widget.dart';
import './widgets/faq_bot_tab_widget.dart';
import './widgets/analytics_tab_widget.dart';

/// Creator Support Command Center
/// Comprehensive support hub with ticketing, guides, AI FAQ bot, and analytics
class CreatorSupportHubScreen extends StatefulWidget {
  const CreatorSupportHubScreen({super.key});

  @override
  State<CreatorSupportHubScreen> createState() =>
      _CreatorSupportHubScreenState();
}

class _CreatorSupportHubScreenState extends State<CreatorSupportHubScreen>
    with SingleTickerProviderStateMixin {
  final SupportTicketService _ticketService = SupportTicketService.instance;
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      // Get ticket stats
      final tickets = await _ticketService.getUserTickets();
      final openTickets = tickets.where((t) => t['status'] == 'open').length;
      final inProgressTickets = tickets
          .where((t) => t['status'] == 'in_progress')
          .length;

      // Get guide stats
      final guideProgress = await _client
          .from('guide_progress')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      final completedGuides = guideProgress
          .where((g) => g['completed'] == true)
          .length;

      setState(() {
        _stats = {
          'openTickets': openTickets,
          'inProgressTickets': inProgressTickets,
          'completedGuides': completedGuides,
          'totalGuides': 0, // Will be loaded in guides tab
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load stats error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'CreatorSupportHubScreen',
      onRetry: _loadStats,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          title: Text(
            'Creator Support Hub',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.onPrimary,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withValues(
              alpha: 0.7,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
            isScrollable: true,
            tabs: const [
              Tab(text: 'Tickets'),
              Tab(text: 'Guides'),
              Tab(text: 'FAQ Bot'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : TabBarView(
                controller: _tabController,
                children: [
                  TicketsTabWidget(onRefresh: _loadStats),
                  GuidesTabWidget(onRefresh: _loadStats),
                  FAQBotTabWidget(),
                  AnalyticsTabWidget(),
                ],
              ),
      ),
    );
  }
}
