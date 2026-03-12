import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceMetricsGridWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const PerformanceMetricsGridWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'title': 'Active Creators',
        'value': metrics['active_creators']?.toString() ?? '1,247',
        'trend': '+42',
        'trendUp': true,
        'icon': Icons.people,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Avg Engagement',
        'value': metrics['avg_engagement']?.toString() ?? '8.4%',
        'trend': '+1.2%',
        'trendUp': true,
        'icon': Icons.trending_up,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Posts/Week',
        'value': metrics['avg_posting_freq']?.toString() ?? '3.2',
        'trend': '-0.3',
        'trendUp': false,
        'icon': Icons.post_add,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Total VP Earned',
        'value': metrics['total_vp']?.toString() ?? '284K',
        'trend': '+12K',
        'trendUp': true,
        'icon': Icons.monetization_on,
        'color': const Color(0xFF8B5CF6),
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final color = card['color'] as Color;
        final trendUp = card['trendUp'] as bool;
        return Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(card['icon'] as IconData, color: color, size: 20),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: trendUp
                          ? const Color(0xFF10B981).withAlpha(26)
                          : const Color(0xFFEF4444).withAlpha(26),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 10,
                          color: trendUp
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        Text(
                          card['trend'] as String,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: trendUp
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['value'] as String,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    card['title'] as String,
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
