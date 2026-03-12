import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class RevenueProjectionWidget extends StatefulWidget {
  final Map<String, dynamic> historicalData;

  const RevenueProjectionWidget({super.key, required this.historicalData});

  @override
  State<RevenueProjectionWidget> createState() =>
      _RevenueProjectionWidgetState();
}

class _RevenueProjectionWidgetState extends State<RevenueProjectionWidget> {
  bool _isLoading = false;
  Map<String, dynamic> _projections = {};
  String _selectedPeriod = '30';

  @override
  void initState() {
    super.initState();
    _generateProjections();
  }

  Future<void> _generateProjections() async {
    setState(() => _isLoading = true);

    try {
      // Simulate OpenAI GPT-4 forecasting (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _projections = {
          '30': {
            'projected_vp': 15000,
            'confidence_low': 12000,
            'confidence_high': 18000,
            'confidence_level': 85,
          },
          '60': {
            'projected_vp': 32000,
            'confidence_low': 25000,
            'confidence_high': 39000,
            'confidence_level': 78,
          },
          '90': {
            'projected_vp': 50000,
            'confidence_low': 38000,
            'confidence_high': 62000,
            'confidence_level': 70,
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Revenue projection error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: theme.colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'AI Revenue Forecast',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.green, size: 12.sp),
                    SizedBox(width: 1.w),
                    Text(
                      'GPT-4',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildPeriodSelector(theme),
          SizedBox(height: 2.h),
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildProjectionCard(theme),
            SizedBox(height: 2.h),
            _buildConfidenceChart(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Row(
      children: [
        _buildPeriodChip('30 Days', '30', theme),
        SizedBox(width: 2.w),
        _buildPeriodChip('60 Days', '60', theme),
        SizedBox(width: 2.w),
        _buildPeriodChip('90 Days', '90', theme),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value, ThemeData theme) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectionCard(ThemeData theme) {
    final projection = _projections[_selectedPeriod] ?? {};
    final projectedVP = projection['projected_vp'] as int? ?? 0;
    final confidenceLow = projection['confidence_low'] as int? ?? 0;
    final confidenceHigh = projection['confidence_high'] as int? ?? 0;
    final confidenceLevel = projection['confidence_level'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withAlpha(204),
            theme.colorScheme.secondary.withAlpha(204),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Projected VP Earnings',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$projectedVP VP',
            style: GoogleFonts.inter(
              fontSize: 32.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Range: $confidenceLow - $confidenceHigh VP',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '$confidenceLevel% confidence',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChart(ThemeData theme) {
    final projection = _projections[_selectedPeriod] ?? {};
    final projectedVP = (projection['projected_vp'] as int? ?? 0).toDouble();
    final confidenceLow = (projection['confidence_low'] as int? ?? 0)
        .toDouble();
    final confidenceHigh = (projection['confidence_high'] as int? ?? 0)
        .toDouble();

    return SizedBox(
      height: 20.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: confidenceHigh * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return Text(
                        'Low',
                        style: GoogleFonts.inter(fontSize: 10.sp),
                      );
                    case 1:
                      return Text(
                        'Projected',
                        style: GoogleFonts.inter(fontSize: 10.sp),
                      );
                    case 2:
                      return Text(
                        'High',
                        style: GoogleFonts.inter(fontSize: 10.sp),
                      );
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: confidenceLow,
                  color: Colors.orange,
                  width: 20.w,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: projectedVP,
                  color: theme.colorScheme.primary,
                  width: 20.w,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: confidenceHigh,
                  color: Colors.green,
                  width: 20.w,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
