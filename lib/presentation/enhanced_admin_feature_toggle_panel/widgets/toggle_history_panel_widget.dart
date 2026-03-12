import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ToggleHistoryPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final VoidCallback onExport;

  const ToggleHistoryPanelWidget({
    super.key,
    required this.history,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blue[600], size: 16.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Toggle History',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onExport,
                  icon: Icon(Icons.download, size: 14.sp),
                  label: Text(
                    'Export',
                    style: GoogleFonts.inter(fontSize: 10.sp),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          if (history.isEmpty)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Center(
                child: Text(
                  'No toggle history available',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 4.h,
                dataRowMinHeight: 3.5.h,
                dataRowMaxHeight: 4.5.h,
                columnSpacing: 3.w,
                headingTextStyle: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                dataTextStyle: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: Colors.grey[700],
                ),
                columns: const [
                  DataColumn(label: Text('Toggle')),
                  DataColumn(label: Text('Previous')),
                  DataColumn(label: Text('New')),
                  DataColumn(label: Text('Changed By')),
                  DataColumn(label: Text('Time')),
                ],
                rows: history.take(10).map((h) {
                  final prevEnabled = h['previous_state'] as bool? ?? false;
                  final newEnabled = h['new_state'] as bool? ?? false;
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          (h['toggle_name'] as String? ?? '').replaceAll(
                            '_',
                            ' ',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.2.h,
                          ),
                          decoration: BoxDecoration(
                            color: prevEnabled
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            prevEnabled ? 'ON' : 'OFF',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: prevEnabled
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 1.5.w,
                            vertical: 0.2.h,
                          ),
                          decoration: BoxDecoration(
                            color: newEnabled
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            newEnabled ? 'ON' : 'OFF',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: newEnabled
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(h['changed_by'] as String? ?? 'Admin')),
                      DataCell(Text(h['timestamp'] as String? ?? '')),
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
