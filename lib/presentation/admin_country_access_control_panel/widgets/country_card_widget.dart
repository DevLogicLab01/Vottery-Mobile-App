import 'package:flutter/material.dart';

class CountryCardWidget extends StatelessWidget {
  final Map<String, dynamic> country;
  final Map<String, dynamic>? statistics;
  final bool isSelected;
  final Function(bool) onToggle;
  final Function(bool) onSelect;

  const CountryCardWidget({
    super.key,
    required this.country,
    this.statistics,
    required this.isSelected,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = country['is_enabled'] ?? true;
    final countryCode = country['country_code'] as String;
    final countryName = country['country_name'] as String;
    final feeZone = country['fee_zone'] ?? 1;
    final complianceLevel = country['compliance_level'] ?? 'moderate';
    final blockedReason = country['blocked_reason'];

    final totalAttempts = statistics?['total_attempts'] ?? 0;
    final grantedAttempts = statistics?['granted'] ?? 0;
    final blockedAttempts = statistics?['blocked'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Selection Checkbox
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelect(value ?? false),
                ),

                // Country Flag Emoji
                Text(
                  _getCountryFlag(countryCode),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),

                // Country Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              countryCode,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Zone $feeZone',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getComplianceColor(complianceLevel),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              complianceLevel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Enable/Disable Toggle
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeThumbColor: Colors.green,
                ),
              ],
            ),

            // Statistics (if available)
            if (totalAttempts > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total',
                    totalAttempts.toString(),
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Granted',
                    grantedAttempts.toString(),
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Blocked',
                    blockedAttempts.toString(),
                    Colors.red,
                  ),
                ],
              ),
            ],

            // Blocked Reason (if disabled)
            if (!isEnabled && blockedReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        blockedReason,
                        style: TextStyle(fontSize: 12, color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getComplianceColor(String level) {
    switch (level) {
      case 'strict':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'relaxed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getCountryFlag(String countryCode) {
    // Convert country code to flag emoji
    final codePoints = countryCode.toUpperCase().codeUnits;
    return String.fromCharCodes(codePoints.map((c) => 0x1F1E6 + (c - 0x41)));
  }
}
