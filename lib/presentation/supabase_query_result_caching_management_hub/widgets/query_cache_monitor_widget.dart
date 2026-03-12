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

  final List<Map<String, dynamic>> _mockEntries = [
    {
      'key': 'user_profile:abc123',
      'ttl': 287,
      'hits': 42,
      'pattern': 'user_profile',
    },
    {
      'key': 'election_feed:1234567',
      'ttl': 198,
      'hits': 156,
      'pattern': 'election_feed',
    },
    {
      'key': 'creator_analytics:xyz789',
      'ttl': 241,
      'hits': 28,
      'pattern': 'creator_analytics',
    },
    {
      'key': 'leaderboard:global',
      'ttl': 142,
      'hits': 89,
      'pattern': 'leaderboard',
    },
    {
      'key': 'election_stats:456',
      'ttl': 78,
      'hits': 34,
      'pattern': 'election_stats',
    },
    {
      'key': 'user_dashboard:user1',
      'ttl': 312,
      'hits': 67,
      'pattern': 'user_dashboard',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final stats = _cacheService.getStats();
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
                '${_mockEntries.length}',
                const Color(0xFF6366F1),
              ),
              SizedBox(width: 2.w),
              _statChip(
                'In-Flight',
                '${stats['inFlightRequests'] ?? 0}',
                const Color(0xFFF59E0B),
              ),
              SizedBox(width: 2.w),
              _statChip('TTL', '5 min', const Color(0xFF3B82F6)),
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
          ..._mockEntries.map((entry) => _cacheRow(entry)),
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
    final ttl = entry['ttl'] as int;
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
                  entry['pattern'] as String,
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
              '${entry['hits']}',
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
