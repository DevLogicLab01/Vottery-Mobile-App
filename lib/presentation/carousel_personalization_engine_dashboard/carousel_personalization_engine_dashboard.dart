import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_personalization_service.dart';
import '../../services/supabase_service.dart';

/// Carousel Personalization Engine Dashboard
/// ML-powered customization management with user behavior analytics
class CarouselPersonalizationEngineDashboard extends StatefulWidget {
  const CarouselPersonalizationEngineDashboard({super.key});

  @override
  State<CarouselPersonalizationEngineDashboard> createState() =>
      _CarouselPersonalizationEngineDashboardState();
}

class _CarouselPersonalizationEngineDashboardState
    extends State<CarouselPersonalizationEngineDashboard>
    with SingleTickerProviderStateMixin {
  final CarouselPersonalizationService _personalizationService =
      CarouselPersonalizationService.instance;

  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _segments = [];
  Map<String, dynamic> _mlPerformance = {};
  Map<String, int> _deviceDistribution = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final segments = await _personalizationService.getSegmentDistribution();
      final mlPerformance = await _personalizationService
          .getMLModelPerformance();
      final deviceDistribution = segments;

      setState(() {
        _segments = segments.entries
            .map((e) => {
                  'segment_name': e.key,
                  'user_count': e.value,
                  'avg_score': 75.0,
                })
            .toList();
        _mlPerformance = mlPerformance;
        _deviceDistribution = deviceDistribution;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carousel Personalization Engine',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'User Segments'),
            Tab(text: 'ML Performance'),
            Tab(text: 'Device Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSegmentsTab(),
                _buildMLPerformanceTab(),
                _buildDeviceAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final totalUsers = _segments.fold<int>(
      0,
      (sum, segment) => sum + (segment['user_count'] as int),
    );
    final avgAccuracy = _mlPerformance['accuracy'] ?? 0.0;
    final totalPredictions = _mlPerformance['total_predictions'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          // Status Overview
          Text(
            'Personalization Status',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Segments',
                  _segments.length.toString(),
                  Icons.group,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Total Users',
                  totalUsers.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'ML Accuracy',
                  '${avgAccuracy.toStringAsFixed(1)}%',
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Predictions',
                  totalPredictions.toString(),
                  Icons.analytics,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _detectDeviceCapabilities,
            icon: const Icon(Icons.devices),
            label: const Text('Detect Device Capabilities'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
          ),
          SizedBox(height: 1.h),
          ElevatedButton.icon(
            onPressed: _runMLPrediction,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Run ML Prediction'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Text(
            'User Segments',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          if (_segments.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.h),
                child: Text(
                  'No segments available',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
            )
          else
            ..._segments.map((segment) => _buildSegmentCard(segment)),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(Map<String, dynamic> segment) {
    final name = segment['segment_name'] as String;
    final userCount = segment['user_count'] as int;
    final avgScore = (segment['avg_score'] as num).toDouble();

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatSegmentName(name),
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getSegmentColor(name).withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '$userCount users',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _getSegmentColor(name),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.score, size: 16.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  'Avg Score: ${avgScore.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: avgScore / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getSegmentColor(name)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLPerformanceTab() {
    final accuracy = _mlPerformance['accuracy'] ?? 0.0;
    final avgConfidence = _mlPerformance['avg_confidence'] ?? 0.0;
    final totalPredictions = _mlPerformance['total_predictions'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Text(
            'ML Model Performance',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),

          // Accuracy Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediction Accuracy',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Center(
                    child: SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: accuracy / 100,
                            strokeWidth: 12.0,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              accuracy > 70
                                  ? Colors.green
                                  : accuracy > 50
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                          Text(
                            '${accuracy.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Predictions',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            totalPredictions.toString(),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Avg Confidence',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            avgConfidence.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Text(
            'Device Tier Distribution',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          if (_deviceDistribution.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(5.h),
                child: Text(
                  'No device data available',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
            )
          else
            ..._deviceDistribution.entries.map(
              (entry) => Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ListTile(
                  leading: Icon(
                    Icons.phone_android,
                    color: _getDeviceTierColor(entry.key),
                  ),
                  title: Text(
                    _formatDeviceTier(entry.key),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    '${entry.value} devices',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSegmentName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getSegmentColor(String segmentName) {
    switch (segmentName) {
      case 'high_engagement':
        return Colors.green;
      case 'content_creators':
        return Colors.purple;
      case 'price_sensitive':
        return Colors.orange;
      case 'early_adopters':
        return Colors.blue;
      case 'power_users':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDeviceTier(String tier) {
    return tier
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getDeviceTierColor(String tier) {
    switch (tier) {
      case 'high_end':
        return Colors.green;
      case 'mid_range':
        return Colors.orange;
      case 'low_end':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _detectDeviceCapabilities() async {
    try {
      await _personalizationService.detectDeviceCapabilities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device capabilities detected successfully'),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _runMLPrediction() async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final prediction = await _personalizationService.predictCarouselType();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Predicted: $prediction',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}