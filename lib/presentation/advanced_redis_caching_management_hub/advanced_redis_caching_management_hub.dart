import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import './widgets/ai_service_cache_widget.dart';
import './widgets/cache_analytics_widget.dart';
import './widgets/cache_management_widget.dart';
import './widgets/cache_status_overview_widget.dart';
import './widgets/market_research_cache_widget.dart';
import './widgets/recommendation_engine_cache_widget.dart';

class AdvancedRedisCachingManagementHub extends StatefulWidget {
  const AdvancedRedisCachingManagementHub({super.key});

  @override
  State<AdvancedRedisCachingManagementHub> createState() =>
      _AdvancedRedisCachingManagementHubState();
}

class _AdvancedRedisCachingManagementHubState
    extends State<AdvancedRedisCachingManagementHub> {
  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Overview', 'icon': Icons.dashboard},
    {'title': 'AI Cache', 'icon': Icons.psychology},
    {'title': 'Recommendations', 'icon': Icons.recommend},
    {'title': 'Market Research', 'icon': Icons.analytics},
    {'title': 'Management', 'icon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF632CA6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Redis Caching Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Distributed caching for AI services',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              _showClearCacheDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const CacheStatusOverviewWidget(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.h),
      height: 6.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF632CA6) : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF632CA6)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabs[index]['icon'],
                    color: isSelected ? Colors.white : Colors.grey[700],
                    size: 16.sp,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _tabs[index]['title'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 13.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: CacheAnalyticsWidget(),
        );
      case 1:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: AiServiceCacheWidget(),
        );
      case 2:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: RecommendationEngineCacheWidget(),
        );
      case 3:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: MarketResearchCacheWidget(),
        );
      case 4:
        return const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: CacheManagementWidget(),
        );
      default:
        return const SizedBox();
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear all cache? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
