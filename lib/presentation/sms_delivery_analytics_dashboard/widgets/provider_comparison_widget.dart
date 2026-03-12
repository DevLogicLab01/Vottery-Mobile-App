import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ProviderComparisonWidget extends StatelessWidget {
  final Map<String, dynamic> providerComparison;

  const ProviderComparisonWidget({
    required this.providerComparison,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final telnyxMetrics = providerComparison['telnyx'] as Map<String, dynamic>? ?? {};
    final twilioMetrics = providerComparison['twilio'] as Map<String, dynamic>? ?? {};

    final telnyxRate = telnyxMetrics['delivery_rate'] ?? 0.0;
    final twilioRate = twilioMetrics['delivery_rate'] ?? 0.0;
    final betterProvider = telnyxRate >= twilioRate ? 'telnyx' : 'twilio';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Comparison',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        SizedBox(height: 2.h),
        _buildProviderCard(
          providerName: 'Telnyx',
          metrics: telnyxMetrics,
          isBetter: betterProvider == 'telnyx',
        ),
        SizedBox(height: 2.h),
        _buildProviderCard(
          providerName: 'Twilio',
          metrics: twilioMetrics,
          isBetter: betterProvider == 'twilio',
        ),
        SizedBox(height: 3.h),
        _buildComparisonTable(telnyxMetrics, twilioMetrics),
      ],
    );
  }

  Widget _buildProviderCard({
    required String providerName,
    required Map<String, dynamic> metrics,
    required bool isBetter,
  }) {
    final sent = metrics['sent'] ?? 0;
    final delivered = metrics['delivered'] ?? 0;
    final deliveryRate = metrics['delivery_rate'] ?? 0.0;
    final avgLatency = metrics['avg_latency_ms'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isBetter
            ? AppTheme.primaryColor.withAlpha(26)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isBetter ? AppTheme.primaryColor : Colors.grey.withAlpha(77),
          width: isBetter ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                providerName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
              if (isBetter) ...[
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Best',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Sent', sent.toString()),
              _buildMetricItem('Delivered', delivered.toString()),
              _buildMetricItem(
                'Rate',
                '${deliveryRate.toStringAsFixed(1)}%',
                color: _getDeliveryRateColor(deliveryRate),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildMetricItem(
            'Avg Latency',
            '${(avgLatency / 1000).toStringAsFixed(1)}s',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryDark,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color ?? AppTheme.textPrimaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(
    Map<String, dynamic> telnyx,
    Map<String, dynamic> twilio,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.withAlpha(51),
          borderRadius: BorderRadius.circular(12.0),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(26),
            ),
            children: [
              _buildTableHeader('Metric'),
              _buildTableHeader('Telnyx'),
              _buildTableHeader('Twilio'),
            ],
          ),
          _buildTableRow('Sent', telnyx['sent'], twilio['sent']),
          _buildTableRow('Delivered', telnyx['delivered'], twilio['delivered']),
          _buildTableRow('Failed', telnyx['failed'], twilio['failed']),
          _buildTableRow('Bounced', telnyx['bounced'], twilio['bounced']),
          _buildTableRow(
            'Delivery Rate',
            '${(telnyx['delivery_rate'] ?? 0.0).toStringAsFixed(1)}%',
            '${(twilio['delivery_rate'] ?? 0.0).toStringAsFixed(1)}%',
          ),
          _buildTableRow(
            'Avg Latency',
            '${((telnyx['avg_latency_ms'] ?? 0) / 1000).toStringAsFixed(1)}s',
            '${((twilio['avg_latency_ms'] ?? 0) / 1000).toStringAsFixed(1)}s',
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(2.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(String label, dynamic telnyxValue, dynamic twilioValue) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(2.w),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(2.w),
          child: Text(
            telnyxValue?.toString() ?? '0',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(2.w),
          child: Text(
            twilioValue?.toString() ?? '0',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getDeliveryRateColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 90) return Colors.yellow;
    return Colors.red;
  }
}