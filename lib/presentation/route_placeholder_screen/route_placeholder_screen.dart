import 'package:flutter/material.dart';

/// Placeholder screen shown when a route is not yet fully implemented.
/// Used by the route registry for any AppRoutes that do not yet have
/// a dedicated screen widget.
class RoutePlaceholderScreen extends StatelessWidget {
  final String routeName;
  final String title;

  const RoutePlaceholderScreen({
    super.key,
    required this.routeName,
    String? title,
  }) : title = title ?? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'This screen is not fully implemented yet.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Route: $routeName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
