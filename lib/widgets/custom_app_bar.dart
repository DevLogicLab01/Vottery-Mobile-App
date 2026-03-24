import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar variants for the voting application.
/// Implements Contemporary Civic Minimalism with clean authority.
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with back button for navigation
  withBack,

  /// App bar with search functionality
  withSearch,

  /// App bar with sync status indicator
  withSyncStatus,

  /// Transparent app bar for special screens (splash, onboarding)
  transparent,
}

/// Custom app bar widget implementing the voting app's design system.
/// Provides consistent navigation and branding across all screens.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display in the app bar
  final String title;

  /// Variant of the app bar to display
  final CustomAppBarVariant variant;

  /// Optional leading widget (overrides default back button)
  final Widget? leading;

  /// Optional actions to display on the right side
  final List<Widget>? actions;

  /// Whether to center the title
  final bool centerTitle;

  /// Optional callback for back button
  final VoidCallback? onBackPressed;

  /// Optional callback for search
  final VoidCallback? onSearchPressed;

  /// Sync status for withSyncStatus variant
  final bool? isOnline;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Whether to show elevation shadow
  final bool showElevation;

  /// Optional bottom widget (e.g. [TabBar]); included in [preferredSize].
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.variant = CustomAppBarVariant.standard,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.onBackPressed,
    this.onSearchPressed,
    this.isOnline,
    this.subtitle,
    this.showElevation = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle transparent variant
    if (variant == CustomAppBarVariant.transparent) {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: leading,
        actions: actions,
      );
    }

    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: showElevation ? 4 : 0,
      centerTitle: centerTitle,
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  /// Build leading widget based on variant
  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (variant == CustomAppBarVariant.withBack) {
      return IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      );
    }

    return null;
  }

  /// Build title widget with optional subtitle
  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    if (subtitle != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.appBarTheme.titleTextStyle),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.appBarTheme.foregroundColor?.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    }

    return Text(title, style: theme.appBarTheme.titleTextStyle);
  }

  /// Build actions based on variant
  List<Widget>? _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> actionWidgets = [];

    // Add search action for withSearch variant
    if (variant == CustomAppBarVariant.withSearch) {
      actionWidgets.add(
        IconButton(
          icon: const Icon(Icons.search, size: 24),
          onPressed: onSearchPressed,
          tooltip: 'Search',
        ),
      );
    }

    // Add sync status indicator for withSyncStatus variant
    if (variant == CustomAppBarVariant.withSyncStatus) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: _SyncStatusIndicator(isOnline: isOnline ?? true),
          ),
        ),
      );
    }

    // Add custom actions if provided
    if (actions != null) {
      actionWidgets.addAll(actions!);
    }

    return actionWidgets.isEmpty ? null : actionWidgets;
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}

/// Sync status indicator widget showing online/offline state
class _SyncStatusIndicator extends StatelessWidget {
  final bool isOnline;

  const _SyncStatusIndicator({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF10B981).withValues(alpha: 0.2)
            : const Color(0xFFF59E0B).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.appBarTheme.foregroundColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
