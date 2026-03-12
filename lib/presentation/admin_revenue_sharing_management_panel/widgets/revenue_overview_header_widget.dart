import 'package:flutter/material.dart';

class RevenueOverviewHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const RevenueOverviewHeaderWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final totalCountries = metrics['total_countries_configured'] ?? 0;
    final avgPlatformPercentage =
        (metrics['average_platform_percentage'] as num? ?? 0.0).toDouble();
    final pendingChanges = metrics['pending_split_changes'] ?? 0;

    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Revenue Split Overview',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  icon: Icons.public,
                  label: 'Countries Configured',
                  value: totalCountries.toString(),
                  color: Colors.white,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  icon: Icons.percent,
                  label: 'Avg Platform %',
                  value: '${avgPlatformPercentage.toStringAsFixed(1)}%',
                  color: Colors.white,
                ),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.03),
              Expanded(
                child: _buildMetricCard(
                  context: context,
                  icon: Icons.pending_actions,
                  label: 'Pending Changes',
                  value: pendingChanges.toString(),
                  color: pendingChanges > 0 ? Colors.orange : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: MediaQuery.of(context).size.width * 0.06,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.005),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.025,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }
}
