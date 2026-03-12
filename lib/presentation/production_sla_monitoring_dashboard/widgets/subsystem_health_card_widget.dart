import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SubsystemHealthCardWidget extends StatelessWidget {
  final String serviceName;
  final Map<String, dynamic> healthData;

  const SubsystemHealthCardWidget({
    super.key,
    required this.serviceName,
    required this.healthData,
  });

  @override
  Widget build(BuildContext context) {
    final status = healthData['status'] ?? 'unknown';
    final responseTime = healthData['response_time_ms'] ?? 0;
    final uptime = healthData['uptime'] ?? 0.0;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'operational':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Operational';
        break;
      case 'degraded':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        statusLabel = 'Degraded';
        break;
      case 'outage':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusLabel = 'Outage';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusLabel = 'Unknown';
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetailedView(context),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _getServiceIcon(),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _formatServiceName(serviceName),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(statusIcon, size: 14.sp, color: statusColor),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                '${responseTime}ms',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
              Text(
                '${uptime.toStringAsFixed(2)}% uptime',
                style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Last check: 30s ago',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getServiceIcon() {
    IconData icon;
    Color color;

    switch (serviceName.toLowerCase()) {
      case 'supabase':
        icon = Icons.storage;
        color = Colors.green;
        break;
      case 'stripe':
        icon = Icons.payment;
        color = Colors.purple;
        break;
      case 'openai':
      case 'anthropic':
      case 'perplexity':
      case 'gemini':
        icon = Icons.psychology;
        color = Colors.blue;
        break;
      case 'twilio':
        icon = Icons.sms;
        color = Colors.red;
        break;
      case 'resend':
        icon = Icons.email;
        color = Colors.orange;
        break;
      default:
        icon = Icons.cloud;
        color = Colors.grey;
    }

    return Icon(icon, size: 20.sp, color: color);
  }

  String _formatServiceName(String name) {
    return name[0].toUpperCase() + name.substring(1);
  }

  void _showDetailedView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getServiceIcon(),
            SizedBox(width: 2.w),
            Text(_formatServiceName(serviceName)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', healthData['status'] ?? 'Unknown'),
              _buildDetailRow(
                'Response Time',
                '${healthData['response_time_ms'] ?? 0}ms',
              ),
              _buildDetailRow(
                'Uptime',
                '${(healthData['uptime'] ?? 0.0).toStringAsFixed(2)}%',
              ),
              if (healthData['error_message'] != null)
                _buildDetailRow('Error', healthData['error_message']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(value, style: TextStyle(fontSize: 12.sp)),
        ],
      ),
    );
  }
}
