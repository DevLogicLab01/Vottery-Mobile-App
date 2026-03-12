import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PrizePreviewWidget extends StatelessWidget {
  final String prizeType;
  final Map<String, dynamic> config;

  const PrizePreviewWidget({
    super.key,
    required this.prizeType,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: Colors.blue[700], size: 18.sp),
              SizedBox(width: 2.w),
              Text(
                'Prize Preview',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildPreviewContent(),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (prizeType == 'monetary') {
      final monetaryConfig = config['monetary_config'];
      if (monetaryConfig == null) {
        return Text('Configure monetary prize details');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Prize Pool',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          Text(
            '${monetaryConfig['currency']} ${monetaryConfig['amount']?.toStringAsFixed(2) ?? "0.00"}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          if (config['multiple_winners_enabled'] == true) ...[
            SizedBox(height: 1.h),
            Text(
              '${config['winner_count']} Winners',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
            ),
          ],
        ],
      );
    } else if (prizeType == 'non_monetary') {
      final nonMonetaryConfig = config['non_monetary_config'];
      if (nonMonetaryConfig == null) {
        return Text('Configure non-monetary prize details');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nonMonetaryConfig['title'] ?? 'Prize Title',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            nonMonetaryConfig['description'] ?? '',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Text(
            'Est. Value: \$${nonMonetaryConfig['value']?.toStringAsFixed(2) ?? "0.00"}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green[900],
            ),
          ),
        ],
      );
    } else if (prizeType == 'revenue_sharing') {
      final revenueConfig = config['revenue_share_config'];
      if (revenueConfig == null) {
        return Text('Configure revenue sharing details');
      }
      final projectedRevenue = revenueConfig['projected_revenue'] ?? 0.0;
      final sharePercentage = revenueConfig['share_percentage'] ?? 0.0;
      final estimatedPayout = projectedRevenue * (sharePercentage / 100);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Sharing Prize',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          Text(
            '${sharePercentage.toStringAsFixed(0)}% of Revenue',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Estimated Payout: \$${estimatedPayout.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green[900],
            ),
          ),
        ],
      );
    }

    return Text('Select a prize type to see preview');
  }
}