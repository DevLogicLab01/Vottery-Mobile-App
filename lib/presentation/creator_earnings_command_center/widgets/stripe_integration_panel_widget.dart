import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StripeIntegrationPanelWidget extends StatelessWidget {
  final Map<String, dynamic> stripeStatus;
  final VoidCallback onRefresh;

  const StripeIntegrationPanelWidget({
    super.key,
    required this.stripeStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = stripeStatus['connected'] ?? false;
    final accountStatus = stripeStatus['account_status'] ?? 'not_connected';
    final nextPayoutDate = stripeStatus['next_payout_date'];
    final pendingBalance = stripeStatus['pending_balance'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stripe Integration',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withAlpha(26)
                      : Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle : Icons.warning,
                      color: isConnected ? Colors.green : Colors.orange,
                      size: 14.sp,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      isConnected ? 'Connected' : 'Not Connected',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.orange,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (isConnected) ...[
            _buildStatusRow(
              'Account Status',
              _formatAccountStatus(accountStatus),
              _getStatusColor(accountStatus),
            ),
            SizedBox(height: 1.h),
            _buildStatusRow(
              'Pending Balance',
              '\$${pendingBalance.toStringAsFixed(2)}',
              Colors.blue,
            ),
            if (nextPayoutDate != null) ...[
              SizedBox(height: 1.h),
              _buildStatusRow(
                'Next Payout',
                _formatDate(nextPayoutDate),
                Colors.purple,
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh Status'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewStripeDetails(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Connect your Stripe account to receive payouts',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _connectStripe(context),
                      icon: const Icon(Icons.link),
                      label: const Text('Connect Stripe Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
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
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatAccountStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending Verification';
      case 'restricted':
        return 'Restricted';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'restricted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final DateTime dateTime = date is DateTime
          ? date
          : DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  void _connectStripe(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to Stripe Connect...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewStripeDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stripe Account Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account ID: ${stripeStatus['account_id'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(
              'Status: ${_formatAccountStatus(stripeStatus['account_status'] ?? '')}',
            ),
            const SizedBox(height: 8),
            Text(
              'Pending Balance: \$${(stripeStatus['pending_balance'] ?? 0.0).toStringAsFixed(2)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
