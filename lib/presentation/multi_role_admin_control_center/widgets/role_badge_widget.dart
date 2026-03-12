import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RoleBadgeWidget extends StatelessWidget {
  final String role;
  final String colorCode;
  final String size; // 'small', 'medium', 'large'

  const RoleBadgeWidget({
    super.key,
    required this.role,
    required this.colorCode,
    this.size = 'medium',
  });

  @override
  Widget build(BuildContext context) {
    final badgeSize = _getBadgeSize();
    final fontSize = _getFontSize();
    final iconSize = _getIconSize();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: badgeSize * 0.3,
        vertical: badgeSize * 0.15,
      ),
      decoration: BoxDecoration(
        color: _getRoleColor().withAlpha(38),
        borderRadius: BorderRadius.circular(badgeSize * 0.3),
        border: Border.all(color: _getRoleColor(), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getRoleIcon(), color: _getRoleColor(), size: iconSize),
          SizedBox(width: badgeSize * 0.1),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _getRoleColor(),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  double _getBadgeSize() {
    switch (size) {
      case 'small':
        return 20.0;
      case 'large':
        return 40.0;
      default:
        return 30.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case 'small':
        return 10.sp;
      case 'large':
        return 14.sp;
      default:
        return 12.sp;
    }
  }

  double _getIconSize() {
    switch (size) {
      case 'small':
        return 14.sp;
      case 'large':
        return 20.sp;
      default:
        return 16.sp;
    }
  }

  Color _getRoleColor() {
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

  IconData _getRoleIcon() {
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
