import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ZoneRedemptionHeatmapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> zoneData;

  const ZoneRedemptionHeatmapWidget({super.key, required this.zoneData});

  @override
  Widget build(BuildContext context) {
    final displayData = zoneData.isEmpty ? _mockZoneData() : zoneData;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone Redemption Heatmap',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '8 Purchasing Power Zones',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[500]),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 1.h,
              childAspectRatio: 1.4,
            ),
            itemCount: displayData.length.clamp(0, 8),
            itemBuilder: (ctx, i) {
              final zone = displayData[i];
              final rate = (zone['redemption_rate'] as num?)?.toDouble() ?? 0.0;
              return _buildZoneCell(
                zone['zone_name']?.toString() ?? 'Zone ${i + 1}',
                rate,
              );
            },
          ),
          SizedBox(height: 2.h),
          Text(
            'Zone Comparison',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 1.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columnSpacing: 3.w,
              headingTextStyle: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              columns: const [
                DataColumn(label: Text('Zone')),
                DataColumn(label: Text('Redemption'), numeric: true),
                DataColumn(label: Text('Avg VP'), numeric: true),
                DataColumn(label: Text('Top Category')),
              ],
              rows: displayData.take(8).map((zone) {
                final rate =
                    (zone['redemption_rate'] as num?)?.toDouble() ?? 0.0;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        zone['zone_name']?.toString() ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${rate.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: _rateColor(rate),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${zone['avg_vp_balance'] ?? 0}',
                        style: GoogleFonts.inter(fontSize: 10.sp),
                      ),
                    ),
                    DataCell(
                      Text(
                        zone['top_redemption_category']?.toString() ?? 'N/A',
                        style: GoogleFonts.inter(fontSize: 9.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCell(String name, double rate) {
    final color = _rateColor(rate);
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1 + (rate / 100) * 0.4),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${rate.toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            name,
            style: GoogleFonts.inter(fontSize: 8.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 70) return const Color(0xFF4CAF50);
    if (rate >= 40) return const Color(0xFFFFB347);
    return const Color(0xFFFF6B6B);
  }

  List<Map<String, dynamic>> _mockZoneData() {
    return [
      {
        'zone_name': 'North America',
        'redemption_rate': 78.5,
        'avg_vp_balance': 1240,
        'top_redemption_category': 'Premium',
      },
      {
        'zone_name': 'Europe',
        'redemption_rate': 65.2,
        'avg_vp_balance': 980,
        'top_redemption_category': 'Ad-Free',
      },
      {
        'zone_name': 'Asia Pacific',
        'redemption_rate': 82.1,
        'avg_vp_balance': 1560,
        'top_redemption_category': 'Avatars',
      },
      {
        'zone_name': 'Latin America',
        'redemption_rate': 45.8,
        'avg_vp_balance': 620,
        'top_redemption_category': 'Boosts',
      },
      {
        'zone_name': 'Middle East',
        'redemption_rate': 58.3,
        'avg_vp_balance': 890,
        'top_redemption_category': 'Premium',
      },
      {
        'zone_name': 'Africa',
        'redemption_rate': 32.7,
        'avg_vp_balance': 340,
        'top_redemption_category': 'Boosts',
      },
      {
        'zone_name': 'South Asia',
        'redemption_rate': 71.4,
        'avg_vp_balance': 1120,
        'top_redemption_category': 'Avatars',
      },
      {
        'zone_name': 'Oceania',
        'redemption_rate': 69.9,
        'avg_vp_balance': 1050,
        'top_redemption_category': 'Ad-Free',
      },
    ];
  }
}
