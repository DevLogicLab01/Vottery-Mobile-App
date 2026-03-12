import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TicketAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const TicketAnalyticsWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalTickets = analytics['total_tickets'] ?? 0;
    final openTickets = analytics['open_tickets'] ?? 0;
    final resolvedTickets = analytics['resolved_tickets'] ?? 0;
    final avgSatisfaction = analytics['avg_satisfaction'] ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Support Statistics',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 3.h),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Total Tickets',
                  totalTickets.toString(),
                  Icons.confirmation_number,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Open',
                  openTickets.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Resolved',
                  resolvedTickets.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  theme,
                  'Satisfaction',
                  avgSatisfaction.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),

          // Resolution Rate
          Text(
            'Resolution Rate',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resolved',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      totalTickets > 0
                          ? '${((resolvedTickets / totalTickets) * 100).toStringAsFixed(1)}%'
                          : '0%',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: LinearProgressIndicator(
                    value: totalTickets > 0
                        ? resolvedTickets / totalTickets
                        : 0,
                    minHeight: 1.5.h,
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Average Satisfaction
          Text(
            'Average Satisfaction Rating',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < avgSatisfaction ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 10.w,
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Tips
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue, size: 6.w),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Check the FAQ section for quick answers to common questions before creating a ticket.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
