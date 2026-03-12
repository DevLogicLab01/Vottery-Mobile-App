import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/lottery_automation_service.dart';
import '../../services/ga4_analytics_service.dart';
import '../../theme/app_theme.dart';
import './widgets/slot_machine_3d_widget.dart';
import './widgets/winner_announcement_widget.dart';
import './widgets/prize_distribution_dashboard_widget.dart';
import './widgets/lottery_audit_trail_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Complete Gamified Lottery Drawing System with 3D slot machine visualization,
/// automated winner selection, and prize distribution tracking
class CompleteGamifiedLotteryDrawingSystem extends StatefulWidget {
  const CompleteGamifiedLotteryDrawingSystem({super.key});

  @override
  State<CompleteGamifiedLotteryDrawingSystem> createState() =>
      _CompleteGamifiedLotteryDrawingSystemState();
}

class _CompleteGamifiedLotteryDrawingSystemState
    extends State<CompleteGamifiedLotteryDrawingSystem>
    with SingleTickerProviderStateMixin {
  final LotteryAutomationService _lotteryService =
      LotteryAutomationService.instance;
  final GA4AnalyticsService _analytics = GA4AnalyticsService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeLotteries = [];
  List<Map<String, dynamic>> _winners = [];
  List<Map<String, dynamic>> _prizeDistributions = [];
  List<Map<String, dynamic>> _auditTrail = [];
  String? _selectedElectionId;
  bool _isDrawing = false;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLotteryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLotteryData() async {
    setState(() => _isLoading = true);

    try {
      // Load active lotteries and related data
      final lotteries = await _fetchActiveLotteries();
      setState(() {
        _activeLotteries = lotteries;
        if (lotteries.isNotEmpty && _selectedElectionId == null) {
          _selectedElectionId = lotteries.first['election_id'];
        }
        _isLoading = false;
      });

      if (_selectedElectionId != null) {
        await _loadElectionData(_selectedElectionId!);
      }
    } catch (e) {
      debugPrint('Load lottery data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActiveLotteries() async {
    // Mock data - replace with actual Supabase query
    return [
      {
        'election_id': 'election-1',
        'title': 'Community Choice Awards',
        'total_votes': 1250,
        'prize_pool': 5000.0,
        'end_time': DateTime.now().add(const Duration(hours: 2)),
        'status': 'active',
      },
      {
        'election_id': 'election-2',
        'title': 'Best Innovation 2026',
        'total_votes': 850,
        'prize_pool': 3000.0,
        'end_time': DateTime.now().add(const Duration(days: 1)),
        'status': 'active',
      },
    ];
  }

  Future<void> _loadElectionData(String electionId) async {
    try {
      final results = await Future.wait([
        _lotteryService.getLotteryWinners(electionId),
        _fetchPrizeDistributions(electionId),
        _fetchAuditTrail(electionId),
      ]);

      setState(() {
        _winners = results[0];
        _prizeDistributions = results[1];
        _auditTrail = results[2];
      });
    } catch (e) {
      debugPrint('Load election data error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPrizeDistributions(
    String electionId,
  ) async {
    // Mock data - replace with actual Supabase query
    return [
      {
        'winner_id': 'user-1',
        'position': 1,
        'prize_amount': 2500.0,
        'status': 'pending',
        'claim_deadline': DateTime.now().add(const Duration(days: 30)),
      },
      {
        'winner_id': 'user-2',
        'position': 2,
        'prize_amount': 1500.0,
        'status': 'notified',
        'claim_deadline': DateTime.now().add(const Duration(days: 30)),
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _fetchAuditTrail(String electionId) async {
    // Mock data - replace with actual Supabase query
    return [
      {
        'event_type': 'lottery_created',
        'timestamp': DateTime.now().subtract(const Duration(days: 7)),
        'details': 'Lottery initialized with 5000 prize pool',
      },
      {
        'event_type': 'vote_cast',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'details': 'Vote #1250 recorded',
      },
    ];
  }

  Future<void> _simulateDrawing() async {
    if (_selectedElectionId == null) return;

    setState(() => _isDrawing = true);

    // Simulate drawing process
    await Future.delayed(const Duration(seconds: 8));

    setState(() {
      _isDrawing = false;
      _showCelebration = true;
    });

    // Track lottery draw event
    await _analytics.trackLotteryDrawCompleted(
      electionId: _selectedElectionId!,
      winnersCount: _winners.length,
    );

    // Hide celebration after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });

    // Reload data
    await _loadElectionData(_selectedElectionId!);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CompleteLotteryDrawingSystem',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Lottery Drawing System'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadLotteryData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildElectionSelector(),
                    if (_selectedElectionId != null) ...[
                      Expanded(
                        child: _isDrawing
                            ? SlotMachine3DWidget(
                                electionId: _selectedElectionId!,
                                onDrawComplete: () {
                                  setState(() => _isDrawing = false);
                                },
                              )
                            : Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: AppTheme.primaryLight,
                                    unselectedLabelColor: Colors.grey.withAlpha(
                                      153,
                                    ),
                                    indicatorColor: AppTheme.primaryLight,
                                    tabs: const [
                                      Tab(text: 'Winners'),
                                      Tab(text: 'Prize Distribution'),
                                      Tab(text: 'Audit Trail'),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        WinnerAnnouncementWidget(
                                          winners: _winners,
                                          onRefresh: () => _loadElectionData(
                                            _selectedElectionId!,
                                          ),
                                        ),
                                        PrizeDistributionDashboardWidget(
                                          distributions: _prizeDistributions,
                                          onRefresh: () => _loadElectionData(
                                            _selectedElectionId!,
                                          ),
                                        ),
                                        LotteryAuditTrailWidget(
                                          auditTrail: _auditTrail,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ],
                ),
              ),
        floatingActionButton: _selectedElectionId != null && !_isDrawing
            ? FloatingActionButton.extended(
                onPressed: _simulateDrawing,
                backgroundColor: AppTheme.accentLight,
                icon: const Icon(Icons.casino, color: Colors.white),
                label: Text(
                  'Start Drawing',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildElectionSelector() {
    if (_activeLotteries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Text(
          'No active lotteries',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey.withAlpha(153),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(26),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(51))),
      ),
      child: DropdownButton<String>(
        value: _selectedElectionId,
        isExpanded: true,
        underline: Container(),
        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black),
        items: _activeLotteries
            .map(
              (lottery) => DropdownMenuItem<String>(
                value: lottery['election_id'],
                child: Text(lottery['title']),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() => _selectedElectionId = value);
          if (value != null) {
            _loadElectionData(value);
          }
        },
      ),
    );
  }

  void _loadData() {
    _loadLotteryData();
  }
}
