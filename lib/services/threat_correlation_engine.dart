import 'dart:math';

class ThreatCorrelationEngine {
  static final ThreatCorrelationEngine _instance =
      ThreatCorrelationEngine._internal();
  factory ThreatCorrelationEngine() => _instance;
  ThreatCorrelationEngine._internal();

  static const int _timeWindowMinutes = 10;

  /// Find temporal correlations (events within time window)
  List<Map<String, dynamic>> findTemporalCorrelations(
    List<Map<String, dynamic>> logs,
  ) {
    final correlations = <Map<String, dynamic>>[];

    // Sort logs by timestamp
    final sortedLogs = List<Map<String, dynamic>>.from(logs)
      ..sort(
        (a, b) => DateTime.parse(
          a['timestamp'],
        ).compareTo(DateTime.parse(b['timestamp'])),
      );

    // Find events within time window
    for (var i = 0; i < sortedLogs.length; i++) {
      final currentLog = sortedLogs[i];
      final currentTime = DateTime.parse(currentLog['timestamp']);
      final relatedEvents = <Map<String, dynamic>>[];

      for (var j = i + 1; j < sortedLogs.length; j++) {
        final nextLog = sortedLogs[j];
        final nextTime = DateTime.parse(nextLog['timestamp']);
        final timeDiff = nextTime.difference(currentTime);

        if (timeDiff.inMinutes > _timeWindowMinutes) break;

        // Check for common attributes
        final commonAttributes = _findCommonAttributes(currentLog, nextLog);
        if (commonAttributes.isNotEmpty) {
          relatedEvents.add(nextLog);
        }
      }

      if (relatedEvents.length >= 2) {
        correlations.add({
          'correlation_type': 'temporal',
          'related_events': [
            currentLog['log_id'],
            ...relatedEvents.map((e) => e['log_id']),
          ],
          'attack_vector': 'Time-based coordinated activity',
          'timeline': 'Events occurred within $_timeWindowMinutes minutes',
          'common_attributes': _findCommonAttributes(
            currentLog,
            relatedEvents.first,
          ),
          'correlation_strength': _calculateCorrelationStrength(
            currentLog,
            relatedEvents,
          ),
        });
      }
    }

    return correlations;
  }

  /// Find spatial correlations (IP geolocation proximity)
  List<Map<String, dynamic>> findSpatialCorrelations(
    List<Map<String, dynamic>> logs,
  ) {
    final correlations = <Map<String, dynamic>>[];

    // Group by IP address
    final ipGroups = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final ipAddress = log['ip_address'] as String?;
      if (ipAddress != null) {
        ipGroups.putIfAbsent(ipAddress, () => []).add(log);
      }
    }

    // Find IP groups with multiple users (distributed attack)
    for (final entry in ipGroups.entries) {
      final ipAddress = entry.key;
      final events = entry.value;
      final uniqueUsers = events.map((e) => e['user_id']).toSet();

      if (uniqueUsers.length >= 3) {
        correlations.add({
          'correlation_type': 'spatial',
          'related_events': events.map((e) => e['log_id']).toList(),
          'attack_vector': 'Distributed attack from single IP',
          'timeline': 'Multiple users from IP: $ipAddress',
          'ip_address': ipAddress,
          'unique_users': uniqueUsers.length,
          'correlation_strength': 0.8,
        });
      }
    }

