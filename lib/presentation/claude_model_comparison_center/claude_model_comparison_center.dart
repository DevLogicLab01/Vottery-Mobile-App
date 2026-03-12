import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/claude_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class ClaudeModelComparisonCenter extends StatefulWidget {
  const ClaudeModelComparisonCenter({super.key});

  @override
  State<ClaudeModelComparisonCenter> createState() =>
      _ClaudeModelComparisonCenterState();
}

class _ClaudeModelComparisonCenterState
    extends State<ClaudeModelComparisonCenter> {
  final ClaudeService _claude = ClaudeService.instance;
  final AuthService _auth = AuthService.instance;
  final _client = SupabaseService.instance.client;

  bool _isLoading = false;
  Map<String, dynamic>? _comparisonData;
  String _selectedTask = 'fraud_detection';
  String _timeRange = '7d';

  final List<String> _taskTypes = [
    'fraud_detection',
    'revenue_forecasting',
    'churn_prediction',
    'content_moderation',
    'sentiment_analysis',
  ];

  final List<String> _timeRanges = ['24h', '7d', '30d', '90d'];

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  Future<void> _loadComparisonData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await _client.rpc(
        'get_claude_model_comparison_data',
        params: {'task_type': _selectedTask, 'time_range': _timeRange},
      );

      if (mounted) {
        setState(() {
          _comparisonData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load comparison data error: $e');
      if (mounted) {
        setState(() {
          _comparisonData = _getMockData();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getMockData() {
    return {
      'sonnet_accuracy': 94.5,
      'opus_accuracy': 96.2,
      'sonnet_avg_cost': 0.0015,
      'opus_avg_cost': 0.0075,
      'recommended_model': 'sonnet',
      'recommendation_reason':
          'Best balance of accuracy and cost for this task type',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude Model Comparison Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComparisonData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(),
                  SizedBox(height: 2.h),
                  _buildOverviewCards(),
                  SizedBox(height: 2.h),
                  _buildPerformanceMetrics(),
                  SizedBox(height: 2.h),
                  _buildCostAnalysis(),
                ],
              ),
            ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Task Type', style: TextStyle(fontSize: 11.sp)),
                      SizedBox(height: 0.5.h),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTask,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _taskTypes.map((task) {
                          return DropdownMenuItem(
                            value: task,
                            child: Text(
                              _formatTaskName(task),
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTask = value);
                            _loadComparisonData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time Range', style: TextStyle(fontSize: 11.sp)),
                      SizedBox(height: 0.5.h),
                      DropdownButtonFormField<String>(
                        initialValue: _timeRange,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _timeRanges.map((range) {
                          return DropdownMenuItem(
                            value: range,
                            child: Text(
                              _formatTimeRange(range),
                              style: TextStyle(fontSize: 11.sp),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _timeRange = value);
                            _loadComparisonData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (_comparisonData == null) return const SizedBox();

    final sonnetAccuracy = (_comparisonData!['sonnet_accuracy'] ?? 0.0)
        .toDouble();
    final opusAccuracy = (_comparisonData!['opus_accuracy'] ?? 0.0).toDouble();
    final sonnetCost = (_comparisonData!['sonnet_avg_cost'] ?? 0.0).toDouble();
    final opusCost = (_comparisonData!['opus_avg_cost'] ?? 0.0).toDouble();
    final recommendedModel = _comparisonData!['recommended_model'] ?? 'sonnet';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModelCard(
                'Claude 3.5 Sonnet',
                sonnetAccuracy,
                sonnetCost,
                recommendedModel == 'sonnet',
                Colors.blue,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildModelCard(
                'Claude 3 Opus',
                opusAccuracy,
                opusCost,
                recommendedModel == 'opus',
                Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildRecommendationBanner(recommendedModel),
      ],
    );
  }

  Widget _buildModelCard(
    String name,
    double accuracy,
    double cost,
    bool isRecommended,
    Color color,
  ) {
    return Card(
      elevation: isRecommended ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isRecommended ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            if (isRecommended)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 1.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.5.h),
            Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              'Accuracy',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            Text(
              '\$${cost.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            Text(
              'Avg Cost/Request',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationBanner(String recommendedModel) {
    final modelName = recommendedModel == 'sonnet'
        ? 'Claude 3.5 Sonnet'
        : 'Claude 3 Opus';
    final reason =
        _comparisonData!['recommendation_reason'] ??
        'Best balance of accuracy and cost';

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended: $modelName',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildMetricRow('Fraud Detection Accuracy', 94.5, 96.2),
            _buildMetricRow('Revenue Forecasting Precision', 92.8, 94.1),
            _buildMetricRow('Churn Prediction Effectiveness', 91.3, 93.7),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double sonnet, double opus) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.sp)),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: sonnet / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.blue),
                      minHeight: 2.h,
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      'Sonnet: ${sonnet.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: opus / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.purple),
                      minHeight: 2.h,
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      'Opus: ${opus.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostAnalysis() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cost Analysis',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildCostCard(
                    'Sonnet',
                    0.0015,
                    Colors.blue,
                    '5x cheaper',
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildCostCard(
                    'Opus',
                    0.0075,
                    Colors.purple,
                    'Higher accuracy',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(String model, double cost, Color color, String note) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            model,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '\$${cost.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          Text('per request', style: TextStyle(fontSize: 9.sp)),
          SizedBox(height: 0.5.h),
          Text(
            note,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _formatTaskName(String task) {
    return task
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimeRange(String range) {
    switch (range) {
      case '24h':
        return 'Last 24 Hours';
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 90 Days';
      default:
        return range;
    }
  }
}
