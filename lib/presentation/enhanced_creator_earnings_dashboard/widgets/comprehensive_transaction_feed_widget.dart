import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ComprehensiveTransactionFeedWidget extends StatelessWidget {
  const ComprehensiveTransactionFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildTransactionCard(index);
      },
    );
  }

  Widget _buildTransactionCard(int index) {
    final types = [
      'Election Fee',
      'Marketplace Sale',
      'Partnership',
      'Subscription',
    ];
    final type = types[index % types.length];
    final amount = (50 + index * 15).toDouble();

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(type).withAlpha(26),
          child: Icon(
            _getTypeIcon(type),
            color: _getTypeColor(type),
            size: 5.w,
          ),
        ),
        title: Text(
          type,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateTime.now()
              .subtract(Duration(hours: index))
              .toString()
              .split('.')[0],
          style: TextStyle(fontSize: 11.sp),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
            Text(
              'Completed',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Election Fee':
        return Icons.how_to_vote;
      case 'Marketplace Sale':
        return Icons.store;
      case 'Partnership':
        return Icons.handshake;
      case 'Subscription':
        return Icons.subscriptions;
      default:
        return Icons.attach_money;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Election Fee':
        return Colors.blue;
      case 'Marketplace Sale':
        return Colors.green;
      case 'Partnership':
        return Colors.purple;
      case 'Subscription':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
