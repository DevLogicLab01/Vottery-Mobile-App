import 'package:flutter/material.dart';

class AccessStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const AccessStatisticsWidget({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    int totalAttempts = 0;
    int totalGranted = 0;
    int totalBlocked = 0;

    statistics.forEach((key, value) {
      totalAttempts += (value['total_attempts'] as int?) ?? 0;
      totalGranted += (value['granted'] as int?) ?? 0;
      totalBlocked += (value['blocked'] as int?) ?? 0;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Global Access Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Attempts',
                totalAttempts.toString(),
                Icons.public,
                Colors.white,
              ),
              _buildStatCard(
                'Granted',
                totalGranted.toString(),
                Icons.check_circle,
                Colors.green[300]!,
              ),
              _buildStatCard(
                'Blocked',
                totalBlocked.toString(),
                Icons.block,
                Colors.red[300]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
