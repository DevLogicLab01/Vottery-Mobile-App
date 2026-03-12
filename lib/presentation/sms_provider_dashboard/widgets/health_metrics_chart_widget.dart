import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/supabase_service.dart';

class HealthMetricsChartWidget extends StatefulWidget {
  const HealthMetricsChartWidget({super.key});

  @override
  State<HealthMetricsChartWidget> createState() =>
      _HealthMetricsChartWidgetState();
}

class _HealthMetricsChartWidgetState extends State<HealthMetricsChartWidget> {
  final _supabase = SupabaseService.instance.client;
  List<Map<String, dynamic>> _telnyxMetrics = [];
  List<Map<String, dynamic>> _twilioMetrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    try {
      final telnyxData = await _supabase
          .from('provider_health_metrics')
          .select()
          .eq('provider_name', 'telnyx')
          .gte(
            'checked_at',
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          )
          .order('checked_at', ascending: true)
          .limit(20);

      final twilioData = await _supabase
          .from('provider_health_metrics')
          .select()
          .eq('provider_name', 'twilio')
          .gte(
            'checked_at',
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          )
          .order('checked_at', ascending: true)
          .limit(20);

      if (mounted) {
        setState(() {
          _telnyxMetrics = List<Map<String, dynamic>>.from(telnyxData);
          _twilioMetrics = List<Map<String, dynamic>>.from(twilioData);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latency Trends (Last Hour)',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1000,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}ms',
                              style: TextStyle(fontSize: 9.sp),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      _buildLineData(_telnyxMetrics, Colors.blue, 'Telnyx'),
                      _buildLineData(_twilioMetrics, Colors.orange, 'Twilio'),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Telnyx', Colors.blue),
                SizedBox(width: 4.w),
                _buildLegendItem('Twilio', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLineData(
    List<Map<String, dynamic>> metrics,
    Color color,
    String label,
  ) {
    final spots = metrics.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final latency = (entry.value['latency_ms'] ?? 0).toDouble();
      return FlSpot(index, latency);
    }).toList();

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withAlpha(26)),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
