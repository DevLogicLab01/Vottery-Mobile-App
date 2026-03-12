import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class NetworkHealthWidget extends StatelessWidget {
  final Map<String, dynamic> networkMetrics;
  final String networkHealth;
  final bool isOnline;
  final Future<void> Function() onRefresh;

  const NetworkHealthWidget({
    super.key,
    required this.networkMetrics,
    required this.networkHealth,
    required this.isOnline,
    required this.onRefresh,
  });

  Color _getHealthColor() {
    switch (networkHealth) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'poor':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latency = networkMetrics['latency'] ?? 0;
    final bandwidth = networkMetrics['bandwidth'] ?? 'unknown';
    final connectionQuality = networkMetrics['connectionQuality'] ?? 'unknown';
    final activeSubscriptions = networkMetrics['activeSubscriptions'] ?? 0;
    final webSocketStatus = networkMetrics['webSocketStatus'] ?? 'disconnected';
    final dataFlowRate = networkMetrics['dataFlowRate'] ?? 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          _buildOverallHealthCard(),
          SizedBox(height: 2.h),
          _buildMetricsGrid(
            latency: latency,
            bandwidth: bandwidth,
            connectionQuality: connectionQuality,
            dataFlowRate: dataFlowRate,
          ),
          SizedBox(height: 2.h),
          _buildConnectionStatusCard(
            activeSubscriptions: activeSubscriptions,
            webSocketStatus: webSocketStatus,
          ),
          SizedBox(height: 2.h),
          _buildLatencyChart(latency),
        ],
      ),
    );
  }

  Widget _buildOverallHealthCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getHealthColor(), _getHealthColor().withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: _getHealthColor().withAlpha(77),
            blurRadius: 15.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
            size: 40.sp,
          ),
          SizedBox(height: 1.h),
          Text(
            networkHealth.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            isOnline ? 'Network Connected' : 'Network Offline',
            style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({
    required int latency,
    required String bandwidth,
    required String connectionQuality,
    required int dataFlowRate,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 2.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          icon: Icons.speed,
          label: 'Latency',
          value: '${latency}ms',
          color: latency < 50
              ? Colors.green
              : latency < 100
              ? Colors.orange
              : Colors.red,
        ),
        _buildMetricCard(
          icon: Icons.network_check,
          label: 'Bandwidth',
          value: bandwidth.toUpperCase(),
          color: Colors.blue,
        ),
        _buildMetricCard(
          icon: Icons.signal_cellular_alt,
          label: 'Connection Quality',
          value: connectionQuality.toUpperCase(),
          color: Colors.purple,
        ),
        _buildMetricCard(
          icon: Icons.trending_up,
          label: 'Data Flow',
          value: '${dataFlowRate}KB/s',
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusCard({
    required int activeSubscriptions,
    required String webSocketStatus,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Real-Time Connections',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildConnectionItem(
                  icon: Icons.subscriptions,
                  label: 'Active Supabase Subscriptions',
                  value: activeSubscriptions.toString(),
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildConnectionItem(
                  icon: Icons.cable,
                  label: 'WebSocket Status',
                  value: webSocketStatus.toUpperCase(),
                  color: webSocketStatus == 'connected'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyChart(int latency) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latency Performance',
            style: GoogleFonts.inter(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Latency',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${latency}ms',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: latency < 50
                            ? Colors.green
                            : latency < 100
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLatencyIndicator('Excellent', latency < 50),
                  _buildLatencyIndicator(
                    'Good',
                    latency >= 50 && latency < 100,
                  ),
                  _buildLatencyIndicator('Poor', latency >= 100),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: (latency / 200).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              latency < 50
                  ? Colors.green
                  : latency < 100
                  ? Colors.orange
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyIndicator(String label, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.grey.shade300,
            ),
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: isActive ? AppTheme.textPrimaryLight : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
