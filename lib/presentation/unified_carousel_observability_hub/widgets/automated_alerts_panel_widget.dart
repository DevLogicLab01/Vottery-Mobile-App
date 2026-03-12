import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/telnyx_critical_alerts_service.dart';
import '../../../theme/app_theme.dart';

class AutomatedAlertsPanelWidget extends StatefulWidget {
  const AutomatedAlertsPanelWidget({super.key});

  @override
  State<AutomatedAlertsPanelWidget> createState() =>
      _AutomatedAlertsPanelWidgetState();
}

class _AutomatedAlertsPanelWidgetState
    extends State<AutomatedAlertsPanelWidget> {
  final _supabase = Supabase.instance.client;
  final TelnyxCriticalAlertsService _telnyxService =
      TelnyxCriticalAlertsService.instance;

  double _latencyThreshold = 1000.0;
  double _costThreshold = 10.0;
  double _accuracyThreshold = 60.0;

  List<Map<String, dynamic>> _activeAlerts = [];
  bool _isLoading = true;
  final Set<String> _acknowledgedAlerts = {};

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _supabase
          .from('carousel_observability_alerts')
          .select()
          .eq('resolved', false)
          .order('created_at', ascending: false)
          .limit(20);
      setState(() {
        _activeAlerts = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _activeAlerts = _getMockAlerts();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getMockAlerts() {
    return [
      {
        'id': '1',
        'alert_type': 'high_latency',
        'affected_carousel': 'Kinetic Spindle',
        'severity': 'high',
        'threshold_breached': 'P99 latency: 1850ms > 1000ms threshold',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
      },
      {
        'id': '2',
        'alert_type': 'accuracy_drop',
        'affected_carousel': 'Isometric Deck',
        'severity': 'medium',
        'threshold_breached': 'Accuracy: 58% < 60% threshold',
        'created_at': DateTime.now()
            .subtract(const Duration(minutes: 23))
            .toIso8601String(),
      },
      {
        'id': '3',
        'alert_type': 'cost_spike',
        'affected_carousel': 'All Carousels',
        'severity': 'critical',
        'threshold_breached': 'Daily cost: \$12.40 > \$10.00 threshold',
        'created_at': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      },
    ];
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    setState(() => _acknowledgedAlerts.add(alertId));
    try {
      await _supabase
          .from('carousel_observability_alerts')
          .update({
            'acknowledged': true,
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId);
    } catch (e) {
      debugPrint('Acknowledge alert error: \$e');
    }
  }

  Future<void> _escalateAlert(Map<String, dynamic> alert) async {
    try {
      final alertType = alert['alert_type'] as String? ?? 'unknown';
      final carousel = alert['affected_carousel'] as String? ?? 'Unknown';
      final details = alert['threshold_breached'] as String? ?? '';

      await _telnyxService.sendServiceDisruptionAlert(
        serviceName: carousel,
        fallbackService: 'Manual Review Required',
        errorDetails: '$alertType - $details',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert escalated via Telnyx SMS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Escalate alert error: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Threshold Configuration',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          _buildThresholdSlider(
            'Latency Threshold',
            _latencyThreshold,
            100,
            3000,
            'ms',
            Colors.orange,
            (v) => setState(() => _latencyThreshold = v),
          ),
          _buildThresholdSlider(
            'Daily Cost Threshold',
            _costThreshold,
            1,
            100,
            '\$',
            Colors.red,
            (v) => setState(() => _costThreshold = v),
          ),
          _buildThresholdSlider(
            'Accuracy Threshold',
            _accuracyThreshold,
            10,
            100,
            '%',
            Colors.blue,
            (v) => setState(() => _accuracyThreshold = v),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Alerts (${_activeAlerts.length})',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAlerts,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activeAlerts.isEmpty
              ? Center(
                  child: Text(
                    'No active alerts',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.green,
                    ),
                  ),
                )
              : Column(
                  children: _activeAlerts
                      .map((alert) => _buildAlertCard(alert))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(
    String label,
    double value,
    double min,
    double max,
    String unit,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                unit == '\$'
                    ? '$unit${value.toStringAsFixed(0)}'
                    : '${value.toStringAsFixed(0)}$unit',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final alertId = alert['id'] as String? ?? '';
    final alertType = alert['alert_type'] as String? ?? 'unknown';
    final carousel = alert['affected_carousel'] as String? ?? 'Unknown';
    final severity = alert['severity'] as String? ?? 'medium';
    final threshold = alert['threshold_breached'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(alert['created_at'] ?? '') ?? DateTime.now();
    final isAcknowledged = _acknowledgedAlerts.contains(alertId);

    final severityColor = severity == 'critical'
        ? Colors.red
        : severity == 'high'
        ? Colors.orange
        : Colors.amber;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isAcknowledged
            ? Colors.grey.withAlpha(20)
            : severityColor.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isAcknowledged
              ? Colors.grey.withAlpha(40)
              : severityColor.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  alertType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatTime(createdAt),
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Carousel: $carousel',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Text(
            threshold,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          if (!isAcknowledged)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _acknowledgeAlert(alertId),
                    icon: Icon(Icons.check, size: 3.5.w),
                    label: Text(
                      'Acknowledge',
                      style: TextStyle(fontSize: 9.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.search, size: 3.5.w),
                    label: Text(
                      'Investigate',
                      style: TextStyle(fontSize: 9.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _escalateAlert(alert),
                    icon: Icon(Icons.escalator_warning, size: 3.5.w),
                    label: Text('Escalate', style: TextStyle(fontSize: 9.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              '✓ Acknowledged',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}