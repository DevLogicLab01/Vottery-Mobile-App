import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../services/redis_cache_service.dart';
import '../../../services/cache_warming_service.dart';

class ManualCacheControlPanelWidget extends StatefulWidget {
  const ManualCacheControlPanelWidget({super.key});

  @override
  State<ManualCacheControlPanelWidget> createState() =>
      _ManualCacheControlPanelWidgetState();
}

class _ManualCacheControlPanelWidgetState
    extends State<ManualCacheControlPanelWidget> {
  bool _isLoading = false;

  Future<void> _clearLeaderboardCaches() async {
    setState(() => _isLoading = true);
    try {
      final count = await RedisCacheService.instance.clear('leaderboard:*');
      Fluttertoast.showToast(msg: 'Cleared $count leaderboard cache entries');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCreatorCaches() async {
    setState(() => _isLoading = true);
    try {
      final count = await RedisCacheService.instance.clear('creator:*');
      Fluttertoast.showToast(msg: 'Cleared $count creator cache entries');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearElectionCaches() async {
    setState(() => _isLoading = true);
    try {
      final count = await RedisCacheService.instance.clear('election:*');
      Fluttertoast.showToast(msg: 'Cleared $count election cache entries');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _warmAllCaches() async {
    setState(() => _isLoading = true);
    try {
      await CacheWarmingService.instance.warmAll();
      Fluttertoast.showToast(msg: 'Cache warming completed successfully');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Manual Cache Control',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: [
                    _buildActionButton(
                      'Clear Leaderboard Caches',
                      const Color(0xFF6366F1),
                      Icons.leaderboard_outlined,
                      _clearLeaderboardCaches,
                    ),
                    _buildActionButton(
                      'Clear Creator Caches',
                      const Color(0xFF10B981),
                      Icons.person_outline,
                      _clearCreatorCaches,
                    ),
                    _buildActionButton(
                      'Clear Election Caches',
                      const Color(0xFFF59E0B),
                      Icons.how_to_vote_outlined,
                      _clearElectionCaches,
                    ),
                    _buildActionButton(
                      'Warm All Caches',
                      const Color(0xFF3B82F6),
                      Icons.local_fire_department_outlined,
                      _warmAllCaches,
                      isPrimary: true,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withAlpha(38),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(128)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : color, size: 14.sp),
            SizedBox(width: 1.5.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
