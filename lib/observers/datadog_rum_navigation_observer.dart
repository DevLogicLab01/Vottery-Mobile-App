import 'package:flutter/material.dart';
import '../services/datadog_tracing_service.dart';

/// NavigatorObserver that tracks screen views in Datadog RUM.
/// Call startRumView when a route is pushed, stopRumView when popped.
class DatadogRumNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      final prevKey =
          previousRoute.settings.name ?? 'unknown_${previousRoute.hashCode}';
      DatadogTracingService.instance.stopRumView(prevKey);
    }
    final key = route.settings.name ?? 'unknown_${route.hashCode}';
    DatadogTracingService.instance.startRumView(key, name: _displayName(key));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final key = route.settings.name ?? 'unknown_${route.hashCode}';
    DatadogTracingService.instance.stopRumView(key);
    if (previousRoute != null) {
      final prevKey =
          previousRoute.settings.name ?? 'unknown_${previousRoute.hashCode}';
      DatadogTracingService.instance.startRumView(
        prevKey,
        name: _displayName(prevKey),
      );
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      final oldKey = oldRoute.settings.name ?? 'unknown_${oldRoute.hashCode}';
      DatadogTracingService.instance.stopRumView(oldKey);
    }
    if (newRoute != null) {
      final newKey = newRoute.settings.name ?? 'unknown_${newRoute.hashCode}';
      DatadogTracingService.instance.startRumView(newKey, name: _displayName(newKey));
    }
  }

  String _displayName(String key) {
    if (key.startsWith('/')) {
      return key.substring(1).replaceAll('-', ' ').replaceAll('/', ' / ');
    }
    return key.replaceAll('-', ' ');
  }
}
