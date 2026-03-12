import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractiveZoneHeatmapWidget extends StatefulWidget {
  final Map<String, Map<String, dynamic>> zoneThreats;
  const InteractiveZoneHeatmapWidget({super.key, required this.zoneThreats});

  @override
  State<InteractiveZoneHeatmapWidget> createState() =>
      _InteractiveZoneHeatmapWidgetState();
}

class _InteractiveZoneHeatmapWidgetState
    extends State<InteractiveZoneHeatmapWidget> {
  String? _selectedZone;

  static const Map<String, Map<String, dynamic>> _zoneInfo = {
    'US_Canada': {'name': 'US/Canada', 'flag': '🇺🇸'},
    'Western_Europe': {'name': 'W. Europe', 'flag': '🇪🇺'},
    'Eastern_Europe': {'name': 'E. Europe', 'flag': '🌍'},
    'Africa': {'name': 'Africa', 'flag': '🌍'},
    'Latin_America': {'name': 'Latin America', 'flag': '🌎'},
    'Middle_East_Asia': {'name': 'Middle East/Asia', 'flag': '🌏'},
    'Australasia': {'name': 'Australasia', 'flag': '🇦🇺'},
    'Southeast_Asia': {'name': 'SE Asia', 'flag': '🌏'},
  };

  Color _getThreatColor(String level) {
    switch (level) {
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone Threat Heatmap',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Tap a zone to view details',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _LegendItem(color: Colors.red, label: 'Critical'),
              SizedBox(width: 3.w),
              _LegendItem(color: Colors.orange, label: 'High'),
              SizedBox(width: 3.w),
              _LegendItem(color: Colors.yellow[700]!, label: 'Medium'),
              SizedBox(width: 3.w),
              _LegendItem(color: Colors.green, label: 'Low'),
            ],
          ),
          SizedBox(height: 2.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 1.5.h,
            childAspectRatio: 1.4,
            children: _zoneInfo.entries.map((entry) {
              final zoneId = entry.key;
              final info = entry.value;
              final threatData = widget.zoneThreats[zoneId] ?? {};
              final threatLevel =
                  threatData['threat_level'] as String? ?? 'low';
              final color = _getThreatColor(threatLevel);
              final isSelected = _selectedZone == zoneId;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedZone = isSelected ? null : zoneId);
                  if (!isSelected) {
                    _showZoneDetailDialog(context, zoneId, info, threatData);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(2.5.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: color.withOpacity(isSelected ? 0.8 : 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            info['flag'] as String,
                            style: const TextStyle(fontSize: 20),
                          ),
                          Container(
                            width: 2.5.w,
                            height: 2.5.w,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            threatLevel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          Text(
                            '${threatData['active_incidents'] ?? 0} incidents',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showZoneDetailDialog(
    BuildContext context,
    String zoneId,
    Map<String, dynamic> info,
    Map<String, dynamic> threatData,
  ) {
    final threatLevel = threatData['threat_level'] as String? ?? 'low';
    final color = _getThreatColor(threatLevel);
    final vulnerabilities = threatData['top_vulnerabilities'] as List? ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            Text(info['flag'] as String, style: const TextStyle(fontSize: 24)),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                info['name'] as String,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Threat Level',
              value: threatLevel.toUpperCase(),
              valueColor: color,
            ),
            _DetailRow(
              label: 'Active Incidents',
              value: '${threatData['active_incidents'] ?? 0}',
            ),
            _DetailRow(
              label: 'Predicted Trend',
              value: threatData['predicted_trend'] as String? ?? 'Stable',
            ),
            if (vulnerabilities.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                'Top Vulnerabilities:',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 0.5.h),
              ...vulnerabilities
                  .take(3)
                  .map(
                    (v) => Padding(
                      padding: EdgeInsets.only(bottom: 0.3.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_right,
                            size: 14.sp,
                            color: Colors.grey[500],
                          ),
                          Expanded(
                            child: Text(
                              v.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2.5.w,
          height: 2.5.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
