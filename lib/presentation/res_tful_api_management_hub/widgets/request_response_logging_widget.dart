import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/restful_api_service.dart';

class RequestResponseLoggingWidget extends StatefulWidget {
  const RequestResponseLoggingWidget({super.key});

  @override
  State<RequestResponseLoggingWidget> createState() =>
      _RequestResponseLoggingWidgetState();
}

class _RequestResponseLoggingWidgetState
    extends State<RequestResponseLoggingWidget> {
  final RestfulApiService _apiService = RestfulApiService.instance;
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _apiService.getAuditLogs(limit: 50);
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: Icon(
              log['method'] == 'POST' ? Icons.upload : Icons.download,
              color: log['method'] == 'POST' ? Colors.green : Colors.blue,
            ),
            title: Text(
              log['endpoint'] ?? '',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Status: ${log['status_code']} | ${log['response_time_ms']}ms',
              style: TextStyle(fontSize: 10.sp),
            ),
            trailing: Text(
              log['created_at'] ?? '',
              style: TextStyle(fontSize: 9.sp, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
