import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/blockchain_verification_service.dart';
import '../../services/voting_service.dart';
import '../../theme/app_theme.dart';
import './widgets/blockchain_audit_widget.dart';
import './widgets/encryption_status_widget.dart';
import './widgets/verification_tools_widget.dart';
import './widgets/vote_signature_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Blockchain Vote Verification Hub - End-to-end encryption and audit logs
/// Implements RSA encryption, digital signatures, and blockchain verification
class BlockchainVoteVerificationHub extends StatefulWidget {
  const BlockchainVoteVerificationHub({super.key});

  @override
  State<BlockchainVoteVerificationHub> createState() =>
      _BlockchainVoteVerificationHubState();
}

class _BlockchainVoteVerificationHubState
    extends State<BlockchainVoteVerificationHub>
    with SingleTickerProviderStateMixin {
  final VotingService _votingService = VotingService.instance;
  final BlockchainVerificationService _blockchainService =
      BlockchainVerificationService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _encryptionStatus = {};
  List<Map<String, dynamic>> _blockchainAuditLogs = [];
  List<Map<String, dynamic>> _userVotes = [];
  Map<String, dynamic>? _currentError;
  Map<String, int> _errorAnalytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentError = null;
    });

    try {
      // Load error analytics
      _errorAnalytics = _blockchainService.getErrorAnalytics();

      // Mock data for demonstration
      setState(() {
        _encryptionStatus = {
          'encryption_enabled': true,
          'algorithm': 'RSA-2048',
          'public_key': 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...',
          'key_expiry': DateTime.now().add(Duration(days: 365)),
          'blockchain_sync': true,
          'verification_success_rate': 99.8,
        };

        _blockchainAuditLogs = [
          {
            'id': '1',
            'block_hash':
                '0x7f9fade1c0d57a7af66ab4ead79fade1c0d57a7af66ab4ead7c2c2eb7b11a91385',
            'transaction_hash':
                '0x3f4b0c8a2d9e1f6c5b8a7d3e2f1c0b9a8d7e6f5c4b3a2d1e0f9c8b7a6d5e4f3c',
            'block_number': 15234567,
            'timestamp': DateTime.now().subtract(Duration(hours: 2)),
            'verification_status': 'verified',
            'vote_count': 1,
          },
          {
            'id': '2',
            'block_hash':
                '0x8a0bfde2d1e68b8cg77bc5fbe90bfde2d1e68b8cg77bc5fbe8d3d3fc8c22b02496',
            'transaction_hash':
                '0x4g5c1d9b3e0f2g7d6c9b8e4f3g2d1c0b9a8e7f6d5c4b3a2e1f0g9d8c7b6e5f4g3d',
            'block_number': 15234566,
            'timestamp': DateTime.now().subtract(Duration(hours: 5)),
            'verification_status': 'verified',
            'vote_count': 3,
          },
        ];

        _userVotes = [
          {
            'id': 'vote_1',
            'election_title': 'Community Park Development',
            'vote_hash':
                '0xa1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6',
            'digital_signature': '0xsig_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
            'blockchain_hash':
                '0x7f9fade1c0d57a7af66ab4ead79fade1c0d57a7af66ab4ead7c2c2eb7b11a91385',
            'timestamp': DateTime.now().subtract(Duration(hours: 2)),
            'verification_status': 'verified',
          },
        ];
      });
    } catch (e) {
      setState(() {
        _currentError = {
          'error': 'load_failed',
          'message': 'Failed to load verification data',
          'suggestion': 'Check your connection and try again',
          'retry_available': true,
        };
      });
      debugPrint('Load blockchain data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'BlockchainVoteVerificationHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Vote Verification'),
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    EncryptionStatusWidget(encryptionStatus: _encryptionStatus),
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Encryption'),
                        Tab(text: 'Signatures'),
                        Tab(text: 'Blockchain'),
                        Tab(text: 'Verify'),
                        Tab(text: 'Analytics'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEncryptionTab(),
                          _buildSignaturesTab(),
                          _buildBlockchainTab(),
                          _buildVerificationTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEncryptionTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RSA Asymmetric Encryption',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInfoCard(
            'Algorithm',
            _encryptionStatus['algorithm'] ?? 'N/A',
            Icons.lock,
          ),
          SizedBox(height: 2.h),
          _buildInfoCard(
            'Public Key',
            _encryptionStatus['public_key'] ?? 'N/A',
            Icons.key,
            truncate: true,
          ),
          SizedBox(height: 2.h),
          _buildInfoCard(
            'Key Expiry',
            _encryptionStatus['key_expiry'] != null
                ? _encryptionStatus['key_expiry'].toString().substring(0, 10)
                : 'N/A',
            Icons.event,
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesTab() {
    if (_userVotes.isEmpty) {
      return Center(
        child: Text(
          'No votes with digital signatures',
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _userVotes.length,
      itemBuilder: (context, index) {
        return VoteSignatureWidget(vote: _userVotes[index]);
      },
    );
  }

  Widget _buildBlockchainTab() {
    return BlockchainAuditWidget(auditLogs: _blockchainAuditLogs);
  }

  Widget _buildVerificationTab() {
    return VerificationToolsWidget(onVerify: (hash) => _verifyVote(hash));
  }

  Widget _buildAnalyticsTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Analytics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          if (_errorAnalytics.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 15.w,
                      color: AppTheme.accentLight,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No errors recorded',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._errorAnalytics.entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatErrorType(entry.key),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            '${entry.value} occurrence${entry.value > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatErrorType(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    bool truncate = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  truncate && value.length > 40
                      ? '${value.substring(0, 40)}...'
                      : value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: truncate ? 1 : null,
                  overflow: truncate ? TextOverflow.ellipsis : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyVote(String hash) async {
    setState(() => _isLoading = true);

    final result = await _blockchainService.verifyVoteIntegrity(hash);

    setState(() => _isLoading = false);

    if (!result['success']) {
      setState(() => _currentError = result);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Vote verified successfully'),
          backgroundColor: result['is_valid']
              ? AppTheme.accentLight
              : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
