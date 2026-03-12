import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // Add this import for JsonEncoder

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class IncidentResolutionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recentAnalyses;
  final Function(String) onResolve;

  const IncidentResolutionWidget({
    super.key,
    required this.recentAnalyses,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final incidents = recentAnalyses
        .where(
          (a) =>
              a['execution_status'] == 'manual_review_required' ||
              a['recommendation']?['action'] == 'investigate',
        )
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1-Click Incident Resolution',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '${incidents.length} incidents requiring attention',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (incidents.isEmpty)
            _buildEmptyState()
          else
            ...incidents.map(
              (incident) => _buildIncidentCard(context, incident),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 15.w),
          SizedBox(height: 2.h),
          Text(
            'No Incidents Detected',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'All AI analyses have been automatically resolved or are within normal parameters',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(
    BuildContext context,
    Map<String, dynamic> incident,
  ) {
    final analysisType = incident['analysis_type'] ?? 'Unknown';
    final recommendation = incident['recommendation'] ?? {};
    final action = recommendation['action'] ?? 'manual_review';
    final confidence =
        (recommendation['confidence'] as num?)?.toDouble() ?? 0.0;
    final reasoning = recommendation['reasoning'] ?? 'No reasoning provided';
    final timestamp = incident['created_at'] != null
        ? DateFormat(
            'MMM dd, HH:mm',
          ).format(DateTime.parse(incident['created_at']))
        : 'Unknown';
    final incidentId = incident['id'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
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
              Icon(Icons.warning, color: Colors.red, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysisType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getActionColor(action).withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  action.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: _getActionColor(action),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'AI Recommendation',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            reasoning,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: 4.w),
              SizedBox(width: 1.w),
              Text(
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onResolve(incidentId),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Resolve Incident'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showIncidentDetails(context, incident),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'investigate':
        return Colors.red;
      case 'flag':
        return Colors.orange;
      case 'monitor':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showIncidentDetails(
    BuildContext context,
    Map<String, dynamic> incident,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Incident Details',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(incident),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontFamily: 'monospace',
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
