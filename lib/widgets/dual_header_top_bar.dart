import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../config/batch1_route_allowlist.dart';

/// Dual Header Navigation System - Top Header
/// Menu → Logo → Search → Friend Requests → Messages → Notifications
class DualHeaderTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int friendRequestsCount;
  final int messagesCount;
  final int notificationsCount;
  final String currentRoute;

  const DualHeaderTopBar({
    super.key,
    this.friendRequestsCount = 0,
    this.messagesCount = 0,
    this.notificationsCount = 0,
    required this.currentRoute,
  });

  @override
  Size get preferredSize => Size.fromHeight(7.h);

  @override
  Widget build(BuildContext context) {
    final canOpenNavHub =
        Batch1RouteAllowlist.isAllowed(AppRoutes.socialMediaNavigationHub);
    final canOpenSearch =
        Batch1RouteAllowlist.isAllowed(AppRoutes.advancedUnifiedSearchScreen);
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Menu Icon
          if (canOpenNavHub)
            _buildBrandIconButton(
              context,
              Icons.menu,
              AppRoutes.socialMediaNavigationHub,
            ),

          SizedBox(width: 2.w),

          // Vottery Logo/Brand
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.socialMediaHomeFeed);
            },
            child: Image.asset(
              'assets/images/upscalemedia-transformed_2_-1770683357845.png',
              height: 5.h,
              fit: BoxFit.contain,
              semanticLabel: 'Vottery logo with yellow and white branding',
            ),
          ),

          const Spacer(),

          // Search Icon - users, posts, elections, groups
          if (canOpenSearch)
            _buildBrandIconButton(
              context,
              Icons.search,
              AppRoutes.advancedUnifiedSearchScreen,
            ),

          // Friend Requests Icon
          _buildIconWithBadge(
            context,
            Icons.person_add_outlined,
            friendRequestsCount,
            AppRoutes.friendRequestsHub,
          ),

          // Messages Icon
          _buildIconWithBadge(
            context,
            Icons.chat_bubble_outline,
            messagesCount,
            AppRoutes.directMessagingScreen,
          ),

          // Notifications Icon — Web parity: `/notification-center-hub`
          _buildIconWithBadge(
            context,
            Icons.notifications_outlined,
            notificationsCount,
            AppRoutes.notificationCenterHub,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandIconButton(
    BuildContext context,
    IconData icon,
    String route,
  ) {
    final isActive = _isActive(route);
    return IconButton(
      icon: isActive
          ? Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.vibrantYellow, width: 1.5),
                color: AppTheme.pureBlue.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.pureBlue, size: 5.w),
            )
          : Icon(icon, color: Colors.black87, size: 6.w),
      onPressed: () {
        if (!Batch1RouteAllowlist.isAllowed(route)) return;
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildIconWithBadge(
    BuildContext context,
    IconData icon,
    int count,
    String route,
  ) {
    if (!Batch1RouteAllowlist.isAllowed(route)) {
      return const SizedBox.shrink();
    }
    final isActive = _isActive(route);
    return Stack(
      children: [
        IconButton(
          icon: isActive
              ? Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.vibrantYellow, width: 1.5),
                    color: AppTheme.pureBlue.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppTheme.pureBlue, size: 5.w),
                )
              : Icon(icon, color: Colors.black87, size: 6.w),
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
        ),
        if (count > 0)
          Positioned(
            right: 2.w,
            top: 1.h,
            child: Container(
              padding: EdgeInsets.all(0.5.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(minWidth: 4.w, minHeight: 4.w),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  bool _isActive(String route) {
    return currentRoute == route;
  }
}