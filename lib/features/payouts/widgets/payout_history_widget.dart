import 'package:flutter/material.dart';

/// YouTube-style: List of payments – date, amount, status.
class PayoutHistoryWidget extends StatelessWidget {
  const PayoutHistoryWidget({
    super.key,
    required this.history,
    required this.formatCurrency,
  });

  final List<Map<String, dynamic>> history;
  final String Function(double, [String]) formatCurrency;

  static String _formatDate(dynamic d) {
    if (d == null) return '';
    final dt = d is DateTime ? d : DateTime.tryParse(d.toString());
    if (dt == null) return d.toString();
    return '${_month(dt.month)} ${dt.day}, ${dt.year}';
  }

  static String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment history',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No payments yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...history.take(12).map((item) {
                final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                final status = item['status'] as String? ?? 'pending';
                final createdAt = item['created_at'];
                Color statusColor = Colors.amber;
                if (status == 'completed') statusColor = Colors.green;
                if (status == 'failed') statusColor = Colors.red;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatCurrency(amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatDate(createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
