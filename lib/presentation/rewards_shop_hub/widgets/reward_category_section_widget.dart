import 'package:flutter/material.dart';

// Placeholder widget for future category section implementation
class RewardCategorySectionWidget extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> rewards;

  const RewardCategorySectionWidget({
    super.key,
    required this.category,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
