import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../theme/app_theme.dart';

class OptimizationEngineWidget extends StatefulWidget {
  final String screenName;
  final Function(String, String) onUpdateStatus;

  const OptimizationEngineWidget({
    super.key,
    required this.screenName,
    required this.onUpdateStatus,
  });

  @override
  State<OptimizationEngineWidget> createState() =>
      _OptimizationEngineWidgetState();
}

class _OptimizationEngineWidgetState extends State<OptimizationEngineWidget> {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(OptimizationEngineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.screenName != widget.screenName) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    final recommendations = await _profilingService
        .getOptimizationRecommendations(screenName: widget.screenName);

    setState(() {
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb, size: 20.w, color: Colors.grey.shade300),
            SizedBox(height: 2.h),
            Text(
              'No optimization recommendations',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = _recommendations[index];
        return _buildRecommendationCard(recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final recommendationType =
        recommendation['recommendation_type'] ?? 'general';
    final priorityScore = recommendation['priority_score'] ?? 50;
    final status = recommendation['implementation_status'] ?? 'pending';
    final playbook = List<String>.from(
      recommendation['actionable_playbook'] ?? [],
    );
    final estimatedImprovement =
        recommendation['estimated_improvement_percentage'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPriorityBadge(priorityScore),
                const Spacer(),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  _getRecommendationIcon(recommendationType),
                  size: 6.w,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _getRecommendationTitle(recommendationType),
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 4.w, color: Colors.green),
                  SizedBox(width: 2.w),
                  Text(
                    'Est. Improvement: ${estimatedImprovement.toStringAsFixed(0)}%',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Actionable Playbook:',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ...playbook.map(
              (step) => Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 4.w,
                      color: AppTheme.accentLight,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        step,
                        style: google_fonts.GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.onUpdateStatus(
                        recommendation['id'],
                        'in_progress',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start Implementation'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => widget.onUpdateStatus(
                        recommendation['id'],
                        'dismissed',
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                ],
              ),
            if (status == 'in_progress')
              ElevatedButton(
                onPressed: () =>
                    widget.onUpdateStatus(recommendation['id'], 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 5.h),
                ),
                child: const Text('Mark as Completed'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(int priority) {
    Color color;
    String label;

    if (priority >= 80) {
      color = Colors.red;
      label = 'HIGH PRIORITY';
    } else if (priority >= 60) {
      color = Colors.orange;
      label = 'MEDIUM PRIORITY';
    } else {
      color = Colors.blue;
      label = 'LOW PRIORITY';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            label,
            style: google_fonts.GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.grey;
        icon = Icons.schedule;
        break;
      case 'in_progress':
        color = Colors.blue;
        icon = Icons.hourglass_empty;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'dismissed':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 3.w, color: color),
          SizedBox(width: 1.w),
          Text(
            status.toUpperCase(),
            style: google_fonts.GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRecommendationIcon(String type) {
    switch (type) {
      case 'lazy_load':
        return Icons.view_list;
      case 'reduce_rebuilds':
        return Icons.refresh;
      case 'memoization':
        return Icons.memory;
      case 'optimize_network':
        return Icons.network_check;
      case 'image_compression':
        return Icons.image;
      case 'code_splitting':
        return Icons.code;
      default:
        return Icons.lightbulb;
    }
  }

  String _getRecommendationTitle(String type) {
    switch (type) {
      case 'lazy_load':
        return 'Implement Lazy Loading';
      case 'reduce_rebuilds':
        return 'Reduce Widget Rebuilds';
      case 'memoization':
        return 'Add Memoization';
      case 'optimize_network':
        return 'Optimize Network Calls';
      case 'image_compression':
        return 'Compress Images';
      case 'code_splitting':
        return 'Implement Code Splitting';
      default:
        return 'General Optimization';
    }
  }
}
