import 'package:flutter/material.dart';

class ConnectivityBannerWidget extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback onSyncPressed;

  const ConnectivityBannerWidget({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.blue.withAlpha(51)
            : Colors.orange.withAlpha(51),
        border: Border(
          bottom: BorderSide(
            color: isOnline ? Colors.blue : Colors.orange,
            width: 2.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.sync : Icons.cloud_off,
            color: isOnline ? Colors.blue : Colors.orange,
            size: 16.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnline ? 'Sync Available' : 'You\'re offline',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: isOnline ? Colors.blue[800] : Colors.orange[800],
                  ),
                ),
                if (pendingCount > 0)
                  Text(
                    '$pendingCount ${pendingCount == 1 ? 'vote' : 'votes'} pending sync',
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isOnline ? Colors.blue[700] : Colors.orange[700],
                    ),
                  ),
                if (!isOnline)
                  Text(
                    'Votes will sync automatically when online',
                    style: TextStyle(fontSize: 10.0, color: Colors.orange[700]),
                  ),
              ],
            ),
          ),
          if (isOnline && pendingCount > 0)
            TextButton(
              onPressed: onSyncPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
              ),
              child: const Text(
                'Sync Now',
                style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
