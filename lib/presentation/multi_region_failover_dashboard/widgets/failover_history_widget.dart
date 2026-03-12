import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FailoverHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> failoverEvents;

  const FailoverHistoryWidget({super.key, required this.failoverEvents});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.orange),
                SizedBox(width: 2.w),
                Text(
                  'Failover History',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            if (failoverEvents.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Text(
                    'No failover events',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: failoverEvents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = failoverEvents[index];
                  final isAutomatic = event['trigger_type'] == 'automatic';
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(1.5.w),
                          decoration: BoxDecoration(
                            color: (isAutomatic ? Colors.orange : Colors.blue)
                                .withAlpha(26),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAutomatic ? Icons.auto_fix_high : Icons.person,
                            size: 14,
                            color: isAutomatic ? Colors.orange : Colors.blue,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    event['from_region']
                                            ?.toString()
                                            .replaceAll('_', '-')
                                            .toUpperCase() ??
                                        'UNKNOWN',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    event['to_region']
                                            ?.toString()
                                            .replaceAll('_', '-')
                                            .toUpperCase() ??
                                        'UNKNOWN',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                event['reason'] ?? 'Health degradation',
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Row(
                                children: [
                                  Text(
                                    event['timestamp'] ?? '',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 1.5.w,
                                      vertical: 0.1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isAutomatic
                                                  ? Colors.orange
                                                  : Colors.blue)
                                              .withAlpha(26),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: Text(
                                      isAutomatic ? 'AUTO' : 'MANUAL',
                                      style: GoogleFonts.inter(
                                        fontSize: 8.sp,
                                        color: isAutomatic
                                            ? Colors.orange
                                            : Colors.blue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
