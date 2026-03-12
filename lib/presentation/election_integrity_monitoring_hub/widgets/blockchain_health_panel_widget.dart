import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class BlockchainHealthPanelWidget extends StatelessWidget {
  final int totalVotes;
  final int verifiedVotes;
  final double syncLagMs;
  final bool isHealthy;

  const BlockchainHealthPanelWidget({
    super.key,
    required this.totalVotes,
    required this.verifiedVotes,
    required this.syncLagMs,
    required this.isHealthy,
  });

  @override
  Widget build(BuildContext context) {
    final verificationRate = totalVotes > 0
        ? (verifiedVotes / totalVotes * 100)
        : 0.0;
    final failedVerifications = totalVotes - verifiedVotes;

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNetworkStatus(),
          SizedBox(height: 2.h),
          _buildMetricCard(
            'Votes On-Chain',
            '$verifiedVotes / $totalVotes',
            '${verificationRate.toStringAsFixed(1)}% verified',
            Icons.link,
            const Color(0xFF6C63FF),
          ),
          SizedBox(height: 1.h),
          _buildMetricCard(
            'Blockchain Sync Lag',
            '${syncLagMs.toStringAsFixed(0)}ms',
            syncLagMs < 500 ? 'Within acceptable range' : 'High lag detected',
            Icons.sync,
            syncLagMs < 500 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
          ),
          SizedBox(height: 1.h),
          _buildMetricCard(
            'Verification Rate',
            '${verificationRate.toStringAsFixed(1)}%',
            verificationRate >= 95
                ? 'Excellent verification rate'
                : 'Below target threshold',
            Icons.verified_outlined,
            verificationRate >= 95
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF6B35),
          ),
          SizedBox(height: 1.h),
          _buildMetricCard(
            'Failed Verifications',
            failedVerifications.toString(),
            failedVerifications == 0
                ? 'No failures detected'
                : 'Requires investigation',
            Icons.error_outline,
            failedVerifications == 0
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE53935),
          ),
          SizedBox(height: 2.h),
          _buildBlockProductionRate(),
        ],
      ),
    );
  }

  Widget _buildNetworkStatus() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isHealthy
            ? const Color(0xFF4CAF50).withAlpha(13)
            : const Color(0xFFE53935).withAlpha(13),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isHealthy
              ? const Color(0xFF4CAF50).withAlpha(77)
              : const Color(0xFFE53935).withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle : Icons.error,
            color: isHealthy
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE53935),
            size: 24,
          ),
          SizedBox(width: 3.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHealthy ? 'Blockchain Network Healthy' : 'Network Degraded',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isHealthy
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935),
                ),
              ),
              Text(
                'All nodes connected • Block production normal',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10.sp, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockProductionRate() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Block Production Rate',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBlockStat('Blocks/Min', '12.4'),
              _buildBlockStat('Avg Block Time', '4.8s'),
              _buildBlockStat('Pending Txns', '23'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6C63FF),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
