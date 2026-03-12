import 'package:flutter/material.dart';
import '../services/platform_feature_toggle_service.dart';

/// Gates a screen by platform feature toggle. If the feature is disabled in the admin panel,
/// shows a "Feature not available" message; otherwise builds [child].
class FeatureGateWidget extends StatelessWidget {
  const FeatureGateWidget({
    super.key,
    required this.featureKey,
    required this.child,
    this.redirectTo,
  });

  final String featureKey;
  final Widget child;
  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PlatformFeatureToggleService.instance.isFeatureEnabled(featureKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return child;
        return _FeatureDisabledPage(
          onTap: redirectTo != null
              ? () => Navigator.of(context).pushReplacementNamed(redirectTo!)
              : () => Navigator.of(context).maybePop(),
        );
      },
    );
  }
}

class _FeatureDisabledPage extends StatelessWidget {
  const _FeatureDisabledPage({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_off_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Feature not available',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This feature is currently turned off by the platform.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onTap, child: const Text('Go back')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
