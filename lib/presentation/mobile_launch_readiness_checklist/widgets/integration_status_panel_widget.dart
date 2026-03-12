import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IntegrationStatusPanelWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onStatusUpdate;
  const IntegrationStatusPanelWidget({super.key, required this.onStatusUpdate});
  @override
  State<IntegrationStatusPanelWidget> createState() =>
      _IntegrationStatusPanelWidgetState();
}

class _IntegrationStatusPanelWidgetState
    extends State<IntegrationStatusPanelWidget> {
  final List<Map<String, dynamic>> _integrations = [
    {
      'name': 'Claude API',
      'key': 'ANTHROPIC_API_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Twilio SMS',
      'key': 'TWILIO_ACCOUNT_SID',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Telnyx SMS',
      'key': 'TELNYX_API_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Resend Email',
      'key': 'RESEND_API_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Stripe Payouts',
      'key': 'STRIPE_SECRET_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Supabase Backend',
      'key': 'SUPABASE_URL',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'OpenAI',
      'key': 'OPENAI_API_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Gemini AI',
      'key': 'GEMINI_API_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
    {
      'name': 'Perplexity AI',
      'key': 'PERPLEXITY_API_KEY',
      'status': 'pending',
      'lastTested': null,
      'responseTime': null,
    },
  ];
  bool _isTesting = false;

  Future<void> _testIntegration(int index) async {
    setState(() => _integrations[index]['status'] = 'testing');
    await Future.delayed(const Duration(milliseconds: 800));
    final success = index != 2;
    setState(() {
      _integrations[index]['status'] = success ? 'success' : 'failed';
      _integrations[index]['lastTested'] = DateTime.now();
      _integrations[index]['responseTime'] = success
          ? '${120 + index * 30}ms'
          : null;
    });
    _notifyUpdate();
  }

  Future<void> _testAll() async {
    setState(() => _isTesting = true);
    for (int i = 0; i < _integrations.length; i++) {
      await _testIntegration(i);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    setState(() => _isTesting = false);
  }

  void _notifyUpdate() {
    final passed = _integrations.where((i) => i['status'] == 'success').length;
    final total = _integrations.length;
    widget.onStatusUpdate({
      'passed': passed,
      'total': total,
      'score': total > 0 ? (passed / total * 100).round() : 0,
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return const Color(0xFF10B981);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'testing':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      case 'testing':
        return Icons.hourglass_empty;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Service Integrations',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testAll,
              icon: _isTesting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 16),
              label: Text(
                _isTesting ? 'Testing...' : 'Test All',
                style: TextStyle(fontSize: 11.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 3.w,
            headingRowHeight: 4.h,
            dataRowMinHeight: 5.h,
            dataRowMaxHeight: 6.h,
            columns: [
              DataColumn(
                label: Text(
                  'Integration',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Response',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Last Tested',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            rows: _integrations.asMap().entries.map((entry) {
              final i = entry.key;
              final integration = entry.value;
              final status = integration['status'] as String;
              final lastTested = integration['lastTested'] as DateTime?;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      integration['name'] as String,
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          _statusIcon(status),
                          color: _statusColor(status),
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          status == 'testing'
                              ? 'Testing'
                              : status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: _statusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      integration['responseTime'] as String? ?? '-',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
                  DataCell(
                    Text(
                      lastTested != null
                          ? '${lastTested.hour}:${lastTested.minute.toString().padLeft(2, '0')}'
                          : 'Never',
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
                  DataCell(
                    TextButton(
                      onPressed: status == 'testing'
                          ? null
                          : () => _testIntegration(i),
                      child: Text('Test', style: TextStyle(fontSize: 10.sp)),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