    // Check for IP subnet matching (e.g., 192.168.1.x)
    final subnetGroups = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final ipAddress = log['ip_address'] as String?;
      if (ipAddress != null) {
        final subnet = _getSubnet(ipAddress);
        subnetGroups.putIfAbsent(subnet, () => []).add(log);
      }
    }

    for (final entry in subnetGroups.entries) {
      final subnet = entry.key;
      final events = entry.value;
      final uniqueIPs = events.map((e) => e['ip_address']).toSet();

      if (uniqueIPs.length >= 5) {
        correlations.add({
          'correlation_type': 'spatial',
          'related_events': events.map((e) => e['log_id']).toList(),
          'attack_vector': 'Coordinated attack from subnet',
          'timeline': 'Multiple IPs from subnet: $subnet',
          'subnet': subnet,
          'unique_ips': uniqueIPs.length,
          'correlation_strength': 0.75,
        });
      }
    }

    return correlations;
  }

  /// Find behavioral correlations (action patterns)
  List<Map<String, dynamic>> findBehavioralCorrelations(
    List<Map<String, dynamic>> logs,
  ) {
    final correlations = <Map<String, dynamic>>[];

    // Define attack signatures (ordered action sequences)
    final attackSignatures = [
      {
        'name': 'Account Takeover Sequence',
        'pattern': ['failed_login', 'password_reset', 'login'],
        'severity': 'critical',
      },
      {
        'name': 'Data Exfiltration Sequence',
        'pattern': ['login', 'data_access', 'data_export'],
        'severity': 'high',
      },
      {
        'name': 'Payment Fraud Sequence',
        'pattern': ['payment_failed', 'payment_failed', 'payment_success'],
        'severity': 'high',
      },
    ];

    // Group logs by user
    final userLogs = <String, List<Map<String, dynamic>>>{};
    for (final log in logs) {
      final userId = log['user_id'] as String?;
      if (userId != null) {
        userLogs.putIfAbsent(userId, () => []).add(log);
      }
    }

    // Check each user's action sequence against attack signatures
    for (final entry in userLogs.entries) {
      final userId = entry.key;
      final events = entry.value
        ..sort(
          (a, b) => DateTime.parse(
            a['timestamp'],
          ).compareTo(DateTime.parse(b['timestamp'])),
        );

      final actionSequence = events.map((e) => e['action'] as String).toList();

      for (final signature in attackSignatures) {
        final pattern = signature['pattern'] as List<String>;
        final matches = _findSequenceMatches(actionSequence, pattern);

        if (matches.isNotEmpty) {
          correlations.add({
            'correlation_type': 'behavioral',
            'related_events': events.map((e) => e['log_id']).toList(),
            'attack_vector': signature['name'],
            'timeline': 'Attack sequence detected: ${pattern.join(" → ")}',
            'severity': signature['severity'],
            'correlation_strength': 0.9,
            'affected_user': userId,
          });
        }
      }
    }

    return correlations;
  }

  /// Build event graph with nodes and edges
  Map<String, dynamic> buildEventGraph(List<Map<String, dynamic>> logs) {
    final nodes = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];

    // Create nodes for each event
    for (final log in logs) {
      nodes.add({
        'id': log['log_id'],
        'type': log['event_type'],
        'timestamp': log['timestamp'],
        'user_id': log['user_id'],
        'ip_address': log['ip_address'],
        'action': log['action'],
        'severity': log['severity'],
      });
    }

    // Create edges based on correlations
    for (var i = 0; i < logs.length; i++) {
      for (var j = i + 1; j < logs.length; j++) {
        final log1 = logs[i];
        final log2 = logs[j];

        final correlationType = _determineCorrelationType(log1, log2);
        if (correlationType != null) {
          final strength = _calculateEdgeStrength(log1, log2);

          edges.add({
            'source': log1['log_id'],
            'target': log2['log_id'],
            'correlation_type': correlationType,
            'strength': strength,
          });
        }
      }
    }

    return {
      'nodes': nodes,
      'edges': edges,
      'node_count': nodes.length,
      'edge_count': edges.length,
    };
  }

  /// Find connected components (attack clusters)
  List<List<String>> findConnectedComponents(Map<String, dynamic> graph) {
    final nodes = graph['nodes'] as List<Map<String, dynamic>>;
    final edges = graph['edges'] as List<Map<String, dynamic>>;

    // Build adjacency list
    final adjacency = <String, Set<String>>{};
    for (final node in nodes) {
      adjacency[node['id']] = {};
    }
    for (final edge in edges) {
      final source = edge['source'] as String;
      final target = edge['target'] as String;
      adjacency[source]!.add(target);
      adjacency[target]!.add(source);
    }

    // Find connected components using DFS
    final visited = <String>{};
    final components = <List<String>>[];

    for (final nodeId in adjacency.keys) {
      if (!visited.contains(nodeId)) {
        final component = <String>[];
        _dfs(nodeId, adjacency, visited, component);
        if (component.length > 1) {
          components.add(component);
        }
      }
    }

    return components;
  }

  /// Find critical paths (likely attack progression)
  List<List<String>> findCriticalPaths(
    Map<String, dynamic> graph,
    int maxPathLength,
  ) {
    final nodes = graph['nodes'] as List<Map<String, dynamic>>;
    final edges = graph['edges'] as List<Map<String, dynamic>>;

    // Build directed adjacency list (temporal ordering)
    final adjacency = <String, List<String>>{};
    for (final node in nodes) {
      adjacency[node['id']] = [];
    }
    for (final edge in edges) {
      final source = edge['source'] as String;
      final target = edge['target'] as String;
      adjacency[source]!.add(target);
    }

    // Find all paths up to maxPathLength
    final paths = <List<String>>[];
    for (final startNode in adjacency.keys) {
      _findPaths(startNode, adjacency, [], paths, maxPathLength);
    }

    // Sort by path length (longer paths are more critical)
    paths.sort((a, b) => b.length.compareTo(a.length));

    return paths.take(10).toList(); // Return top 10 critical paths
  }

  /// Calculate centrality measures (identify key events)
  Map<String, double> calculateCentrality(Map<String, dynamic> graph) {
    final nodes = graph['nodes'] as List<Map<String, dynamic>>;
    final edges = graph['edges'] as List<Map<String, dynamic>>;

    final centrality = <String, double>{};

    // Calculate degree centrality (number of connections)
    final degrees = <String, int>{};
    for (final node in nodes) {
      degrees[node['id']] = 0;
    }
    for (final edge in edges) {
      degrees[edge['source'] as String] = (degrees[edge['source']] ?? 0) + 1;
      degrees[edge['target'] as String] = (degrees[edge['target']] ?? 0) + 1;
    }

    // Normalize centrality scores
    final maxDegree = degrees.values.isEmpty ? 1 : degrees.values.reduce(max);
    for (final entry in degrees.entries) {
      centrality[entry.key] = entry.value / maxDegree;
    }

    return centrality;
  }

  /// Helper: Find common attributes between logs
  List<String> _findCommonAttributes(
    Map<String, dynamic> log1,
    Map<String, dynamic> log2,
  ) {
    final common = <String>[];

    if (log1['user_id'] == log2['user_id'] && log1['user_id'] != null) {
      common.add('same_user');
    }
    if (log1['ip_address'] == log2['ip_address'] &&
        log1['ip_address'] != null) {
      common.add('same_ip');
    }
    if (log1['event_type'] == log2['event_type']) {
      common.add('same_event_type');
    }

    return common;
  }

  /// Helper: Calculate correlation strength
  double _calculateCorrelationStrength(
    Map<String, dynamic> log,
    List<Map<String, dynamic>> relatedLogs,
  ) {
    var strength = 0.0;

    for (final related in relatedLogs) {
      final commonAttrs = _findCommonAttributes(log, related);
      strength += commonAttrs.length * 0.2;
    }

    return (strength / relatedLogs.length).clamp(0.0, 1.0);
  }

  /// Helper: Get subnet from IP address
  String _getSubnet(String ipAddress) {
    final parts = ipAddress.split('.');
    if (parts.length >= 3) {
      return '${parts[0]}.${parts[1]}.${parts[2]}.x';
    }
    return ipAddress;
  }

  /// Helper: Find sequence matches
  List<int> _findSequenceMatches(List<String> sequence, List<String> pattern) {
    final matches = <int>[];

    for (var i = 0; i <= sequence.length - pattern.length; i++) {
      var match = true;
      for (var j = 0; j < pattern.length; j++) {
        if (sequence[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) matches.add(i);
    }

    return matches;
  }

  /// Helper: Determine correlation type between two logs
  String? _determineCorrelationType(
    Map<String, dynamic> log1,
    Map<String, dynamic> log2,
  ) {
    final time1 = DateTime.parse(log1['timestamp']);
    final time2 = DateTime.parse(log2['timestamp']);
    final timeDiff = time2.difference(time1).abs();

    if (timeDiff.inMinutes <= _timeWindowMinutes) {
      if (log1['user_id'] == log2['user_id']) return 'same_user';
      if (log1['ip_address'] == log2['ip_address']) return 'same_ip';
      return 'temporal';
    }

    return null;
  }

  /// Helper: Calculate edge strength
  double _calculateEdgeStrength(
    Map<String, dynamic> log1,
    Map<String, dynamic> log2,
  ) {
    final commonAttrs = _findCommonAttributes(log1, log2);
    return (commonAttrs.length * 0.3).clamp(0.0, 1.0);
  }

  /// Helper: Depth-first search for connected components
  void _dfs(
    String nodeId,
    Map<String, Set<String>> adjacency,
    Set<String> visited,
    List<String> component,
  ) {
    visited.add(nodeId);
    component.add(nodeId);

    for (final neighbor in adjacency[nodeId]!) {
      if (!visited.contains(neighbor)) {
        _dfs(neighbor, adjacency, visited, component);
      }
    }
  }

  /// Helper: Find all paths up to max length
  void _findPaths(
    String currentNode,
    Map<String, List<String>> adjacency,
    List<String> currentPath,
    List<List<String>> allPaths,
    int maxLength,
  ) {
    currentPath.add(currentNode);

    if (currentPath.length >= 2) {
      allPaths.add(List.from(currentPath));
    }

    if (currentPath.length < maxLength) {
      for (final neighbor in adjacency[currentNode]!) {
        if (!currentPath.contains(neighbor)) {
          _findPaths(neighbor, adjacency, currentPath, allPaths, maxLength);
        }
      }
    }

    currentPath.removeLast();
  }
}
