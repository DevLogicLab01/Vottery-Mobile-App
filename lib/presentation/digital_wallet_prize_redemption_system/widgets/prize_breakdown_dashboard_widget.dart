import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PrizeBreakdownDashboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> prizeBreakdown;
  final String currency;

  const PrizeBreakdownDashboardWidget({
    super.key,
    required this.prizeBreakdown,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prize Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          ...prizeBreakdown.map((prize) => _buildPrizeItem(prize)),
        ],
      ),
    );
  }

  Widget _buildPrizeItem(Map<String, dynamic> prize) {
    final type = prize['type'] ?? '';
    final amount = prize['amount'] ?? 0.0;
    final source = prize['source'] ?? '';

    IconData icon;
    Color color;

    switch (type) {
      case 'lottery':
        icon = Icons.casino;
        color = Colors.purple;
        break;
      case 'prediction_pool':
        icon = Icons.analytics;
        color = Colors.blue;
        break;
      case 'quest':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      default:
        icon = Icons.attach_money;
        color = Colors.green;
    }

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
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  source,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '+\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
