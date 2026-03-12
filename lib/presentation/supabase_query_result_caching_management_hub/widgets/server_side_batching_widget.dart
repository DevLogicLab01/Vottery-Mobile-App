import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';


class ServerSideBatchingWidget extends StatelessWidget {
  const ServerSideBatchingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final batchMethods = [
      {
        'method': 'batchGetUserProfiles',
        'desc': 'Single .inFilter() for multiple user IDs',
        'savings': '94%',
        'calls': 156,
      },
      {
        'method': 'batchGetElections',
        'desc': 'Single query for multiple election IDs',
        'savings': '89%',
        'calls': 78,
      },
      {
        'method': 'batchGetVoteCounts',
        'desc': 'RPC get_elections_batch reduces N+1',
        'savings': '92%',
        'calls': 234,
      },
    ];

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
              const Icon(
                Icons.batch_prediction,
                color: Color(0xFF22C55E),
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Server-Side Batching',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withAlpha(20),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF22C55E).withAlpha(51)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF22C55E),
                  size: 14,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'BatchRequestQueue flushes every 50ms or 10 requests — eliminates N+1 patterns',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF22C55E),
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Batch Method',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
              ),
              SizedBox(
                width: 10.w,
                child: Text(
                  'Savings',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 9.sp,
                  ),
                ),
              ),
              SizedBox(
                width: 10.w,
                child: Text(
                  'Calls',
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
          ...batchMethods.map((m) => _batchRow(m)),
          SizedBox(height: 2.h),
          Text(
            'Queue Configuration',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          _configRow('Flush Interval', '50ms'),
          _configRow('Max Batch Size', '10 requests'),
          _configRow('Deduplication', 'Enabled'),
          _configRow('In-Flight Tracking', 'Active'),
        ],
      ),
    );
  }

  Widget _batchRow(Map<String, dynamic> m) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['method'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  m['desc'] as String,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 8.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(26),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                m['savings'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF22C55E),
                  fontSize: 9.sp,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 10.w,
            child: Text(
              '${m['calls']}',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 9.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configRow(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 10.sp,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
