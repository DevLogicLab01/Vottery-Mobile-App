import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../theme/app_theme.dart';

class OptimizationRecommendationsWidget extends StatefulWidget {
  const OptimizationRecommendationsWidget({super.key});

  @override
  State<OptimizationRecommendationsWidget> createState() =>
      _OptimizationRecommendationsWidgetState();
}

class _OptimizationRecommendationsWidgetState
    extends State<OptimizationRecommendationsWidget> {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  String _selectedScreen = 'vote_casting';
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;

  final List<String> _screens = [
    'vote_casting',
    'vote_discovery',
    'create_vote',
    'vote_results',
    'user_profile',
    'social_media_home_feed',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    final recommendations = await _profilingService
        .getOptimizationRecommendations(
          screenName: _selectedScreen,
          status: 'pending',
        );

    setState(() {
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  Future<void> _markImplemented(String recommendationId) async {
    final success = await _profilingService.markRecommendationImplemented(
      recommendationId,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recommendation marked as implemented'),
          backgroundColor: Colors.green,
        ),
      );
      _loadRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenSelector(),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildScreenSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedScreen,
      decoration: InputDecoration(
        labelText: 'Select Screen',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        prefixIcon: Icon(Icons.screen_search_desktop, size: 5.w),
      ),
      items: _screens.map((screen) {
        return DropdownMenuItem(
          value: screen,
          child: Text(screen.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedScreen = value!);
        _loadRecommendations();
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No recommendations available',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            Text(
              'All optimizations have been implemented!',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return _buildRecommendationCard(recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] as String;
    final type = recommendation['recommendation_type'] as String;
    final estimatedImprovement =
        recommendation['estimated_improvement_percentage'] as num?;
    final complexity = recommendation['implementation_complexity'] as String;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  _getTypeIcon(type),
                  size: 5.w,
                  color: AppTheme.accentLight,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    _formatType(type),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              recommendation['recommendation_text'] ?? '',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                if (estimatedImprovement != null) ...[
                  Icon(Icons.trending_up, size: 4.w, color: Colors.green),
                  SizedBox(width: 1.w),
                  Text(
                    '${estimatedImprovement.toStringAsFixed(0)}% improvement',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
                Icon(Icons.build, size: 4.w, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  '${complexity.toUpperCase()} complexity',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () => _markImplemented(recommendation['id']),
              icon: Icon(Icons.check, size: 4.w),
              label: Text('Mark as Implemented'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'lazy_load':
        return Icons.hourglass_empty;
      case 'reduce_rebuilds':
        return Icons.refresh;
      case 'memoization':
        return Icons.memory;
      case 'optimize_network':
        return Icons.network_check;
      case 'image_optimization':
        return Icons.image;
      default:
        return Icons.code;
    }
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
