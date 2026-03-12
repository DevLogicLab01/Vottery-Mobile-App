import 'package:flutter/material.dart';

/// Custom bottom navigation bar for the voting application.
/// Implements bottom-heavy interaction design with thumb-friendly positioning.
///
/// This widget is parameterized and reusable across different implementations.
/// Navigation logic should be handled by the parent widget.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when a navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
              theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
          unselectedLabelStyle:
              theme.bottomNavigationBarTheme.unselectedLabelStyle,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            // Dashboard/Home - Primary destination for active vote discovery
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined, size: 24),
              activeIcon: Icon(
                Icons.dashboard,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              label: 'Dashboard',
              tooltip: 'Vote Dashboard',
            ),

            // History - Essential for tracking participation and outcomes
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined, size: 24),
              activeIcon: Icon(
                Icons.history,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              label: 'History',
              tooltip: 'Vote History',
            ),

            // Profile - Critical for security settings and biometric management
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline, size: 24),
              activeIcon: Icon(
                Icons.person,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              label: 'Profile',
              tooltip: 'User Profile',
            ),
          ],
        ),
      ),
    );
  }
}
