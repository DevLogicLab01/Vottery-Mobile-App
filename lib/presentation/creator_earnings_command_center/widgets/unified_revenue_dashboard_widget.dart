import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class UnifiedRevenueDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> earningsSummary;
  final List<Map<String, dynamic>> revenueBreakdown;
  final bool showDetailed;

  const UnifiedRevenueDashboardWidget({
    super.key,
    required this.earningsSummary,
    required this.revenueBreakdown,
    this.showDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unified Revenue Dashboard',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.trending_up, color: Colors.green, size: 20.sp),
            ],
          ),
          SizedBox(height: 2.h),
          _buildRevenueGrid(context),
          if (showDetailed) ...[
            SizedBox(height: 2.h),
            _buildRevenueChart(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueGrid(BuildContext context) {
    final streams = [
      {
        'label': 'Election Fees',
        'amount': earningsSummary['election_fees'] ?? 0.0,
        'icon': Icons.how_to_vote,
        'color': Colors.blue,
      },
      {
        'label': 'Marketplace',
        'amount': earningsSummary['marketplace_revenue'] ?? 0.0,
        'icon': Icons.store,
        'color': Colors.purple,
      },
      {
        'label': 'Partnerships',
        'amount': earningsSummary['partnership_revenue'] ?? 0.0,
        'icon': Icons.handshake,
        'color': Colors.orange,
      },
      {
        'label': 'Subscriptions',
        'amount': earningsSummary['subscription_revenue'] ?? 0.0,
        'icon': Icons.card_membership,
        'color': Colors.green,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 1.5,
      ),
      itemCount: streams.length,
      itemBuilder: (context, index) {
        final stream = streams[index];
        return _buildRevenueCard(
          context,
          stream['label'] as String,
          stream['amount'] as double,
          stream['icon'] as IconData,
          stream['color'] as Color,
        );
      },
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.green, size: 10.sp),
                    Text(
                      '12%',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
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
                label,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
              SizedBox(height: 0.5.h),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    if (revenueBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Distribution',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 25.h,
          child: PieChart(
            PieChartData(
              sections: _buildPieChartSections(),
              centerSpaceRadius: 40.0,
              sectionsSpace: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green];
    final total =
        (earningsSummary['election_fees'] ?? 0.0) +
        (earningsSummary['marketplace_revenue'] ?? 0.0) +
        (earningsSummary['partnership_revenue'] ?? 0.0) +
        (earningsSummary['subscription_revenue'] ?? 0.0);

    if (total == 0) return [];

    final values = [
      earningsSummary['election_fees'] ?? 0.0,
      earningsSummary['marketplace_revenue'] ?? 0.0,
      earningsSummary['partnership_revenue'] ?? 0.0,
      earningsSummary['subscription_revenue'] ?? 0.0,
    ];

    return List.generate(values.length, (index) {
      final percentage = (values[index] / total) * 100;
      return PieChartSectionData(
        value: values[index],
        title: '${percentage.toStringAsFixed(1)}%',
        color: colors[index],
        radius: 50.0,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
}
