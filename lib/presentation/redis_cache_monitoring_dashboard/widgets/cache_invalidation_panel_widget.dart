import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/redis_cache_service.dart';

class CacheInvalidationPanelWidget extends StatelessWidget {
  const CacheInvalidationPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final log = RedisCacheService.instance.invalidationLog;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2D2D3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Cache Invalidations',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          log.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Text(
                      'No invalidations recorded yet',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: log.take(10).length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white12, height: 1.h),
                  itemBuilder: (context, index) {
                    final item = log[index];
                    final reason = item['reason'] as String;
                    final isScheduled =
                        reason.contains('warm') || reason.contains('scheduled');
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.5.h),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isScheduled
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['key_pattern'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item['reason']} • ${_formatTime(item['timestamp'] as String)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 1.5.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: isScheduled
                                  ? const Color(0xFF6366F1).withAlpha(51)
                                  : const Color(0xFFF59E0B).withAlpha(51),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              isScheduled ? 'scheduled' : 'user_action',
                              style: GoogleFonts.inter(
                                fontSize: 8.sp,
                                color: isScheduled
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return isoString;
    }
  }
}
