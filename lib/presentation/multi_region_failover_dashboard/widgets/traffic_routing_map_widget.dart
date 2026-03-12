import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class TrafficRoutingMapWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> regionHealth;

  const TrafficRoutingMapWidget({super.key, required this.regionHealth});

  @override
  Widget build(BuildContext context) {
    final zoneRoutings = [
      {'zones': 'Zones 1-2', 'region': 'us_east', 'traffic': '35%'},
      {'zones': 'Zones 3-4', 'region': 'us_west', 'traffic': '25%'},
      {'zones': 'Zones 5-6', 'region': 'eu_west', 'traffic': '25%'},
      {'zones': 'Zones 7-8', 'region': 'asia_pacific', 'traffic': '15%'},
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 2.w),
                Text(
                  'Traffic Routing Map',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            ...zoneRoutings.map((routing) {
              final region = routing['region']!;
              final health = regionHealth[region];
              final healthScore = (health?['health_score'] ?? 85).toDouble();
              final isHealthy = healthScore >= 70;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Container(
                      width: 20.w,
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(26),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        routing['zones']!,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: (isHealthy ? Colors.green : Colors.red)
                              .withAlpha(26),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: (isHealthy ? Colors.green : Colors.red)
                                .withAlpha(77),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isHealthy ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              region.replaceAll('_', '-').toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: isHealthy
                                    ? Colors.green[800]
                                    : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      routing['traffic']!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
