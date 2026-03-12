import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// Lottery ticket preview widget shown inline during voting for gamified elections
class LotteryTicketPreviewWidget extends StatefulWidget {
  final String ticketNumber;
  final int entryCount;
  final int totalVoters;
  final DateTime? drawDate;

  const LotteryTicketPreviewWidget({
    super.key,
    required this.ticketNumber,
    required this.entryCount,
    required this.totalVoters,
    this.drawDate,
  });

  @override
  State<LotteryTicketPreviewWidget> createState() =>
      _LotteryTicketPreviewWidgetState();
}

class _LotteryTicketPreviewWidgetState extends State<LotteryTicketPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  String get _countdownText {
    if (widget.drawDate == null) return 'Draw date TBD';
    final diff = widget.drawDate!.difference(DateTime.now());
    if (diff.isNegative) return 'Draw completed';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    return '${days}d ${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFD700),
                const Color(0xFFFFA500),
                const Color(0xFFFFD700),
              ],
              stops: [
                (_shimmerAnimation.value - 0.5).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.5).clamp(0.0, 1.0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha(100),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.white, size: 6.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎉 You\'re in the Lottery!',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Ticket #${widget.ticketNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTicketStat(
                  'Your Entries',
                  '${widget.entryCount}',
                  Icons.star,
                ),
                _buildTicketStat(
                  'Total Voters',
                  '${widget.totalVoters}',
                  Icons.people,
                ),
                _buildTicketStat(
                  'Your Odds',
                  '1 in ${widget.totalVoters > 0 ? widget.totalVoters : "?"}',
                  Icons.casino,
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.white, size: 4.w),
                  SizedBox(width: 1.5.w),
                  Text(
                    'Draw in: $_countdownText',
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
      ),
    );
  }

  Widget _buildTicketStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 5.w),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Colors.white.withAlpha(200),
          ),
        ),
      ],
    );
  }
}
