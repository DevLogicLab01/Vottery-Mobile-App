import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CacheManagementWidget extends StatelessWidget {
  const CacheManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInvalidationStrategies(),
        SizedBox(height: 2.h),
        _buildEvictionPolicy(),
        SizedBox(height: 2.h),
        _buildCacheWarming(),
      ],
    );
  }

  Widget _buildInvalidationStrategies() {
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
              Icon(Icons.refresh, color: const Color(0xFF632CA6), size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Invalidation Strategies',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildStrategyItem(
            'Cache-Aside Pattern',
            'Load data on demand, cache on first access',
            true,
            Colors.blue,
          ),
          SizedBox(height: 1.h),
          _buildStrategyItem(
            'Write-Through',
            'Write to cache and database simultaneously',
            true,
            Colors.green,
          ),
          SizedBox(height: 1.h),
          _buildStrategyItem(
            'Time-Based Expiration',
            'Configurable TTL per data type',
            true,
            Colors.orange,
          ),
          SizedBox(height: 1.h),
          _buildStrategyItem(
            'Event-Based Invalidation',
            'Triggered by Supabase real-time subscriptions',
            true,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyItem(
    String title,
    String description,
    bool enabled,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              enabled ? Icons.check : Icons.close,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {},
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildEvictionPolicy() {
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
                Icons.delete_sweep,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'LRU Eviction Policy',
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
            'Least Recently Used (LRU) policy manages memory efficiently',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          _buildPolicyMetric('Max Memory', '4 GB'),
          SizedBox(height: 1.h),
          _buildPolicyMetric('Current Usage', '2.4 GB (60%)'),
          SizedBox(height: 1.h),
          _buildPolicyMetric('Eviction Count (24h)', '1,247 entries'),
          SizedBox(height: 1.h),
          _buildPolicyMetric('Avg Entry Age', '8.5 minutes'),
        ],
      ),
    );
  }

  Widget _buildPolicyMetric(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
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

  Widget _buildCacheWarming() {
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
                Icons.local_fire_department,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Cache Warming',
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
            'Preload frequently accessed data',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          _buildWarmingItem(
            'Popular Elections',
            'Top 100 trending elections',
            '1,247 entries',
            Colors.blue,
          ),
          SizedBox(height: 1.h),
          _buildWarmingItem(
            'User Recommendations',
            'Active users (last 24h)',
            '3,421 entries',
            Colors.green,
          ),
          SizedBox(height: 1.h),
          _buildWarmingItem(
            'AI Model Responses',
            'Common queries',
            '856 entries',
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Cache Warming'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF632CA6),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarmingItem(
    String title,
    String description,
    String entries,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            entries,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
