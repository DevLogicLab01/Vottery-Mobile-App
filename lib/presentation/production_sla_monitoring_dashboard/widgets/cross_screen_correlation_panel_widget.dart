import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/datadog_sla_correlation_service.dart';
import '../../../theme/app_theme.dart';

class CrossScreenCorrelationPanelWidget extends StatefulWidget {
  const CrossScreenCorrelationPanelWidget({super.key});

  @override
  State<CrossScreenCorrelationPanelWidget> createState() =>
      _CrossScreenCorrelationPanelWidgetState();
}

class _CrossScreenCorrelationPanelWidgetState
    extends State<CrossScreenCorrelationPanelWidget> {
  final DatadogSLACorrelationService _correlationService =
      DatadogSLACorrelationService.instance;

  Map<String, dynamic> _correlationData = {};
  bool _isLoading = true;
  String? _selectedScreen;
  Map<String, dynamic> _screenDetails = {};

  @override
  void initState() {
    super.initState();
    _loadCorrelations();
  }

  Future<void> _loadCorrelations() async {
    setState(() => _isLoading = true);
    final data = await _correlationService.analyzeCorrelations();
    setState(() {
      _correlationData = data;
      _isLoading = false;
    });
  }

  Future<void> _drillDown(String screenName) async {
    setState(() => _selectedScreen = screenName);
    final details = await _correlationService.getScreenViolationDetails(
      screenName,
    );
    setState(() => _screenDetails = details);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cross-Screen SLA Correlation',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadCorrelations,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                _buildSummaryRow(),
                SizedBox(height: 2.h),
                _buildTopViolatingScreensTable(),
                SizedBox(height: 2.h),
                _buildCorrelationMatrix(),
                if (_selectedScreen != null) ...[
                  SizedBox(height: 2.h),
                  _buildDrillDownPanel(),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final totalViolations = _correlationData['total_violations'] ?? 0;
    final screensAnalyzed = _correlationData['screens_analyzed'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Violations',
            totalViolations.toString(),
            Colors.red,
            Icons.warning_amber,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildSummaryCard(
            'Screens Analyzed',
            screensAnalyzed.toString(),
            Colors.blue,
            Icons.monitor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 5.w),
          SizedBox(width: 2.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopViolatingScreensTable() {
    final screens =
        (_correlationData['top_violating_screens'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Violating Screens',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withAlpha(40)),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                color: Colors.grey.withAlpha(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Screen',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Violations',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Avg Latency',
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
              ),
              ...screens.map((screen) => _buildScreenRow(screen)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScreenRow(Map<String, dynamic> screen) {
    final name = screen['screen_name'] as String? ?? 'unknown';
    final count = screen['violation_count'] ?? 0;
    final latency = (screen['avg_latency'] ?? 0.0).toDouble();
    final rootCause = screen['root_cause'] as String? ?? 'Unknown';
    final isSelected = _selectedScreen == name;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      color: isSelected ? AppTheme.primaryLight.withAlpha(20) : null,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  rootCause,
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              count.toString(),
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${latency.toStringAsFixed(0)}ms',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: latency > 2000
                    ? Colors.red
                    : latency > 1000
                    ? Colors.orange
                    : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 8.w,
            child: IconButton(
              icon: Icon(Icons.open_in_new, size: 3.5.w),
              onPressed: () => _drillDown(name),
              padding: EdgeInsets.zero,
              tooltip: 'Drill down',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationMatrix() {
    final matrix =
        (_correlationData['correlation_matrix'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correlation Matrix',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        if (matrix.isEmpty)
          Text(
            'No correlations detected',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.green),
          )
        else
          ...matrix.map((corr) => _buildCorrelationRow(corr)),
      ],
    );
  }

  Widget _buildCorrelationRow(Map<String, dynamic> corr) {
    final screenA = (corr['screen_a'] as String? ?? 'unknown').replaceAll(
      '_',
      ' ',
    );
    final screenB = (corr['screen_b'] as String? ?? 'unknown').replaceAll(
      '_',
      ' ',
    );
    final score = (corr['correlation_score'] ?? 0.0).toDouble();
    final rootCause = corr['common_root_cause'] as String? ?? 'Unknown';

    final color = score >= 0.8
        ? Colors.red
        : score >= 0.6
        ? Colors.orange
        : Colors.amber;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$screenA ↔ $screenB',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  rootCause,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '${(score * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrillDownPanel() {
    final screen = _selectedScreen ?? '';
    final violationCount = _screenDetails['violation_count'] ?? 0;
    final totalLoads = _screenDetails['total_loads'] ?? 0;
    final avgLatency = (_screenDetails['avg_latency'] ?? 0.0).toDouble();
    final p95Latency = (_screenDetails['p95_latency'] ?? 0.0).toDouble();

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(10),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Drill-down: ${screen.replaceAll('_', ' ')}',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedScreen = null),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildDetailStat(
                  'Violations',
                  violationCount.toString(),
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildDetailStat(
                  'Total Loads',
                  totalLoads.toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildDetailStat(
                  'Avg Latency',
                  '${avgLatency.toStringAsFixed(0)}ms',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildDetailStat(
                  'P95 Latency',
                  '${p95Latency.toStringAsFixed(0)}ms',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: AppTheme.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
