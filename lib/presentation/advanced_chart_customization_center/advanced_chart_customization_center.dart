import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/chart_anomaly_analyzer.dart';
import '../../services/global_filter_provider.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/chart_type_selector_widget.dart';

class AdvancedChartCustomizationCenter extends StatefulWidget {
  final String? chartId;

  const AdvancedChartCustomizationCenter({super.key, this.chartId});

  @override
  State<AdvancedChartCustomizationCenter> createState() =>
      _AdvancedChartCustomizationCenterState();
}

class _AdvancedChartCustomizationCenterState
    extends State<AdvancedChartCustomizationCenter> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  bool _isLoading = true;
  bool _isAnalyzingAnomalies = false;
  String _chartId = 'revenue_chart';
  Map<String, dynamic> _chartPreferences = {
    'chart_type': 'line',
    'color_scheme': 'default',
    'axis_config': {
      'x_axis': {'label_rotation': 0, 'grid_lines': true},
      'y_axis': {'scale_type': 'linear', 'grid_lines': true},
    },
    'data_point_labels': false,
    'legend_config': {'position': 'top', 'font_size': 12},
  };
  List<Map<String, dynamic>> _anomalies = [];
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    if (widget.chartId != null) {
      _chartId = widget.chartId!;
    }
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadChartPreferences(),
        _loadAnomalies(),
        _loadMockChartData(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Load chart data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChartPreferences() async {
    try {
      if (!_auth.isAuthenticated) return;

      final response = await _client
          .from('user_chart_preferences')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('chart_id', _chartId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _chartPreferences = response['preferences'] as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Load chart preferences error: $e');
    }
  }

  Future<void> _loadAnomalies() async {
    try {
      final response = await _client
          .from('chart_anomalies')
          .select()
          .eq('chart_id', _chartId)
          .eq('investigated', false)
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        _anomalies = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Load anomalies error: $e');
    }
  }

  Future<void> _loadMockChartData() async {
    // Mock chart data for preview
    setState(() {
      _chartData = List.generate(7, (index) {
        return {
          'x': index.toDouble(),
          'y': (50 + (index * 10) + (index % 2 == 0 ? 15 : -10)).toDouble(),
          'label': 'Day ${index + 1}',
        };
      });
    });
  }

  Future<void> _saveChartPreferences() async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('user_chart_preferences').upsert({
        'user_id': _auth.currentUser!.id,
        'chart_id': _chartId,
        'preferences': _chartPreferences,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chart preferences saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save chart preferences error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeAnomalies() async {
    setState(() => _isAnalyzingAnomalies = true);

    try {
      final analyzer = ChartAnomalyAnalyzer.instance;

      final anomalies = await analyzer.highlightAnomalies(
        chartId: _chartId,
        chartData: _chartData,
        metricName: 'Revenue',
        businessDomain: 'Revenue Analytics',
      );

      await _loadAnomalies();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${anomalies.length} anomalies'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Analyze anomalies error: $e');
    } finally {
      setState(() => _isAnalyzingAnomalies = false);
    }
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      if (key.contains('.')) {
        final parts = key.split('.');
        if (parts.length == 2) {
          _chartPreferences[parts[0]][parts[1]] = value;
        } else if (parts.length == 3) {
          _chartPreferences[parts[0]][parts[1]][parts[2]] = value;
        }
      } else {
        _chartPreferences[key] = value;
      }
    });
  }

  void _showDrillDownModal(Map<String, dynamic> dataPoint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Drill-Down Analysis',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Data Point: ${dataPoint['label']}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataRow('X Value', dataPoint['x'].toString()),
                  _buildDataRow('Y Value', dataPoint['y'].toString()),
                  _buildDataRow('Category', dataPoint['label']),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Filtered Data',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Metric')),
                    DataColumn(label: Text('Value')),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        DataCell(Text('Total')),
                        DataCell(Text(dataPoint['y'].toString())),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text('Average')),
                        DataCell(Text((dataPoint['y'] / 7).toStringAsFixed(2))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilterToDashboard(dataPoint);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
                child: Text(
                  'Apply Filter to Dashboard',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _applyFilterToDashboard(Map<String, dynamic> dataPoint) {
    final filterProvider = GlobalFilterProvider.instance;
    filterProvider.applyFilter('category', dataPoint['label']);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Filter applied: ${dataPoint['label']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildAnomalyHighlights() {
    if (_anomalies.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI-Detected Anomalies',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20.sp),
                  onPressed: _analyzeAnomalies,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ..._anomalies.map((anomaly) => _buildAnomalyCard(anomaly)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(Map<String, dynamic> anomaly) {
    final confidence = (anomaly['confidence'] as num).toDouble();
    final confidenceColor = confidence > 0.8
        ? Colors.red
        : confidence > 0.6
        ? Colors.orange
        : Colors.yellow;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: confidenceColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: confidenceColor),
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
                  color: confidenceColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                anomaly['anomaly_type'].toString().toUpperCase(),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: confidenceColor,
                ),
              ),
              Spacer(),
              Text(
                '${(confidence * 100).toInt()}% confidence',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(anomaly['explanation'], style: TextStyle(fontSize: 11.sp)),
          if (anomaly['business_cause'] != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              'Possible cause: ${anomaly['business_cause']}',
              style: TextStyle(fontSize: 10.sp, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  void _showAnomalyInvestigation(Map<String, dynamic> anomaly) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anomaly Investigation',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Text('Type: ${anomaly['anomaly_type']}'),
            Text('Explanation: ${anomaly['explanation']}'),
            Text('Confidence: ${anomaly['confidence']}'),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () async {
                await _client
                    .from('chart_anomalies')
                    .update({
                      'investigated': true,
                      'investigated_at': DateTime.now().toIso8601String(),
                      'investigated_by': _auth.currentUser!.id,
                    })
                    .eq('id', anomaly['id']);

                await _loadAnomalies();
                Navigator.pop(context);
              },
              child: Text('Mark as Investigated'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AdvancedChartCustomizationCenter',
      onRetry: _loadChartData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Chart Customization',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'save',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _saveChartPreferences,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnomalyHighlights(),
                    SizedBox(height: 2.h),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Chart Preview',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isAnalyzingAnomalies
                                      ? null
                                      : _analyzeAnomalies,
                                  icon: _isAnalyzingAnomalies
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(Icons.auto_awesome, size: 16.sp),
                                  label: Text('AI Analyze'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryLight,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            SizedBox(
                              height: 30.h,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _chartData.length,
                                itemBuilder: (context, index) {
                                  final dataPoint = _chartData[index];
                                  return GestureDetector(
                                    onTap: () => _showDrillDownModal(dataPoint),
                                    child: Container(
                                      width: 10.w,
                                      margin: EdgeInsets.only(right: 2.w),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height:
                                                (dataPoint['y'] / 100 * 20).h,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryLight,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          SizedBox(height: 1.h),
                                          Text(
                                            dataPoint['label'],
                                            style: TextStyle(fontSize: 9.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    ChartTypeSelectorWidget(
                      selectedType: _chartPreferences['chart_type'],
                      onTypeChanged: (type) =>
                          _updatePreference('chart_type', type),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
