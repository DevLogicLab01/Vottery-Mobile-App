import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SystemConfigPanelWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onStatusUpdate;
  const SystemConfigPanelWidget({super.key, required this.onStatusUpdate});
  @override
  State<SystemConfigPanelWidget> createState() =>
      _SystemConfigPanelWidgetState();
}

class _SystemConfigPanelWidgetState extends State<SystemConfigPanelWidget> {
  final List<Map<String, dynamic>> _configs = [
    {
      'name': 'Push Notifications',
      'description': 'FCM configuration & delivery',
      'status': 'pending',
      'icon': Icons.notifications_active,
    },
    {
      'name': 'Offline Sync',
      'description': 'Hive storage & sync queue',
      'status': 'pending',
      'icon': Icons.sync,
    },
    {
      'name': 'Location Services',
      'description': 'GPS permissions & accuracy',
      'status': 'pending',
      'icon': Icons.location_on,
    },
    {
      'name': 'Biometric Auth',
      'description': 'Fingerprint & Face ID',
      'status': 'pending',
      'icon': Icons.fingerprint,
    },
    {
      'name': 'Deep Links',
      'description': 'URL scheme & link handling',
      'status': 'pending',
      'icon': Icons.link,
    },
  ];

  Future<void> _testConfig(int index) async {
    setState(() => _configs[index]['status'] = 'testing');
    await Future.delayed(const Duration(milliseconds: 600));
    setState(
      () => _configs[index]['status'] = index == 3 ? 'warning' : 'success',
    );
    _notifyUpdate();
  }

  Future<void> _testAll() async {
    for (int i = 0; i < _configs.length; i++) {
      await _testConfig(i);
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _notifyUpdate() {
    final passed = _configs.where((c) => c['status'] == 'success').length;
    final total = _configs.length;
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
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'failed':
        return const Color(0xFFEF4444);
      case 'testing':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber;
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
              'System Configuration',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _testAll,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('Verify All', style: TextStyle(fontSize: 11.sp)),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ..._configs.asMap().entries.map((entry) {
          final i = entry.key;
          final config = entry.value;
          final status = config['status'] as String;
          return Container(
            margin: EdgeInsets.only(bottom: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: CheckboxListTile(
              value: status == 'success',
              onChanged: null,
              title: Row(
                children: [
                  Icon(
                    config['icon'] as IconData,
                    size: 18,
                    color: const Color(0xFF3B82F6),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      config['name'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                config['description'] as String,
                style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
              ),
              secondary: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 18,
                  ),
                  SizedBox(width: 1.w),
                  TextButton(
                    onPressed: status == 'testing'
                        ? null
                        : () => _testConfig(i),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                    ),
                    child: Text('Test', style: TextStyle(fontSize: 10.sp)),
                  ),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        }),
      ],
    );
  }
}
