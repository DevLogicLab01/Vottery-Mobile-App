import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AiServiceCacheWidget extends StatelessWidget {
  const AiServiceCacheWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final aiServices = [
      {
        'service': 'Claude Recommendations',
        'ttl': '5 min',
        'hitRate': '96.8%',
        'entries': '1,247',
        'avgResponseTime': '12ms',
        'color': Colors.purple,
      },
      {
        'service': 'Perplexity Market Research',
        'ttl': '15 min',
        'hitRate': '89.3%',
        'entries': '856',
        'avgResponseTime': '18ms',
        'color': Colors.blue,
      },
      {
        'service': 'OpenAI Embeddings',
        'ttl': '1 hour',
        'hitRate': '98.5%',
        'entries': '3,421',
        'avgResponseTime': '8ms',
        'color': Colors.teal,
      },
      {
        'service': 'Gemini Analysis',
        'ttl': '10 min',
        'hitRate': '92.1%',
        'entries': '645',
        'avgResponseTime': '15ms',
        'color': Colors.orange,
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
                Icons.psychology,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'AI Service Cache',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...aiServices.map((service) => _buildServiceItem(service)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: (service['color'] as Color).withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: (service['color'] as Color).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: service['color'],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  service['service'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: service['color'],
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'TTL: ${service['ttl']}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(child: _buildMetric('Hit Rate', service['hitRate'])),
              Expanded(child: _buildMetric('Entries', service['entries'])),
              Expanded(
                child: _buildMetric('Avg Time', service['avgResponseTime']),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.refresh, size: 14.sp),
                  label: Text('Invalidate', style: TextStyle(fontSize: 11.sp)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: service['color'],
                    side: BorderSide(color: service['color'] as Color),
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.settings, size: 14.sp),
                  label: Text('Configure', style: TextStyle(fontSize: 11.sp)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                  ),
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
