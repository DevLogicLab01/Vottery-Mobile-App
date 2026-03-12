import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/payout_management_service.dart';

class AutomatedRetryTimelineWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const AutomatedRetryTimelineWidget({super.key, required this.onRefresh});

  @override
  State<AutomatedRetryTimelineWidget> createState() =>
      _AutomatedRetryTimelineWidgetState();
}

class _AutomatedRetryTimelineWidgetState
    extends State<AutomatedRetryTimelineWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _failedPayouts = [];

  @override
  void initState() {
    super.initState();
    _loadFailedPayouts();
  }

  Future<void> _loadFailedPayouts() async {
    setState(() => _isLoading = true);

    try {
      final payouts = await PayoutManagementService.instance.getFailedPayouts();
      if (mounted) {
        setState(() {
          _failedPayouts = payouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_failedPayouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 20.sp, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No failed payouts',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _failedPayouts.length,
      itemBuilder: (context, index) {
        final payout = _failedPayouts[index];
        return _buildPayoutCard(payout, theme);
      },
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout, ThemeData theme) {
    final retryAttempts = payout['payout_retry_attempts'] as List? ?? [];
    final attemptCount = retryAttempts.length;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout ID: ${payout['id']?.toString().substring(0, 8) ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Amount: \$${payout['amount_usd']}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[700],
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
                    color: Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    'FAILED',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Retry Timeline (Attempt $attemptCount/3)',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            if (retryAttempts.isEmpty)
              Text(
                'No retry attempts yet',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              )
            else
              ...retryAttempts.map(
                (attempt) => _buildRetryAttemptItem(attempt),
              ),
            SizedBox(height: 1.h),
            if (attemptCount < 3)
              ElevatedButton.icon(
                onPressed: () => _manualRetry(payout['id']),
                icon: Icon(Icons.refresh, size: 14.sp),
                label: Text('Manual Retry', style: TextStyle(fontSize: 11.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              )
            else
              Text(
                'Maximum retry attempts reached',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryAttemptItem(Map<String, dynamic> attempt) {
    final status = attempt['status'] as String;
    final attemptNumber = attempt['attempt_number'] as int;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'succeeded':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'retrying':
        statusColor = Colors.orange;
        statusIcon = Icons.refresh;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(statusIcon, size: 14.sp, color: statusColor),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attempt $attemptNumber - ${status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (attempt['attempted_at'] != null)
                  Text(
                    attempt['attempted_at'],
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                  ),
                if (attempt['failure_reason'] != null)
                  Text(
                    attempt['failure_reason'],
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _manualRetry(String payoutId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manual Retry'),
        content: Text('Are you sure you want to manually retry this payout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Retry'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await PayoutManagementService.instance.retryFailedPayout(
        payoutId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Retry initiated successfully'
                  : 'Failed to initiate retry',
            ),
          ),
        );

        if (success) {
          widget.onRefresh();
          _loadFailedPayouts();
        }
      }
    }
  }
}
