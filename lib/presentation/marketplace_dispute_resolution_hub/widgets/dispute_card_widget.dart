import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DisputeCardWidget extends StatelessWidget {
  final Map<String, dynamic> dispute;
  final VoidCallback onTap;
  final bool isAdmin;

  const DisputeCardWidget({
    required this.dispute,
    required this.onTap,
    this.isAdmin = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final status = dispute['status'] ?? 'open';
    final raisedAt = DateTime.parse(
      dispute['raised_at'] ?? DateTime.now().toIso8601String(),
    );
    final hoursSinceRaised = DateTime.now().difference(raisedAt).inHours;
    final isUrgent = status == 'open' && hoursSinceRaised > 48;

    final orderInfo = dispute['marketplace_orders'] as Map<String, dynamic>?;
    final serviceTitle =
        orderInfo?['marketplace_services']?['title'] ?? 'Unknown Service';
    final buyerInfo = orderInfo?['buyer'] as Map<String, dynamic>?;
    final sellerInfo = orderInfo?['seller'] as Map<String, dynamic>?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isUrgent ? Colors.red.shade300 : Colors.grey.shade200,
            width: isUrgent ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    serviceTitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 2.w),
                _buildStatusBadge(status),
                if (isUrgent) ...[
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: Colors.white, size: 4.w),
                        SizedBox(width: 1.w),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _buildUserAvatar(buyerInfo?['avatar_url'], 'Buyer'),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buyer: ${buyerInfo?['full_name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Seller: ${sellerInfo?['full_name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildUserAvatar(sellerInfo?['avatar_url'], 'Seller'),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                dispute['dispute_reason'] ?? 'No reason provided',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textPrimaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      timeago.format(raisedAt),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Order #${dispute['order_id']?.toString().substring(0, 8) ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'open':
        color = Colors.orange;
        label = 'OPEN';
        break;
      case 'under_review':
        color = Colors.blue;
        label = 'REVIEWING';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'RESOLVED';
        break;
      default:
        color = Colors.grey;
        label = 'UNKNOWN';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? avatarUrl, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 6.w,
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Icon(Icons.person, size: 6.w, color: AppTheme.primaryLight)
              : null,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(fontSize: 9.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}
