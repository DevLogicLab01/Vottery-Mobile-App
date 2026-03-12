import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PermissionMatrixWidget extends StatelessWidget {
  final List<Map<String, dynamic>> permissionMatrices;

  const PermissionMatrixWidget({super.key, required this.permissionMatrices});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: permissionMatrices.length,
      itemBuilder: (context, index) {
        final matrix = permissionMatrices[index];
        return _buildPermissionCard(matrix);
      },
    );
  }

  Widget _buildPermissionCard(Map<String, dynamic> matrix) {
    final role = matrix['role'] ?? '';
    final description = matrix['description'] ?? '';
    final colorCode = matrix['color_code'] ?? 'gray';
    final permissions = matrix['permissions'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: _getRoleColor(colorCode).withAlpha(77)),
      ),
      child: ExpansionTile(
        leading: Icon(
          _getRoleIcon(role),
          color: _getRoleColor(colorCode),
          size: 24.sp,
        ),
        title: Text(
          role.toUpperCase(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: _getRoleColor(colorCode),
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permissions:',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                ...permissions.entries.map((entry) {
                  final hasPermission = entry.value == true;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    child: Row(
                      children: [
                        Icon(
                          hasPermission ? Icons.check_circle : Icons.cancel,
                          color: hasPermission ? Colors.green : Colors.red,
                          size: 16.sp,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _formatPermissionName(entry.key),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: hasPermission
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPermissionName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getRoleColor(String colorCode) {
    switch (colorCode) {
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.amber;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return Icons.manage_accounts;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'moderator':
        return Icons.shield;
      case 'auditor':
        return Icons.fact_check;
      case 'editor':
        return Icons.edit;
      case 'advertiser':
        return Icons.campaign;
      case 'analyst':
        return Icons.analytics;
      default:
        return Icons.person;
    }
  }
}
