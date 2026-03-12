import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TestHistoryTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const TestHistoryTableWidget({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
            SizedBox(height: 2.h),
            Text(
              'No test history yet',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Execution History',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildHeader(),
                ...history.map((item) => _buildRow(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          topRight: Radius.circular(8.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Date',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Tier',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Duration',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Status',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item) {
    final status = item['test_status'] ?? 'unknown';
    final isPassed = status == 'completed';
    final userTier = item['user_tier'] ?? 0;
    final duration = item['test_duration_seconds'] ?? 0;
    final executedAt = item['executed_at'] != null
        ? DateTime.tryParse(item['executed_at'].toString())
        : null;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              executedAt != null
                  ? '${executedAt.month}/${executedAt.day} ${executedAt.hour}:${executedAt.minute.toString().padLeft(2, '0')}'
                  : 'N/A',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              _formatCount(userTier is int ? userTier : 0),
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              '${duration}s',
              style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: isPassed
                      ? const Color(0xFF4CAF50).withAlpha(26)
                      : const Color(0xFFFF6B35).withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  isPassed ? 'PASS' : 'FAIL',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: isPassed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6B35),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(0)}B';
    }
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(0)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}
