import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../routes/app_routes.dart';
import '../../../services/creator_earnings_service.dart';

class EarningsTransactionFeedWidget extends StatelessWidget {
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;

  EarningsTransactionFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.payoutHistoryScreen);
                },
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _earningsService.streamRecentTransactions(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(2.h),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final transactions = snapshot.data ?? [];

              if (transactions.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(2.h),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: transactions.map((transaction) {
                  return _buildTransactionItem(transaction);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final transactionType = transaction['transaction_type'] ?? 'unknown';
    final vpAmount = transaction['vp_amount'] ?? 0;
    final usdAmount = transaction['usd_amount'] ?? 0.0;
    final description = transaction['description'] ?? 'Transaction';
    final createdAt = transaction['created_at'] != null
        ? DateTime.parse(transaction['created_at'])
        : DateTime.now();

    final icon = _getTransactionIcon(transactionType);
    final color = _getTransactionColor(transactionType);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: CustomIconWidget(iconName: icon, size: 5.w, color: color),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _formatTimestamp(createdAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$vpAmount VP',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentLight,
                ),
              ),
              Text(
                '+\$${usdAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTransactionIcon(String type) {
    switch (type) {
      case 'vp_earned':
        return 'stars';
      case 'vote_reward':
        return 'how_to_vote';
      case 'election_prize':
        return 'emoji_events';
      case 'subscription_payment':
        return 'card_membership';
      default:
        return 'attach_money';
    }
  }

  Color _getTransactionColor(String type) {
    switch (type) {
      case 'vp_earned':
        return AppTheme.vibrantYellow;
      case 'vote_reward':
        return AppTheme.primaryLight;
      case 'election_prize':
        return AppTheme.accentLight;
      case 'subscription_payment':
        return AppTheme.secondaryLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
