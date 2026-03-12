import 'package:flutter/material.dart';

class ShareableBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> badge;

  const ShareableBadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Placeholder for future badge sharing UI enhancements
      child: const SizedBox.shrink(),
    );
  }
}
