import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveFraudPatternFeedWidget extends StatefulWidget {
  final List<Map<String, dynamic>> fraudAlerts;
  final List<Map<String, dynamic>> automatedResponses;
  final bool isLoading;

  const LiveFraudPatternFeedWidget({
    super.key,
    required this.fraudAlerts,
    required this.automatedResponses,
    this.isLoading = false,
  });

  @override
  State<LiveFraudPatternFeedWidget> createState() =>
      _LiveFraudPatternFeedWidgetState();
}

class _LiveFraudPatternFeedWidgetState
    extends State<LiveFraudPatternFeedWidget> {
  Timer? _pulseTimer;
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _isPulsing = !_isPulsing);
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 2.w,
                height: 2.w,
                decoration: BoxDecoration(
                  color: _isPulsing ? Colors.red : Colors.red[300],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 1.5.w),
              Text(
                'LIVE Fraud Pattern Feed',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Real-time fraud detection alerts',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 2.h),
          if (widget.fraudAlerts.isEmpty)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'No active fraud patterns detected',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            )
          else
            ...widget.fraudAlerts
                .take(8)
                .map(
                  (alert) => _PatternCard(
                    alert: alert,
                    getSeverityColor: _getSeverityColor,
                  ),
                ),
          SizedBox(height: 2.h),
          Text(
            'Pattern Correlation Network',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          _NetworkGraphWidget(alerts: widget.fraudAlerts),
          SizedBox(height: 2.h),
          Text(
            'Automated Responses',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          if (widget.automatedResponses.isEmpty)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'No automated responses triggered',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey[500],
                ),
              ),
            )
          else
            ...widget.automatedResponses
                .take(5)
                .map((response) => _AutomatedResponseCard(response: response)),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Color Function(String) getSeverityColor;
  const _PatternCard({required this.alert, required this.getSeverityColor});

  @override
  Widget build(BuildContext context) {
    final severity = alert['alert_severity'] as String? ?? 'low';
    final color = getSeverityColor(severity);
    final confidence = (alert['confidence_score'] as num?)?.toDouble() ?? 0.0;
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  alert['pattern_type'] as String? ?? 'Unknown Pattern',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(confidence * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(Icons.people, size: 12.sp, color: Colors.grey[400]),
              SizedBox(width: 1.w),
              Text(
                '${alert['affected_users'] ?? 0} users affected',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.access_time, size: 12.sp, color: Colors.grey[400]),
              SizedBox(width: 1.w),
              Text(
                alert['detection_timestamp'] as String? ?? 'Just now',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkGraphWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  const _NetworkGraphWidget({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 15.h,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: alerts.isEmpty
          ? Center(
              child: Text(
                'No patterns to visualize',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[400],
                ),
              ),
            )
          : CustomPaint(
              painter: _NetworkPainter(nodeCount: alerts.length.clamp(0, 8)),
              child: Container(),
            ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final int nodeCount;
  _NetworkPainter({required this.nodeCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount == 0) return;
    final paint = Paint()
      ..color = Colors.blue.withAlpha(153)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    final nodes = List.generate(nodeCount, (i) {
      final angle = (i / nodeCount) * 2 * 3.14159;
      return Offset(
        size.width / 2 +
            size.width * 0.3 * (0.6 + 0.4 * (i % 2)) * (angle < 3.14 ? 1 : -1),
        size.height / 2 +
            size.height *
                0.3 *
                (0.5 + 0.5 * (i % 3 == 0 ? 1 : 0.6)) *
                (angle < 1.57 || angle > 4.71 ? 1 : -1),
      );
    });
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if ((i + j) % 3 == 0) canvas.drawLine(nodes[i], nodes[j], paint);
      }
    }
    for (final node in nodes) {
      canvas.drawCircle(node, 5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AutomatedResponseCard extends StatelessWidget {
  final Map<String, dynamic> response;
  const _AutomatedResponseCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final actionType = response['action_type'] as String? ?? 'unknown';
    final icon = actionType == 'account_suspension'
        ? Icons.block
        : actionType == 'transaction_block'
        ? Icons.credit_card_off
        : Icons.speed;
    final color = actionType == 'account_suspension'
        ? Colors.red
        : actionType == 'transaction_block'
        ? Colors.orange
        : Colors.blue;
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionType.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  response['description'] as String? ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'TRIGGERED',
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
