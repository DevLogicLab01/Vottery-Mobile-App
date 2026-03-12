import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/payout_management_service.dart';
import '../../../theme/app_theme.dart';

class FailedPayoutRetryWidget extends StatefulWidget {
  const FailedPayoutRetryWidget({super.key});

  @override
  State<FailedPayoutRetryWidget> createState() =>
      _FailedPayoutRetryWidgetState();
}

class _FailedPayoutRetryWidgetState extends State<FailedPayoutRetryWidget> {
  final PayoutManagementService _payoutService =
      PayoutManagementService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _failedPayouts = [];
  String? _expandedPayoutId;
  List<Map<String, dynamic>> _retryAttempts = [];

  @override
  void initState() {
    super.initState();
    _loadFailedPayouts();
  }

  Future<void> _loadFailedPayouts() async {
    setState(() => _isLoading = true);

    try {
      final payouts = await _payoutService.getFailedPayouts();

      setState(() {
        _failedPayouts = payouts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRetryAttempts(String payoutId) async {
    try {
      final attempts = await _payoutService.getRetryAttempts(payoutId);

      setState(() {
        _retryAttempts = attempts;
        _expandedPayoutId = payoutId;
      });
    } catch (e) {
      debugPrint('Load retry attempts error: $e');
    }
  }

  Future<void> _retryPayout(String payoutId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Manual Retry'),
        content: Text(
          'Manually retry this failed payout? This will initiate a new retry attempt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _payoutService.retryFailedPayout(payoutId);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Retry initiated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadFailedPayouts();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to initiate retry'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Retry Now'),
          ),
        ],
      ),
    );
  }

  String _getFailureReasonText(String? reason) {
    if (reason == null) return 'Unknown error';

    switch (reason) {
      case 'insufficient_funds':
        return 'Insufficient Funds';
      case 'invalid_account':
        return 'Invalid Account Details';
      case 'bank_rejection':
        return 'Bank Rejected Transfer';
      case 'account_closed':
        return 'Account Closed';
      default:
        return reason.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getResolutionGuidance(String? reason) {
    if (reason == null) return 'Contact support for assistance';

    switch (reason) {
      case 'insufficient_funds':
        return 'Ensure sufficient balance in your Stripe account. Retry will occur automatically.';
      case 'invalid_account':
        return 'Update your bank account details in Stripe Connect settings.';
      case 'bank_rejection':
        return 'Contact your bank to authorize transfers from Stripe.';
      case 'account_closed':
        return 'Add a new bank account in Stripe Connect settings.';
      default:
        return 'Contact support for assistance with this error.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_failedPayouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 25.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Failed Payouts',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All payouts processed successfully',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _failedPayouts.length,
      itemBuilder: (context, index) {
        final payout = _failedPayouts[index];
        final payoutId = payout['id'];
        final amount = payout['amount_usd'] ?? 0.0;
        final failureReason = payout['failure_reason'];
        final createdAt = payout['created_at'] != null
            ? DateTime.parse(payout['created_at'])
            : null;
        final isExpanded = _expandedPayoutId == payoutId;

        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 6.w,
                  ),
                ),
                title: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 0.5.h),
                    Text(
                      _getFailureReasonText(failureReason),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat('MMM d, yyyy h:mm a').format(createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryLight,
                  ),
                  onPressed: () {
                    if (isExpanded) {
                      setState(() => _expandedPayoutId = null);
                    } else {
                      _loadRetryAttempts(payoutId);
                    }
                  },
                ),
              ),
              if (isExpanded) ...[
                Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resolution Guidance
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _getResolutionGuidance(failureReason),
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Retry History Timeline
                      Text(
                        'Retry Attempt History',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      if (_retryAttempts.isEmpty)
                        Text(
                          'No retry attempts yet',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        )
                      else
                        ..._retryAttempts.map((attempt) {
                          final attemptNumber = attempt['attempt_number'] ?? 0;
                          final attemptedAt = attempt['attempted_at'] != null
                              ? DateTime.parse(attempt['attempted_at'])
                              : null;
                          final status = attempt['status'] ?? 'unknown';

                          return Padding(
                            padding: EdgeInsets.only(bottom: 1.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: status == 'succeeded'
                                        ? Colors.green
                                        : status == 'failed'
                                        ? Colors.red
                                        : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$attemptNumber',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attempt $attemptNumber - ${status.toUpperCase()}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimaryLight,
                                        ),
                                      ),
                                      if (attemptedAt != null)
                                        Text(
                                          DateFormat(
                                            'MMM d, h:mm a',
                                          ).format(attemptedAt),
                                          style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            color: AppTheme.textSecondaryLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      SizedBox(height: 2.h),

                      // Manual Retry Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _retryAttempts.length < 3
                              ? () => _retryPayout(payoutId)
                              : null,
                          icon: Icon(Icons.refresh),
                          label: Text(
                            _retryAttempts.length < 3
                                ? 'Manual Retry'
                                : 'Max Retries Reached',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryLight,
                            disabledBackgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
