import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PartnershipStatusHeaderWidget extends StatelessWidget {
  final int activeCampaigns;
  final double totalRevenue;
  final int portfolioCompletion;

  const PartnershipStatusHeaderWidget({
    super.key,
    required this.activeCampaigns,
    required this.totalRevenue,
    required this.portfolioCompletion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.campaign,
            label: 'Active Campaigns',
            value: activeCampaigns.toString(),
          ),
          Container(width: 1, height: 8.h, color: Colors.white.withAlpha(77)),
          _buildStatItem(
            context,
            icon: Icons.attach_money,
            label: 'Total Revenue',
            value: '\$${totalRevenue.toStringAsFixed(0)}',
          ),
          Container(width: 1, height: 8.h, color: Colors.white.withAlpha(77)),
          _buildStatItem(
            context,
            icon: Icons.folder_special,
            label: 'Portfolio',
            value: '$portfolioCompletion%',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 8.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white.withAlpha(230)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
