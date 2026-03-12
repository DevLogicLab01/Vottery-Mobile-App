import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MarketResearchCacheWidget extends StatelessWidget {
  const MarketResearchCacheWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final marketResearchCache = [
      {
        'segment': 'Tech Advertisers',
        'cacheKey': 'market:tech:trends',
        'dataPoints': '1,247',
        'hitRate': '91.5%',
        'lastUpdate': '12 min ago',
        'ttl': '15 min',
      },
      {
        'segment': 'Healthcare Brands',
        'cacheKey': 'market:healthcare:insights',
        'dataPoints': '856',
        'hitRate': '88.3%',
        'lastUpdate': '8 min ago',
        'ttl': '15 min',
      },
      {
        'segment': 'Finance Sector',
        'cacheKey': 'market:finance:analysis',
        'dataPoints': '2,103',
        'hitRate': '94.7%',
        'lastUpdate': '5 min ago',
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
                Icons.analytics,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Market Research Cache',
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
            'Advertiser-segment based cache keys',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          ...marketResearchCache.map((cache) => _buildMarketCacheItem(cache)),
        ],
      ),
    );
  }

  Widget _buildMarketCacheItem(Map<String, dynamic> cache) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.5.w),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Icon(Icons.business, color: Colors.white, size: 16.sp),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cache['segment'],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      cache['cacheKey'],
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(child: _buildMetric('Data Points', cache['dataPoints'])),
              Expanded(child: _buildMetric('Hit Rate', cache['hitRate'])),
              Expanded(child: _buildMetric('TTL', cache['ttl'])),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(Icons.update, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                'Updated: ${cache['lastUpdate']}',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Refresh',
                  style: TextStyle(fontSize: 11.sp, color: Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
