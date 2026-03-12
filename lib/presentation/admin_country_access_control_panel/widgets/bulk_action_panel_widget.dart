import 'package:flutter/material.dart';

class BulkActionPanelWidget extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onEnableAll;
  final VoidCallback onDisableAll;
  final VoidCallback onClearSelection;

  const BulkActionPanelWidget({
    super.key,
    required this.selectedCount,
    required this.onEnableAll,
    required this.onDisableAll,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          top: BorderSide(color: Colors.blue[200]!),
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$selectedCount selected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onEnableAll,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text('Enable All'),
            style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onDisableAll,
            icon: const Icon(Icons.block, color: Colors.red),
            label: const Text('Disable All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClearSelection,
            icon: const Icon(Icons.close),
            tooltip: 'Clear Selection',
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
