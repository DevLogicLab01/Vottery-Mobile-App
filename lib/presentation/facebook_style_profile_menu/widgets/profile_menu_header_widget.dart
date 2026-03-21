import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../routes/app_routes.dart';
import '../../../services/secure_storage_service.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Profile menu header widget displaying user information
/// and profile switching option.
class ProfileMenuHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileMenuHeaderWidget({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Profile
          Row(
            children: [
              // Avatar
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: userData['avatar'],
                    width: 16.w,
                    height: 16.w,
                    fit: BoxFit.cover,
                    semanticLabel: userData['semanticLabel'],
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Name and Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      userData['email'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // See all profiles
          InkWell(
            onTap: () => _showProfilesSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'people',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'See all profiles',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilesSheet(BuildContext context) {
    final profiles =
        (userData['profiles'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[
          {
            'name': userData['name'],
            'email': userData['email'],
            'active': true,
          },
        ];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(4.w),
          children: [
            Text(
              'Profiles',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.5.h),
            ...profiles.map((profile) {
              final isActive = profile['active'] == true;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (profile['name']?.toString().isNotEmpty ?? false)
                        ? profile['name'].toString().substring(0, 1).toUpperCase()
                        : 'U',
                  ),
                ),
                title: Text(profile['name']?.toString() ?? 'Unknown'),
                subtitle: Text(profile['email']?.toString() ?? ''),
                trailing: isActive
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  final selectedEmail = profile['email']?.toString() ?? '';
                  SecureStorageService.instance.write(
                    'active_profile_context',
                    selectedEmail,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Switched profile context to ${profile['name'] ?? 'profile'}',
                      ),
                    ),
                  );
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed(AppRoutes.userProfile);
                },
              );
            }),
            SizedBox(height: 1.h),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.settingsAccountDashboardWebCanonical);
              },
              icon: const Icon(Icons.manage_accounts),
              label: const Text('Manage Profiles'),
            ),
          ],
        ),
      ),
    );
  }
}
