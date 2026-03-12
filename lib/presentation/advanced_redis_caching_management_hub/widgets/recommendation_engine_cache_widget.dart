import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RecommendationEngineCacheWidget extends StatelessWidget {
  const RecommendationEngineCacheWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cacheEntries = [
      {
        'key': 'user:12345:recommendations',
        'type': 'Election Recommendations',
        'size': '24 KB',
        'hits': '1,247',
        'lastAccess': '2 min ago',
        'ttl': '10 min',
      },
      {
        'key': 'user:67890:feed',
        'type': 'Personalized Feed',
        'size': '18 KB',
        'hits': '856',
        'lastAccess': '5 min ago',
        'ttl': '5 min',
      },
      {
        'key': 'user:54321:content',
        'type': 'Content Suggestions',
        'size': '32 KB',
        'hits': '2,103',
        'lastAccess': '1 min ago',
        'ttl': '15 min',
      },
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Recommendation Engine Cache',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'User-specific cache keys with personalized content',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ...cacheEntries.map((entry) => _buildCacheEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildCacheEntry(Map<String, dynamic> entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry['type'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            entry['key'],
            style: TextStyle(
              fontSize: 11.sp,
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildInfoChip('Size', entry['size'], Icons.storage),
              SizedBox(width: 2.w),
              _buildInfoChip('Hits', entry['hits'], Icons.touch_app),
              SizedBox(width: 2.w),
              _buildInfoChip('TTL', entry['ttl'], Icons.timer),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                'Last access: ${entry['lastAccess']}',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 16.sp,
                  color: Colors.red,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.grey[600]),
          SizedBox(width: 1.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
