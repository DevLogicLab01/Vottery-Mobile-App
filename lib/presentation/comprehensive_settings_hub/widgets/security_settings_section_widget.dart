import 'package:flutter/material.dart';

import '../../../config/batch1_route_allowlist.dart';
import '../../user_profile/widgets/settings_section_widget.dart';
import '../../../routes/app_routes.dart';

/// Security settings section widget for authentication and session management.
class SecuritySettingsSectionWidget extends StatelessWidget {
  const SecuritySettingsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Batch1RouteAllowlist.isAllowed(AppRoutes.userSecurityCenter)) {
      return const SizedBox.shrink();
    }
    return SettingsSectionWidget(
      title: 'Security Settings',
      items: [
        {
          'icon': 'security',
          'title': 'Two-Factor Authentication',
          'subtitle': 'Add extra security to your account',
          'onTap': () {
            Navigator.pushNamed(context, AppRoutes.userSecurityCenter);
          },
        },
        {
          'icon': 'fingerprint',
          'title': 'Biometric Authentication',
          'subtitle': 'Use fingerprint or face ID',
          'onTap': () {
            Navigator.pushNamed(context, AppRoutes.userSecurityCenter);
          },
        },
        {
          'icon': 'devices',
          'title': 'Active Sessions',
          'subtitle': 'View and revoke active sessions',
          'onTap': () {
            Navigator.pushNamed(context, AppRoutes.userSecurityCenter);
          },
        },
      ],
    );
  }
}