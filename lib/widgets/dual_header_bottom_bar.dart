import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../config/batch1_route_allowlist.dart';
import '../../services/auth_service.dart';

/// Dual Header Navigation System - Bottom Header
/// Home → Jolts → Elections & Voting (dropdown) → Posts/Feeds (dropdown) → Groups → Profile (dropdown)
class DualHeaderBottomBar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const DualHeaderBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<DualHeaderBottomBar> createState() => _DualHeaderBottomBarState();
}

class _DualHeaderBottomBarState extends State<DualHeaderBottomBar> {
  String? _activeDropdown;

  void _toggleDropdown(String dropdown) {
    setState(() {
      _activeDropdown = _activeDropdown == dropdown ? null : dropdown;
    });
  }

  void _navigate(String route) {
    if (!Batch1RouteAllowlist.isAllowed(route)) return;
    setState(() => _activeDropdown = null);
    widget.onNavigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_activeDropdown != null) _buildDropdownMenu(),
        Container(
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 8.h,
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    Icons.home_outlined,
                    Icons.home,
                    'Home',
                    AppRoutes.socialMediaHomeFeed,
                  ),
                  _buildNavItem(
                    Icons.video_library_outlined,
                    Icons.video_library,
                    'Jolts',
                    AppRoutes.joltsVideoFeed,
                  ),
                  _buildDropdownNavItem(
                    Icons.how_to_vote_outlined,
                    Icons.how_to_vote,
                    'Elections',
                    'elections',
                  ),
                  _buildDropdownNavItem(
                    Icons.feed_outlined,
                    Icons.feed,
                    'Posts',
                    'posts',
                  ),
                  _buildNavItem(
                    Icons.groups_outlined,
                    Icons.groups,
                    'Groups',
                    AppRoutes.groupsHub,
                  ),
                  _buildDropdownNavItem(
                    Icons.account_circle_outlined,
                    Icons.account_circle,
                    'Profile',
                    'profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    String route,
  ) {
    if (!Batch1RouteAllowlist.isAllowed(route)) {
      return const SizedBox.shrink();
    }
    final isActive = widget.currentRoute == route;

    return GestureDetector(
      onTap: () => _navigate(route),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive
                ? Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.vibrantYellow, width: 1.5),
                      color: AppTheme.pureBlue.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      filledIcon,
                      color: AppTheme.pureBlue,
                      size: 5.w,
                    ),
                  )
                : Icon(
                    outlinedIcon,
                    color: Colors.grey[400],
                    size: 6.w,
                  ),
            SizedBox(height: 0.3.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.vibrantYellow : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownNavItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    String dropdownId,
  ) {
    final isActive = _activeDropdown == dropdownId;

    return GestureDetector(
      onTap: () => _toggleDropdown(dropdownId),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive
                ? Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.vibrantYellow, width: 1.5),
                      color: AppTheme.pureBlue.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      filledIcon,
                      color: AppTheme.pureBlue,
                      size: 5.w,
                    ),
                  )
                : Icon(
                    outlinedIcon,
                    color: Colors.grey[400],
                    size: 6.w,
                  ),
            SizedBox(height: 0.3.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.vibrantYellow : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownMenu() {
    final items = _getDropdownItems()
        .where(
          (item) =>
              item['isLogout'] == true ||
              Batch1RouteAllowlist.isAllowed(item['route'] as String?),
        )
        .toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) {
                final isLogout = item['isLogout'] == true;
                return ListTile(
                  leading: Icon(item['icon'] as IconData, size: 5.w),
                  title: Text(
                    item['label'] as String,
                    style: GoogleFonts.inter(fontSize: 13.sp),
                  ),
                  onTap: () {
                    if (isLogout) {
                      _handleLogout(context);
                    } else {
                      _navigate(item['route'] as String);
                    }
                  },
                );
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    setState(() => _activeDropdown = null);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AuthService.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splash,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getDropdownItems() {
    switch (_activeDropdown) {
      case 'elections':
        return [
          {
            'icon': Icons.add_circle_outline,
            'label': 'Create Elections',
            'route': AppRoutes.electionCreationStudio,
          },
          {
            'icon': Icons.how_to_vote,
            'label': 'Vote in Elections',
            'route': AppRoutes.voteDiscovery,
          },
          {
            'icon': Icons.verified_outlined,
            'label': 'Verify Elections',
            'route': AppRoutes.blockchainVoteVerificationHub,
          },
          {
            'icon': Icons.analytics_outlined,
            'label': 'Audit Elections',
            'route': AppRoutes.blockchainAuditPortal,
          },
        ];
      case 'posts':
        return [
          {
            'icon': Icons.post_add,
            'label': 'Post',
            'route': AppRoutes.socialPostComposer,
          },
          {
            'icon': Icons.auto_stories,
            'label': 'Moment',
            'route': AppRoutes.momentsStoriesHub,
          },
          {
            'icon': Icons.video_library,
            'label': 'Jolts',
            'route': AppRoutes.joltsVideoFeed,
          },
          {
            'icon': Icons.live_tv,
            'label': 'Live',
            'route': AppRoutes.liveStreamingCenter,
          },
        ];
      case 'profile':
        return [
          {
            'icon': Icons.person,
            'label': 'View Profile',
            'route': AppRoutes.userProfile,
          },
          {
            'icon': Icons.account_balance_wallet,
            'label': 'Digital Wallet',
            'route': AppRoutes.digitalWalletScreen,
          },
          {
            'icon': Icons.settings,
            'label': 'Settings',
            'route': AppRoutes.comprehensiveSettingsHub,
          },
          {
            'icon': Icons.security,
            'label': 'Security Audit',
            'route': AppRoutes.securityAuditDashboard,
          },
          {
            'icon': Icons.groups,
            'label': 'Creator Community',
            'route': AppRoutes.creatorCommunityHub,
          },
          {
            'icon': Icons.help_outline,
            'label': 'Help & Support',
            'route': AppRoutes.userFeedbackPortal,
          },
          {
            'icon': Icons.brightness_6,
            'label': 'Theme',
            'route': AppRoutes.comprehensiveSettingsHub,
          },
          {
            'icon': Icons.logout,
            'label': 'Logout',
            'route': AppRoutes.splash,
            'isLogout': true,
          },
        ];
      default:
        return [];
    }
  }
}