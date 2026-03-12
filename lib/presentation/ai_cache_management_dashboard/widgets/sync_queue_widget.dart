import 'package:flutter/material.dart';

class SyncQueueWidget extends StatelessWidget {
  final List<Map<String, dynamic>> pendingRequests;
  final VoidCallback onSync;
  final bool isSyncing;
  final bool isOnline;

  const SyncQueueWidget({
    super.key,
    required this.pendingRequests,
    required this.onSync,
    required this.isSyncing,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80.0, color: Colors.green),
            SizedBox(height: 16.0),
            Text(
              'All synced!',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'No pending requests in queue',
              style: TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.0),
          color: Colors.orange[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20.0),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  '${pendingRequests.length} requests waiting to sync',
                  style: TextStyle(fontSize: 13.0),
                ),
              ),
              if (isOnline)
                ElevatedButton(
                  onPressed: isSyncing ? null : onSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text(
                    isSyncing ? 'Syncing...' : 'Sync Now',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(12.0),
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              return _buildRequestCard(request, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, int index) {
    final functionName = request['function_name'] as String? ?? 'Unknown';
    final timestamp = request['timestamp'] != null
        ? DateTime.parse(request['timestamp'])
        : DateTime.now();

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange[100],
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          functionName,
          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Queued: ${_formatTimestamp(timestamp)}',
          style: TextStyle(fontSize: 12.0, color: Colors.grey),
        ),
        trailing: Icon(Icons.pending, color: Colors.orange, size: 20.0),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
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
