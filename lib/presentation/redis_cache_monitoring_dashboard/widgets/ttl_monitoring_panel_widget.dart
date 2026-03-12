import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/redis_cache_service.dart';

class TtlMonitoringPanelWidget extends StatelessWidget {
  const TtlMonitoringPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final expiringSoon = RedisCacheService.instance.getKeysExpiringSoon(
      withinSeconds: 120,
    );
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2D2D3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TTL Monitoring',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: expiringSoon.isEmpty
                      ? const Color(0xFF10B981).withAlpha(51)
                      : const Color(0xFFF59E0B).withAlpha(51),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '${expiringSoon.length} expiring soon',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: expiringSoon.isEmpty
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          expiringSoon.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Text(
                      'No keys expiring within 2 minutes',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFF2D2D3F),
                    ),
                    dataRowColor: WidgetStateProperty.all(
                      const Color(0xFF1E1E2E),
                    ),
                    columnSpacing: 3.w,
                    columns: [
                      DataColumn(
                        label: Text(
                          'Key',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'TTL (s)',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Size',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    rows: expiringSoon.take(10).map((item) {
                      final ttl = item['remaining_ttl'] as int;
                      final isUrgent = ttl < 30;
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 35.w,
                              child: Text(
                                item['key'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '$ttl',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: isUrgent
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${item['data_size'] as int} B',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                color: Colors.white54,
                              ),
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
}
