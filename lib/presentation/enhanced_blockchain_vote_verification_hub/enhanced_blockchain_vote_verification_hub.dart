import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/blockchain_error_service.dart';
import '../../services/blockchain_verification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/error_analytics_widget.dart';
import './widgets/error_recovery_widget.dart';
import './widgets/verification_error_card_widget.dart';
import './widgets/verification_retry_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Enhanced Blockchain Vote Verification Hub with comprehensive error handling
/// Implements RSA decryption failure handling, blockchain timeout management,
/// invalid hash detection, and user-friendly error states with recovery suggestions
class EnhancedBlockchainVoteVerificationHub extends StatefulWidget {
  const EnhancedBlockchainVoteVerificationHub({super.key});

  @override
  State<EnhancedBlockchainVoteVerificationHub> createState() =>
      _EnhancedBlockchainVoteVerificationHubState();
}

class _EnhancedBlockchainVoteVerificationHubState
    extends State<EnhancedBlockchainVoteVerificationHub>
    with SingleTickerProviderStateMixin {
  final BlockchainVerificationService _verificationService =
      BlockchainVerificationService.instance;
  final BlockchainErrorService _errorService = BlockchainErrorService.instance;
  final TextEditingController _receiptController = TextEditingController();

  late TabController _tabController;

  bool _isLoading = false;
  bool _isVerifying = false;
  Map<String, dynamic>? _verificationResult;
  Map<String, dynamic>? _errorResult;
  Map<String, dynamic> _errorAnalytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadErrorAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _loadErrorAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final analytics = await _errorService.getErrorAnalytics();
      setState(() {
        _errorAnalytics = analytics;
      });
    } catch (e) {
      debugPrint('Load error analytics error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyVote() async {
    if (_receiptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a receipt code')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationResult = null;
      _errorResult = null;
    });

    try {
      final result = await _errorService.verifyVoteWithErrorHandling(
        _receiptController.text.trim(),
      );

      setState(() {
        if (result['success'] == true) {
          _verificationResult = result['data'];
          _errorResult = null;
        } else {
          _verificationResult = null;
          _errorResult = result;
        }
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vote verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Verify vote error: $e');
      setState(() {
        _errorResult = {
          'success': false,
          'errorType': BlockchainErrorType.unknown,
          'errorMessage': 'An unexpected error occurred',
        };
      });
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _retryVerification() async {
    await _verifyVote();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'EnhancedBlockchainVoteVerificationHub',
      onRetry: _loadErrorAnalytics,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Vote Verification',
            variant: CustomAppBarVariant.standard,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: _loadErrorAnalytics,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildVerificationHeader(Theme.of(context)),
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Verify'),
                      Tab(text: 'Error Analytics'),
                      Tab(text: 'Help'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVerificationTab(Theme.of(context)),
                        _buildErrorAnalyticsTab(Theme.of(context)),
                        _buildHelpTab(Theme.of(context)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVerificationHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.accentLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Blockchain Vote Verification',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Verify vote integrity with advanced error handling',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReceiptInput(theme),
          SizedBox(height: 2.h),
          if (_isVerifying) _buildVerifyingIndicator(theme),
          if (_verificationResult != null)
            _buildSuccessResult(theme, _verificationResult!),
          if (_errorResult != null) ...[
            VerificationErrorCardWidget(errorResult: _errorResult!),
            SizedBox(height: 2.h),
            ErrorRecoveryWidget(
              errorType: _errorResult!['errorType'] as BlockchainErrorType,
              onRetry: _retryVerification,
            ),
            SizedBox(height: 2.h),
            VerificationRetryWidget(
              onRetry: _retryVerification,
              retryCount: _errorResult!['retryCount'] ?? 0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptInput(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Receipt Code',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _receiptController,
              decoration: InputDecoration(
                hintText: 'e.g., VR-ABC123-XYZ789',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.receipt_long),
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyVote,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                _isVerifying ? 'Verifying...' : 'Verify Vote',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyingIndicator(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            SizedBox(height: 2.h),
            Text(
              'Verifying vote on blockchain...',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              'This may take up to 30 seconds',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessResult(ThemeData theme, Map<String, dynamic> result) {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 8.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Vote Verified Successfully',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildResultRow(
              theme,
              'Vote Hash',
              result['vote_hash']?.toString() ?? 'N/A',
            ),
            _buildResultRow(
              theme,
              'Block Number',
              result['block_number']?.toString() ?? 'N/A',
            ),
            _buildResultRow(
              theme,
              'Status',
              result['verification_status']?.toString() ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorAnalyticsTab(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: ErrorAnalyticsWidget(analytics: _errorAnalytics),
    );
  }

  Widget _buildHelpTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpSection(theme, 'Common Error Types', [
            '🔐 RSA Decryption Error: Encryption key issues',
            '⏱️ Blockchain Timeout: Network connectivity problems',
            '⚠️ Invalid Hash: Vote integrity compromised',
            '🌐 Network Error: Connection issues',
            '❌ Verification Failed: Receipt code not found',
            '📅 Expired Certificate: Verification period ended',
          ]),
          SizedBox(height: 2.h),
          _buildHelpSection(theme, 'Troubleshooting Tips', [
            'Check your internet connection',
            'Verify receipt code for typos',
            'Wait 30 seconds for timeout',
            'Contact support if issues persist',
            'Save receipt code for reference',
          ]),
        ],
      ),
    );
  }

  Widget _buildHelpSection(ThemeData theme, String title, List<String> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            ...items.map(
              (item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12.sp,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
