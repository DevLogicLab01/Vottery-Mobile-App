import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BlockchainExplorerWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentTransactions;

  const BlockchainExplorerWidget({super.key, required this.recentTransactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Gamification Activity',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (recentTransactions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            )
          else
            ...recentTransactions.take(5).map((tx) {
              final type = tx['transaction_type'] ?? 'unknown';
              final hash = tx['transaction_hash'] ?? 'Pending';
              final isVerified = tx['verification_status'] == 'verified';

              IconData icon;
              Color color;
              String label;

              switch (type) {
                case 'vp_transaction':
                  icon = Icons.account_balance_wallet;
                  color = Colors.blue;
                  label = 'VP Transaction';
                  break;
                case 'badge_award':
                  icon = Icons.emoji_events;
                  color = Colors.amber;
                  label = 'Badge Award';
                  break;
                case 'challenge_completion':
                  icon = Icons.task_alt;
                  color = Colors.green;
                  label = 'Challenge';
                  break;
                case 'prediction_resolution':
                  icon = Icons.trending_up;
                  color = Colors.purple;
                  label = 'Prediction';
                  break;
                default:
                  icon = Icons.receipt;
                  color = Colors.grey;
                  label = 'Transaction';
              }

              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 16.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            hash.length > 20
                                ? '${hash.substring(0, 20)}...'
                                : hash,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey.shade600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isVerified ? Icons.verified : Icons.pending,
                      size: 14.sp,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
