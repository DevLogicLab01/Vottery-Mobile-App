import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class CampaignStatsHeaderWidget extends StatelessWidget {
  final int activeCampaigns;
  final int totalReach;
  final double avgCpe;
  final bool isLoading;

  const CampaignStatsHeaderWidget({
    super.key,
    required this.activeCampaigns,
    required this.totalReach,
    required this.avgCpe,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Active',
            value: isLoading ? '--' : activeCampaigns.toString(),
            icon: Icons.campaign,
          ),
          _Divider(),
          _StatItem(
            label: 'Total Reach',
            value: isLoading ? '--' : _formatNumber(totalReach),
            icon: Icons.people,
          ),
          _Divider(),
          _StatItem(
            label: 'Avg CPE',
            value: isLoading ? '--' : '\$${avgCpe.toStringAsFixed(2)}',
            icon: Icons.attach_money,
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 5.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 6.h, color: Colors.white.withAlpha(60));
  }
}
