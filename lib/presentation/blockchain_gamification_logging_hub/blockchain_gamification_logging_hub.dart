import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import './widgets/admin_blockchain_audit_widget.dart';
import './widgets/badge_award_verification_widget.dart';
import './widgets/blockchain_explorer_widget.dart';
import './widgets/blockchain_status_header_widget.dart';
import './widgets/challenge_completion_audit_widget.dart';
import './widgets/prediction_pool_resolution_widget.dart';
import './widgets/smart_contract_integration_widget.dart';
import './widgets/vp_transaction_logging_widget.dart';

class BlockchainGamificationLoggingHub extends StatefulWidget {
  const BlockchainGamificationLoggingHub({super.key});

  @override
  State<BlockchainGamificationLoggingHub> createState() =>
      _BlockchainGamificationLoggingHubState();
}

class _BlockchainGamificationLoggingHubState
    extends State<BlockchainGamificationLoggingHub>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;

  late TabController _tabController;
  Map<String, dynamic>? _blockchainStatus;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBlockchainData();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      setState(() {
        _isAdmin = response?['role'] == 'admin';
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadBlockchainData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load recent blockchain transactions
      final transactionsResponse = await _supabaseService.client
          .from('blockchain_gamification_logs')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      // Simulate blockchain status (in production, this would query actual blockchain)
      final blockchainStatus = {
        'network_health': 'Healthy',
        'gas_fee_gwei': 25,
        'transaction_queue': 3,
        'last_block': 18234567,
        'sync_status': 'Synced',
      };

      setState(() {
        _recentTransactions = List<Map<String, dynamic>>.from(
          transactionsResponse,
        );
        _blockchainStatus = blockchainStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading blockchain data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blockchain Gamification Logging',
          style: TextStyle(fontSize: 16.sp),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadBlockchainData),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'VP Transactions'),
            Tab(text: 'Badge Awards'),
            Tab(text: 'Challenges'),
            Tab(text: 'Predictions'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Blockchain Status Header
                BlockchainStatusHeaderWidget(
                  networkHealth:
                      _blockchainStatus?['network_health'] ?? 'Unknown',
                  gasFeeGwei: _blockchainStatus?['gas_fee_gwei'] ?? 0,
                  transactionQueue:
                      _blockchainStatus?['transaction_queue'] ?? 0,
                  lastBlock: _blockchainStatus?['last_block'] ?? 0,
                  syncStatus: _blockchainStatus?['sync_status'] ?? 'Unknown',
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // VP Transaction Logging
                      VPTransactionLoggingWidget(
                        transactions: _recentTransactions
                            .where(
                              (t) => t['transaction_type'] == 'vp_transaction',
                            )
                            .toList(),
                        onRefresh: _loadBlockchainData,
                      ),

                      // Badge Award Verification
                      BadgeAwardVerificationWidget(
                        badgeAwards: _recentTransactions
                            .where(
                              (t) => t['transaction_type'] == 'badge_award',
                            )
                            .toList(),
                        onRefresh: _loadBlockchainData,
                      ),

                      // Challenge Completion Audit
                      ChallengeCompletionAuditWidget(
                        challenges: _recentTransactions
                            .where(
                              (t) =>
                                  t['transaction_type'] ==
                                  'challenge_completion',
                            )
                            .toList(),
                        onRefresh: _loadBlockchainData,
                      ),

                      // Prediction Pool Resolution
                      PredictionPoolResolutionWidget(
                        predictions: _recentTransactions
                            .where(
                              (t) =>
                                  t['transaction_type'] ==
                                  'prediction_resolution',
                            )
                            .toList(),
                        onRefresh: _loadBlockchainData,
                      ),
                    ],
                  ),
                ),

                // Blockchain Explorer Section
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain Explorer',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      BlockchainExplorerWidget(
                        recentTransactions: _recentTransactions,
                      ),

                      if (_isAdmin) ...[
                        SizedBox(height: 2.h),
                        Text(
                          'Admin Blockchain Audit Tools',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        AdminBlockchainAuditWidget(),
                      ],

                      SizedBox(height: 2.h),
                      SmartContractIntegrationWidget(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
