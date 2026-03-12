import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../services/admin_automation_engine_service.dart';

class ExecutionHistoryWidget extends StatefulWidget {
  const ExecutionHistoryWidget({super.key});

  @override
  State<ExecutionHistoryWidget> createState() => _ExecutionHistoryWidgetState();
}

class _ExecutionHistoryWidgetState extends State<ExecutionHistoryWidget> {
  List<ExecutionLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final logs = await AdminAutomationEngineService.getExecutionHistory();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'skipped':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Execution History',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () {
                setState(() => _loading = true);
                _loadHistory();
              },
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (_logs.isEmpty)
          Center(
            child: Text(
              'No execution history',
              style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return Card(
                margin: EdgeInsets.only(bottom: 1.h),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.ruleName,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(log.status).withAlpha(26),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              log.status.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                color: _statusColor(log.status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatDateTime(log.executedAt),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 3.w),
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${log.affectedCount} affected',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (log.actionsTaken.isNotEmpty) ...[
                        SizedBox(height: 0.5.h),
                        Wrap(
                          spacing: 1.w,
                          children: log.actionsTaken
                              .map(
                                (a) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 1.5.w,
                                    vertical: 0.2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(26),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    a.replaceAll('_', ' '),
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
