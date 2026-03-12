import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TotalRevenueCardWidget extends StatefulWidget {
  final double totalRevenue;
  final double monthOverMonthChange;

  const TotalRevenueCardWidget({
    super.key,
    required this.totalRevenue,
    required this.monthOverMonthChange,
  });

  @override
  State<TotalRevenueCardWidget> createState() => _TotalRevenueCardWidgetState();
}

class _TotalRevenueCardWidgetState extends State<TotalRevenueCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.totalRevenue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.monthOverMonthChange >= 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF89B4FA).withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF89B4FA).withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF89B4FA).withAlpha(38),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF89B4FA),
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Total Revenue',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFA6E3A1).withAlpha(38)
                      : const Color(0xFFF38BA8).withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive
                          ? const Color(0xFFA6E3A1)
                          : const Color(0xFFF38BA8),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${widget.monthOverMonthChange.abs().toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? const Color(0xFFA6E3A1)
                            : const Color(0xFFF38BA8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Text(
                '\$${_animation.value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: GoogleFonts.inter(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              );
            },
          ),
          SizedBox(height: 0.5.h),
          Text(
            'All revenue streams combined',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
