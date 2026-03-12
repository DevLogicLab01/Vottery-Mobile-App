import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../core/app_export.dart';
import '../../services/perplexity_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Enhanced Perplexity 90-Day Threat Forecasting Hub
class EnhancedPerplexity90DayThreatForecastingHub extends StatefulWidget {
  const EnhancedPerplexity90DayThreatForecastingHub({super.key});

  @override
  State<EnhancedPerplexity90DayThreatForecastingHub> createState() =>
      _EnhancedPerplexity90DayThreatForecastingHubState();
}

class _EnhancedPerplexity90DayThreatForecastingHubState
    extends State<EnhancedPerplexity90DayThreatForecastingHub> {
  final PerplexityService _perplexityService = PerplexityService.instance;

  List<Map<String, dynamic>> _threatReports = [];
  List<Map<String, dynamic>> _crossZonePatterns = [];
  bool _isLoading = true;
  String _selectedPeriod = '90_days';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final reports = await _perplexityService.getThreatForecastingReports(
      limit: 10,
    );
    final patterns = await _perplexityService.getCrossZoneFraudPatterns(
      limit: 20,
    );

    setState(() {
      _threatReports = reports;
      _crossZonePatterns = patterns;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: '90-Day Threat Forecasting',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: '90-Day Threat Forecasting',
          variant: CustomAppBarVariant.withBack,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildForecastPeriodSelector(),
                      SizedBox(height: 2.h),
                      _buildLatestForecast(),
                      SizedBox(height: 2.h),
                      _buildCrossZonePatternsSection(),
                      SizedBox(height: 2.h),
                      _buildZoneVulnerabilitiesSection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildForecastPeriodSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Period',
              style: google_fonts.GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                _buildPeriodChip('30_days', '30 Days'),
                SizedBox(width: 2.w),
                _buildPeriodChip('60_days', '60 Days'),
                SizedBox(width: 2.w),
                _buildPeriodChip('90_days', '90 Days'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = period);
        }
      },
      selectedColor: AppTheme.accentLight,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildLatestForecast() {
    if (_threatReports.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Center(
            child: Text(
              'No threat forecasts available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final latestReport = _threatReports.first;
    final threatLevel = latestReport['threat_level'] ?? 'low';
    final confidence = latestReport['confidence_score'] ?? 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: _getThreatLevelColor(threatLevel),
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Threat Assessment',
                        style: google_fonts.GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Threat Level: ${threatLevel.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _getThreatLevelColor(threatLevel),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: confidence,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                _getThreatLevelColor(threatLevel),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            ),
            if (latestReport['emerging_threats'] != null)
              ..._buildEmergingThreats(latestReport['emerging_threats']),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmergingThreats(dynamic threats) {
    if (threats is! List || threats.isEmpty) return [];

    return [
      SizedBox(height: 2.h),
      Text(
        'Emerging Threats:',
        style: google_fonts.GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 1.h),
      ...threats.take(3).map((threat) {
        return Padding(
          padding: EdgeInsets.only(bottom: 1.h),
          child: Row(
            children: [
              Icon(Icons.arrow_right, size: 4.w),
              Expanded(
                child: Text(
                  threat['type']?.toString() ?? 'Unknown threat',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }

  Widget _buildCrossZonePatternsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cross-Zone Fraud Patterns',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        if (_crossZonePatterns.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Center(
                child: Text(
                  'No cross-zone patterns detected',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ..._crossZonePatterns.take(5).map((pattern) {
            return _buildPatternCard(pattern);
          }),
      ],
    );
  }

  Widget _buildPatternCard(Map<String, dynamic> pattern) {
    final riskAssessment = pattern['risk_assessment'] ?? 'low';
    final affectedZones = List<String>.from(pattern['affected_zones'] ?? []);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
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
                    color: _getRiskColor(riskAssessment).withAlpha(26),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    riskAssessment.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getRiskColor(riskAssessment),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    pattern['pattern_type'] ?? 'Unknown',
                    style: google_fonts.GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              pattern['pattern_description'] ?? '',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
            if (affectedZones.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Wrap(
                spacing: 1.w,
                runSpacing: 0.5.h,
                children: affectedZones
                    .map(
                      (zone) => Chip(
                        label: Text(zone, style: TextStyle(fontSize: 9.sp)),
                        backgroundColor: Colors.orange.shade50,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoneVulnerabilitiesSection() {
    if (_threatReports.isEmpty) return SizedBox.shrink();

    final latestReport = _threatReports.first;
    final vulnerabilities = latestReport['zone_vulnerabilities'];

    if (vulnerabilities == null || vulnerabilities is! Map) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Vulnerabilities',
          style: google_fonts.GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              children: vulnerabilities.entries.take(8).map((entry) {
                final zone = entry.key;
                final data = entry.value as Map<String, dynamic>?;
                final riskScore = data?['risk_score'] ?? 0;

                return Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(zone, style: TextStyle(fontSize: 11.sp)),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: riskScore / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _getRiskColorFromScore(riskScore),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '$riskScore',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getThreatLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  Color _getRiskColorFromScore(num score) {
    if (score >= 80) return Colors.red;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.yellow.shade700;
    return Colors.green;
  }
}
