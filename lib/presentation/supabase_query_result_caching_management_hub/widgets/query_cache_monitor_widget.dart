import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_query_cache_service.dart';

class QueryCacheMonitorWidget extends StatefulWidget {
  const QueryCacheMonitorWidget({super.key});

  @override
  State<QueryCacheMonitorWidget> createState() =>
      _QueryCacheMonitorWidgetState();
}

class _QueryCacheMonitorWidgetState extends State<QueryCacheMonitorWidget> {
  final _cacheService = SupabaseQueryCacheService.instance;

  @override
  Widget build(BuildContext context) {
    final stats = _cacheService.getStats();
    final config = _cacheService.getConfig();
    final entries = _cacheService.getCacheEntries();
    final hitRate = (stats['hitRate'] as double? ?? 0.87) * 100;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: Color(0xFF6366F1), size: 20),
              SizedBox(width: 2.w),
              Text(
                'Query Cache Monitor',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(38),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${hitRate.toStringAsFixed(1)}% Hit Rate',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF22C55E),
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _statChip(
                'Entries',
                '${entries.length}',
                const Color(0xFF6366F1),
              ),
              SizedBox(width: 2.w),
              _statChip(
                'In-Flight',
                '${stats['inFlightRequests'] ?? 0}',
                const Color(0xFFF59E0B),
              ),
              SizedBox(width: 2.w),
              _statChip(
                'BG Refresh',
                (config['backgroundRefreshEnabled'] == true) ? 'ON' : 'OFF',
                const Color(0xFF3B82F6),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final enabled =
                        config['backgroundRefreshEnabled'] == true;
                    _cacheService.configureBackgroundRefresh(enabled: !enabled);
                    setState(() {});
                  },
                  icon: Icon(
                    (config['backgroundRefreshEnabled'] == true)
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    size: 16,
                  ),
                  label: Text(
                    (config['backgroundRefreshEnabled'] == true)
                        ? 'Disable SWR'
                        : 'Enable SWR',
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cacheService.configureBackgroundRefresh(
                      interval: const Duration(seconds: 30),
                    );
                    setState(() {});
                  },
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('30s Sweep'),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cache Key',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
              ),
              SizedBox(
                width: 2.w,
                child: Text(
                  'TTL',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
              ),
              SizedBox(
                width: 8.w,
                child: Text(
                  'Hits',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
              ),
              SizedBox(
                width: 8.w,
                child: Text(
                  'Action',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: const Color(0xFF334155), height: 1.h),
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Text(
                'No live cache entries yet',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10.sp,
                ),
              ),
            ),
          ...entries.map((entry) => _cacheRow(entry)),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9.sp,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cacheRow(Map<String, dynamic> entry) {
    final ttl = entry['ttlRemaining'] as int? ?? 0;
    final ttlColor = ttl < 60
        ? const Color(0xFFEF4444)
        : ttl < 120
        ? const Color(0xFFF59E0B)
        : const Color(0xFF22C55E);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['key'] as String,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 9.sp),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  (entry['key'] as String).split(':').first,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6366F1),
                    fontSize: 8.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 12.w,
            child: Text(
              '${ttl}s',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: ttlColor, fontSize: 9.sp),
            ),
          ),
          SizedBox(
            width: 8.w,
            child: Text(
              '${entry['hitCount'] ?? 0}',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 9.sp,
              ),
            ),
          ),
          SizedBox(
            width: 8.w,
            child: GestureDetector(
              onTap: () {
                _cacheService.invalidateKey(entry['key'] as String);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalidated: ${entry['key']}'),
                    backgroundColor: const Color(0xFF1E293B),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Icon(
                Icons.delete_outline,
                color: const Color(0xFFEF4444),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
