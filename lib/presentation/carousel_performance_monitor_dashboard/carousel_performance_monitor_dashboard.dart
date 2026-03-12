import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/carousel_performance_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Carousel Performance Monitor Dashboard Screen
/// Displays FPS tracking, battery impact, and quality management
class CarouselPerformanceMonitorDashboard extends StatefulWidget {
  const CarouselPerformanceMonitorDashboard({super.key});

  @override
  State<CarouselPerformanceMonitorDashboard> createState() =>
      _CarouselPerformanceMonitorDashboardState();
}

class _CarouselPerformanceMonitorDashboardState
    extends State<CarouselPerformanceMonitorDashboard> {
  final CarouselPerformanceService _performanceService =
      CarouselPerformanceService();
  final SupabaseService _supabaseService = SupabaseService.instance;

  double _currentFPS = 60.0;
  QualityLevel _currentQuality = QualityLevel.high;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePerformanceMonitoring();
  }

  Future<void> _initializePerformanceMonitoring() async {
    await _performanceService.initialize();

    _performanceService.onFPSUpdate = (fps) {
      if (mounted) {
        setState(() => _currentFPS = fps);
      }
    };

    _performanceService.onQualityChanged = (quality) {
      if (mounted) {
        setState(() => _currentQuality = quality);
        _showQualityChangeSnackBar(quality);
      }
    };

    setState(() => _isInitialized = true);
  }

  void _showQualityChangeSnackBar(QualityLevel quality) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Performance quality adjusted to ${quality.name.toUpperCase()}',
          style: TextStyle(color: AppTheme.textPrimaryLight),
        ),
        backgroundColor: AppTheme.surfaceDark,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _performanceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Performance Monitor',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerformanceOverview(),
                  SizedBox(height: 3.h),
                  _buildFPSMonitor(),
                  SizedBox(height: 3.h),
                  _buildQualityControls(),
                  SizedBox(height: 3.h),
                  _buildPerformanceTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeColors.electricGold.withAlpha(51),
            AppThemeColors.neonMint.withAlpha(51),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                color: AppThemeColors.electricGold,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current FPS',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _currentFPS.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: _getFPSColor(_currentFPS),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Quality Level',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getQualityColor(_currentQuality).withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: _getQualityColor(_currentQuality),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _currentQuality.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: _getQualityColor(_currentQuality),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFPSMonitor() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS Monitoring',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getFPSColor(_currentFPS),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _currentFPS.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: _getFPSColor(_currentFPS),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      _getFPSStatus(_currentFPS),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFPSIndicator('Excellent', 55, 60, Colors.green),
                    SizedBox(height: 1.h),
                    _buildFPSIndicator('Good', 45, 55, Colors.yellow),
                    SizedBox(height: 1.h),
                    _buildFPSIndicator('Poor', 0, 45, Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFPSIndicator(String label, double min, double max, Color color) {
    final isActive = _currentFPS >= min && _currentFPS < max;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : color.withAlpha(77),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          '$label ($min-${max.toInt()} FPS)',
          style: TextStyle(
            fontSize: 11.sp,
            color: isActive
                ? AppTheme.textPrimaryLight
                : AppTheme.textSecondaryLight,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quality Controls',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildQualityOption(
            QualityLevel.high,
            'High Quality',
            'All effects enabled, best visual experience',
            Icons.hd,
          ),
          SizedBox(height: 1.h),
          _buildQualityOption(
            QualityLevel.medium,
            'Medium Quality',
            'Balanced performance and visuals',
            Icons.high_quality,
          ),
          SizedBox(height: 1.h),
          _buildQualityOption(
            QualityLevel.low,
            'Low Quality',
            'Maximum performance, minimal effects',
            Icons.sd,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(
    QualityLevel level,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _currentQuality == level;
    return GestureDetector(
      onTap: () {
        _performanceService.setQuality(level);
        setState(() => _currentQuality = level);
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? _getQualityColor(level).withAlpha(51)
              : AppTheme.backgroundDark,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected
                ? _getQualityColor(level)
                : AppTheme.backgroundDark,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? _getQualityColor(level)
                  : AppTheme.textSecondaryLight,
              size: 24.sp,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.textPrimaryLight
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: _getQualityColor(level),
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTips() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppThemeColors.electricGold,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Performance Tips',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildTipItem('Lower quality settings improve battery life'),
          _buildTipItem('Close background apps for better performance'),
          _buildTipItem(
            'Performance auto-adjusts based on device capabilities',
          ),
          _buildTipItem('FPS below 45 triggers automatic quality reduction'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppThemeColors.neonMint,
            size: 16.sp,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getFPSColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.yellow;
    return Colors.red;
  }

  String _getFPSStatus(double fps) {
    if (fps >= 55) return 'Excellent';
    if (fps >= 45) return 'Good';
    return 'Poor';
  }

  Color _getQualityColor(QualityLevel quality) {
    switch (quality) {
      case QualityLevel.high:
        return Colors.green;
      case QualityLevel.medium:
        return Colors.yellow;
      case QualityLevel.low:
        return Colors.orange;
    }
  }
}
