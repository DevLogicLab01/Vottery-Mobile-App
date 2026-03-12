import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class BlockedMessagesPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> blockedMessages;

  const BlockedMessagesPanelWidget({super.key, required this.blockedMessages});

  @override
  Widget build(BuildContext context) {
    final pendingCount = blockedMessages
        .where((m) => m['resend_status'] == 'pending')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Blocked Gamification SMS',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '$pendingCount Pending',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Messages blocked during Twilio fallback will be automatically resent when Telnyx is restored',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        SizedBox(height: 2.h),
        if (blockedMessages.isEmpty)
          Center(
            child: Column(
              children: [
                SizedBox(height: 4.h),
                Icon(Icons.check_circle, size: 48.sp, color: Colors.green),
                SizedBox(height: 2.h),
                Text(
                  'No blocked messages',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: blockedMessages.length,
            itemBuilder: (context, index) {
              final message = blockedMessages[index];
              return _buildMessageCard(message);
            },
          ),
      ],
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final category = message['message_category'] ?? 'unknown';
    final phone = message['recipient_phone'] ?? 'Unknown';
    final body = message['message_body'] ?? '';
    final blockedAt = message['blocked_at'] != null
        ? DateTime.parse(message['blocked_at'])
        : DateTime.now();
    final resendStatus = message['resend_status'] ?? 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: resendStatus == 'pending'
              ? Colors.orange.shade200
              : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.purple.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  phone,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                resendStatus == 'pending' ? Icons.pending : Icons.check_circle,
                size: 16.sp,
                color: resendStatus == 'pending' ? Colors.orange : Colors.green,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            body,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.block, size: 12.sp, color: Colors.red),
              SizedBox(width: 1.w),
              Text(
                'Blocked ${timeago.format(blockedAt)}',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
