import 'package:flutter/material.dart';

/// YouTube-style: "You're $X away from the payment threshold" / progress bar.
class ThresholdProgressWidget extends StatelessWidget {
  const ThresholdProgressWidget({
    super.key,
    required this.availableBalance,
    required this.threshold,
    required this.amountToThreshold,
    required this.formatCurrency,
  });

  final double availableBalance;
  final double threshold;
  final double amountToThreshold;
  final String Function(double) formatCurrency;

  @override
  Widget build(BuildContext context) {
    final meetsThreshold = availableBalance >= threshold;
    final progress = (availableBalance / threshold).clamp(0.0, 1.0);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payment threshold',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${formatCurrency(threshold)} minimum to get paid',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meetsThreshold
                  ? 'You\'ve reached the threshold. You can request a payout.'
                  : 'You\'re ${formatCurrency(amountToThreshold)} away from the payment threshold.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: meetsThreshold ? Colors.green.shade700 : null,
                    fontWeight: meetsThreshold ? FontWeight.w500 : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
