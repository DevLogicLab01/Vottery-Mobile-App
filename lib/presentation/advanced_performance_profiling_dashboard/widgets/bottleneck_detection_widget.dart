import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/performance_profiling_service.dart';
import '../../../theme/app_theme.dart';

class BottleneckDetectionWidget extends StatefulWidget {
  const BottleneckDetectionWidget({super.key});

  @override
  State<BottleneckDetectionWidget> createState() =>
      _BottleneckDetectionWidgetState();
}

class _BottleneckDetectionWidgetState extends State<BottleneckDetectionWidget> {
  final PerformanceProfilingService _profilingService =
      PerformanceProfilingService.instance;

  List<Map<String, dynamic>> _bottlenecks = [];
  bool _isLoading = false;
  String _filterSeverity = 'all';
  bool _unresolvedOnly = true;

  @override
  void initState() {
    super.initState();
    _loadBottlenecks();
  }

  Future<void> _loadBottlenecks() async {
    setState(() => _isLoading = true);

    final bottlenecks = await _profilingService.getPerformanceBottlenecks(
      severity: _filterSeverity == 'all' ? null : _filterSeverity,
      unresolvedOnly: _unresolvedOnly,
    );

    setState(() {
      _bottlenecks = bottlenecks;
      _isLoading = false;
    });
  }

  Future<void> _resolveBottleneck(String bottleneckId) async {
    final success = await _profilingService.resolveBottleneck(
      bottleneckId: bottleneckId,
      resolutionNotes: 'Resolved from dashboard',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bottleneck resolved'),
          backgroundColor: Colors.green,
        ),
      );
      _loadBottlenecks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else if (_bottlenecks.isEmpty)
            _buildEmptyState()
          else
            _buildBottlenecksList(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _filterSeverity,
              decoration: InputDecoration(
                labelText: 'Filter by Severity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (value) {
                setState(() => _filterSeverity = value!);
                _loadBottlenecks();
              },
            ),
            SizedBox(height: 1.h),
            SwitchListTile(
              title: Text('Unresolved Only', style: TextStyle(fontSize: 11.sp)),
              value: _unresolvedOnly,
              onChanged: (value) {
                setState(() => _unresolvedOnly = value);
                _loadBottlenecks();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 15.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No bottlenecks detected',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your app is performing well!',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottlenecksList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bottlenecks.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final bottleneck = _bottlenecks[index];
        return _buildBottleneckCard(bottleneck);
      },
    );
  }

  Widget _buildBottleneckCard(Map<String, dynamic> bottleneck) {
    final severity = bottleneck['severity'] as String;
    final type = bottleneck['bottleneck_type'] as String;
    final isResolved = bottleneck['resolved_at'] != null;

    return Card(
      elevation: 2,
      color: isResolved ? Colors.grey.shade100 : Colors.white,
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
                    color: _getSeverityColor(severity),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                if (isResolved)
                  Icon(Icons.check_circle, color: Colors.green, size: 5.w),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              bottleneck['screen_name'] ?? 'Unknown Screen',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              bottleneck['threshold_exceeded'] ?? '',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Text(
                  'Actual: ${bottleneck['actual_value']}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Threshold: ${bottleneck['threshold_value']}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            if (!isResolved) ...[
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: () => _resolveBottleneck(bottleneck['id']),
                icon: Icon(Icons.check, size: 4.w),
                label: Text('Mark as Resolved'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'cpu':
        return Colors.purple;
      case 'memory':
        return Colors.teal;
      case 'network':
        return Colors.indigo;
      default:
        return Colors.cyan;
    }
  }
}
