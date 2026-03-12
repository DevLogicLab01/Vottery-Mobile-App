import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_security_service.dart';

class ActiveSessionsWidget extends StatefulWidget {
  final VoidCallback onSessionsChanged;

  const ActiveSessionsWidget({super.key, required this.onSessionsChanged});

  @override
  State<ActiveSessionsWidget> createState() => _ActiveSessionsWidgetState();
}

class _ActiveSessionsWidgetState extends State<ActiveSessionsWidget> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      final sessions = await UserSecurityService.instance.getActiveSessions();

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _terminateSession(String sessionId, bool isCurrent) async {
    if (isCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot terminate current session'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Session'),
        content: const Text(
          'Are you sure you want to sign out this device? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await UserSecurityService.instance.terminateSession(
        sessionId,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session terminated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSessionsChanged();
        _loadSessions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : _sessions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.devices_other, size: 30.sp, color: Colors.grey),
                SizedBox(height: 2.h),
                Text(
                  'No active sessions',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(3.w),
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              final session = _sessions[index];
              final device = session['trusted_devices'];
              final deviceName = device?['device_name'] ?? 'Unknown Device';
              final ipAddress = session['ip_address'];
              final isCurrent = session['is_current'] ?? false;
              final lastActivity = session['last_activity_at'] != null
                  ? DateTime.parse(session['last_activity_at'])
                  : null;
              final expiresAt = session['expires_at'] != null
                  ? DateTime.parse(session['expires_at'])
                  : null;

              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? Colors.green.withAlpha(51)
                        : Colors.blue.withAlpha(51),
                    child: Icon(
                      isCurrent ? Icons.check_circle : Icons.devices,
                      color: isCurrent ? Colors.green : Colors.blue,
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
                      if (ipAddress != null)
                        Text(
                          'IP: $ipAddress',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      if (lastActivity != null)
                        Text(
                          'Last active: ${lastActivity.toString().substring(0, 16)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (expiresAt != null)
                        Text(
                          'Expires: ${expiresAt.toString().substring(0, 16)}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: isCurrent
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(51),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          onPressed: () =>
                              _terminateSession(session['id'], isCurrent),
                        ),
                ),
              );
            },
          );
  }
}
