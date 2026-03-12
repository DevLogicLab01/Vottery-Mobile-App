import 'package:flutter/material.dart';

class CacheItemCard extends StatelessWidget {
  final String itemType;
  final String itemId;
  final DateTime cachedAt;
  final DateTime? expiresAt;
  final VoidCallback onDelete;

  const CacheItemCard({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.cachedAt,
    this.expiresAt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = expiresAt != null && DateTime.now().isAfter(expiresAt!);

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            _getIconForType(itemType),
            color: isExpired ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(
          itemType,
          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${itemId.substring(0, 8)}...',
              style: TextStyle(fontSize: 11.0, color: Colors.grey),
            ),
            Text(
              'Cached: ${_formatTime(cachedAt)}',
              style: TextStyle(fontSize: 11.0, color: Colors.grey),
            ),
            if (expiresAt != null)
              Text(
                isExpired ? 'Expired' : 'Expires: ${_formatTime(expiresAt!)}',
                style: TextStyle(
                  fontSize: 11.0,
                  color: isExpired ? Colors.red : Colors.grey,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'consensus':
        return Icons.psychology;
      case 'quest':
        return Icons.emoji_events;
      default:
        return Icons.storage;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
