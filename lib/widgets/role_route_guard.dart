import 'package:flutter/material.dart';

import '../constants/roles.dart';
import '../services/auth_service_new.dart';

/// Wraps a screen and redirects if user is unauthenticated or lacks required roles.
class RoleRouteGuard extends StatefulWidget {
  const RoleRouteGuard({
    super.key,
    required this.child,
    required this.requiredRoles,
    this.fallbackRoute = '/splash',
    this.authRoute,
  });

  final Widget child;
  final List<String> requiredRoles;
  final String fallbackRoute;
  /// Route for unauthenticated users (defaults to fallbackRoute)
  final String? authRoute;

  @override
  State<RoleRouteGuard> createState() => _RoleRouteGuardState();
}

class _RoleRouteGuardState extends State<RoleRouteGuard> {
  bool _checked = false;
  bool _allowed = false;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final auth = AuthService.instance;
    final isAuthenticated = auth.isAuthenticated;
    if (!isAuthenticated) {
      if (mounted) {
        setState(() {
          _checked = true;
          _allowed = false;
          _authenticated = false;
        });
        _redirect(widget.authRoute ?? widget.fallbackRoute);
      }
      return;
    }
    final profile = await auth.getUserProfile();
    final role = profile?['role'] as String?;
    final allowed = AppRoles.hasAnyRole(role, widget.requiredRoles);
    if (mounted) {
      setState(() {
        _checked = true;
        _allowed = allowed;
        _authenticated = true;
      });
      if (!allowed) {
        _showAccessDeniedAndRedirect();
      }
    }
  }

  void _redirect(String route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          route,
          (route) => false,
        );
      }
    });
  }

  void _showAccessDeniedAndRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "You don't have permission to access this screen.",
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _redirect(widget.fallbackRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_allowed) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
