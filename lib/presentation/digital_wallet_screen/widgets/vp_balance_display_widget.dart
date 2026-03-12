import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class VPBalanceDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> vpBalance;
  final Map<String, double> exchangeRates;

  const VPBalanceDisplayWidget({
    super.key,
    required this.vpBalance,
    required this.exchangeRates,
  });

  @override
  State<VPBalanceDisplayWidget> createState() => _VPBalanceDisplayWidgetState();
}

class _VPBalanceDisplayWidgetState extends State<VPBalanceDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayedBalance = 0;

  @override
  void initState() {
    super.initState();
    final targetBalance = (widget.vpBalance['available_vp'] ?? 0) as int;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation =
        Tween<double>(begin: 0, end: targetBalance.toDouble()).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        )..addListener(() {
          setState(() {
            _displayedBalance = _animation.value.toInt();
          });
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifetimeEarned = (widget.vpBalance['lifetime_earned'] ?? 0) as int;
    final pendingRewards = (widget.vpBalance['pending_vp'] ?? 0) as int;
    final dailyChange = (widget.vpBalance['daily_change'] ?? 0) as int;
    final usdValue =
        _displayedBalance * 0.002; // 2000 VP = $10, so 1 VP = $0.005

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withAlpha(77),
            blurRadius: 15.0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: dailyChange >= 0
                      ? AppTheme.accentLight.withAlpha(77)
                      : AppTheme.errorLight.withAlpha(77),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      dailyChange >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 12.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${dailyChange >= 0 ? '+' : ''}$dailyChange VP',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_displayedBalance',
                style: GoogleFonts.inter(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              SizedBox(width: 2.w),
              Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  'VP',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            '≈ \$${usdValue.toStringAsFixed(2)} USD',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Lifetime Earned',
                  '$lifetimeEarned VP',
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  'Pending Rewards',
                  '$pendingRewards VP',
                  Icons.pending,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18.sp),
          SizedBox(height: 1.h),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
