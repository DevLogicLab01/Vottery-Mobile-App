import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_security_service.dart';

class TrustedDevicesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> devices;
  final VoidCallback onDevicesChanged;

  const TrustedDevicesWidget({
    super.key,
    required this.devices,
    required this.onDevicesChanged,
  });

  @override
  State<TrustedDevicesWidget> createState() => _TrustedDevicesWidgetState();
}

class _TrustedDevicesWidgetState extends State<TrustedDevicesWidget> {
  Future<void> _revokeDevice(String deviceId, String deviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Device Access'),
        content: Text(
          'Are you sure you want to revoke access for $deviceName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await UserSecurityService.instance.revokeDevice(deviceId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device access revoked'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onDevicesChanged();
      }
    }
  }

  Future<void> _authorizeDevice(String deviceId, String deviceName) async {
    final success = await UserSecurityService.instance.authorizeDevice(
      deviceId,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deviceName authorized successfully'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onDevicesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.devices.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_outlined, size: 30.sp, color: Colors.grey),
                SizedBox(height: 2.h),
                Text(
                  'No devices registered',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: widget.devices.length,
            itemBuilder: (context, index) {
              final device = widget.devices[index];
              final deviceName = device['device_name'] ?? 'Unknown Device';
              final deviceType = device['device_type'] ?? 'unknown';
              final browser = device['browser'];
              final os = device['operating_system'];
              final isTrusted = device['is_trusted'] ?? false;
              final lastUsed = device['last_used_at'] != null
                  ? DateTime.parse(device['last_used_at'])
                  : null;
              final ipAddress = device['ip_address'];

              IconData deviceIcon;
              switch (deviceType) {
                case 'mobile':
                  deviceIcon = Icons.phone_android;
                  break;
                case 'tablet':
                  deviceIcon = Icons.tablet;
                  break;
                case 'desktop':
                  deviceIcon = Icons.computer;
                  break;
                default:
                  deviceIcon = Icons.devices;
              }

              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: isTrusted
                        ? Colors.green.withAlpha(51)
                        : Colors.grey.withAlpha(51),
                    child: Icon(
                      deviceIcon,
                      color: isTrusted ? Colors.green : Colors.grey,
                    ),
                  ),
                  title: Text(
                    deviceName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 0.5.h),
                      if (browser != null && os != null)
                        Text(
                          '$browser on $os',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      if (lastUsed != null)
                        Text(
                          'Last used: ${lastUsed.toString().substring(0, 16)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isTrusted
                          ? Colors.green.withAlpha(51)
                          : Colors.grey.withAlpha(51),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      isTrusted ? 'TRUSTED' : 'REVOKED',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: isTrusted ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ipAddress != null)
                            _buildDetailRow(
                              'IP Address',
                              ipAddress,
                              Icons.location_on,
                            ),
                          _buildDetailRow(
                            'Device Type',
                            deviceType,
                            Icons.category,
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              if (isTrusted)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _revokeDevice(device['id'], deviceName),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Revoke Access'),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _authorizeDevice(
                                      device['id'],
                                      deviceName,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Authorize'),
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
          );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.grey[600]),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 11.sp)),
          ),
        ],
      ),
    );
  }
}
