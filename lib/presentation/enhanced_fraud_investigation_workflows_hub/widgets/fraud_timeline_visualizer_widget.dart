import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FraudTimelineVisualizerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> events;

  const FraudTimelineVisualizerWidget({super.key, required this.events});

  @override
  State<FraudTimelineVisualizerWidget> createState() =>
      _FraudTimelineVisualizerWidgetState();
}

class _FraudTimelineVisualizerWidgetState
    extends State<FraudTimelineVisualizerWidget> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return Center(
        child: Text(
          'No timeline events available',
          style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondaryLight),
        ),
      );
    }

    return Column(
      children: [
        // Controls
        Container(
          padding: EdgeInsets.all(2.w),
          color: AppTheme.surfaceLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline (${widget.events.length} events)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_out, size: 5.w),
                    onPressed: () =>
                        setState(() => _scale = (_scale - 0.2).clamp(0.5, 3.0)),
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_in, size: 5.w),
                    onPressed: () =>
                        setState(() => _scale = (_scale + 0.2).clamp(0.5, 3.0)),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, size: 5.w),
                    onPressed: () => setState(() {
                      _scale = 1.0;
                      _offset = Offset.zero;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Timeline visualization
        Expanded(
          child: GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _scale = (_scale * details.scale).clamp(0.5, 3.0);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _offset += details.delta;
              });
            },
            child: Transform(
              transform: Matrix4.identity()
                ..translate(_offset.dx, _offset.dy)
                ..scale(_scale),
              child: CustomPaint(
                painter: TimelinePainter(events: widget.events),
                child: Container(),
              ),
            ),
          ),
        ),

        // Legend
        Container(
          padding: EdgeInsets.all(2.w),
          color: AppTheme.surfaceLight,
          child: Wrap(
            spacing: 4.w,
            children: [
              _buildLegendItem('Authentication', Colors.red),
              _buildLegendItem('Payment', Colors.blue),
              _buildLegendItem('User Action', Colors.green),
              _buildLegendItem('Security', Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}

class TimelinePainter extends CustomPainter {
  final List<Map<String, dynamic>> events;

  TimelinePainter({required this.events});

  @override
  void paint(Canvas canvas, Size size) {
    if (events.isEmpty) return;

    // Sort events by timestamp
    final sortedEvents = List<Map<String, dynamic>>.from(events)
      ..sort((a, b) {
        final aTime = DateTime.parse(
          a['timestamp'] ?? DateTime.now().toIso8601String(),
        );
        final bTime = DateTime.parse(
          b['timestamp'] ?? DateTime.now().toIso8601String(),
        );
        return aTime.compareTo(bTime);
      });

    // Calculate time range
    final firstTime = DateTime.parse(sortedEvents.first['timestamp']);
    final lastTime = DateTime.parse(sortedEvents.last['timestamp']);
    final timeRange = lastTime.difference(firstTime).inSeconds;

    // Draw timeline axis
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(50, size.height / 2),
      Offset(size.width - 50, size.height / 2),
      axisPaint,
    );

    // Draw events
    for (int i = 0; i < sortedEvents.length; i++) {
      final event = sortedEvents[i];
      final eventTime = DateTime.parse(event['timestamp']);
      final position = timeRange > 0
          ? (eventTime.difference(firstTime).inSeconds / timeRange)
          : 0.5;

      final x = 50 + (size.width - 100) * position;
      final y = size.height / 2;

      // Event color based on type
      final eventType = event['event_type'] as String? ?? 'user_action';
      Color color;
      switch (eventType.toLowerCase()) {
        case 'authentication':
          color = Colors.red;
          break;
        case 'payment':
          color = Colors.blue;
          break;
        case 'security':
          color = Colors.orange;
          break;
        default:
          color = Colors.green;
      }

      // Draw event node
      final nodePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, nodePaint);

      // Draw connecting line to next event
      if (i < sortedEvents.length - 1) {
        final nextEvent = sortedEvents[i + 1];
        final nextTime = DateTime.parse(nextEvent['timestamp']);
        final nextPosition = timeRange > 0
            ? (nextTime.difference(firstTime).inSeconds / timeRange)
            : 0.5;
        final nextX = 50 + (size.width - 100) * nextPosition;

        final linePaint = Paint()
          ..color = color.withAlpha(77)
          ..strokeWidth = 2;

        canvas.drawLine(Offset(x, y), Offset(nextX, y), linePaint);

        // Draw arrow
        _drawArrow(canvas, Offset(x, y), Offset(nextX, y), color);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color.withAlpha(128)
      ..strokeWidth = 2;

    final arrowSize = 10.0;
    final angle = (end - start).direction;

    final arrowP1 = end + Offset.fromDirection(angle + 2.8, arrowSize);
    final arrowP2 = end + Offset.fromDirection(angle - 2.8, arrowSize);

    canvas.drawLine(end, arrowP1, paint);
    canvas.drawLine(end, arrowP2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
