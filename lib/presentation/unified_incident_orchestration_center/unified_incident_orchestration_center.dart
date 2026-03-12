import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/incident_response_service.dart';
import '../../services/threat_correlation_service.dart';
import '../../services/anomaly_detection_service.dart';
import '../../services/slack_notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class UnifiedIncidentOrchestrationCenter extends StatefulWidget {
  const UnifiedIncidentOrchestrationCenter({super.key});

  @override
  State<UnifiedIncidentOrchestrationCenter> createState() =>
      _UnifiedIncidentOrchestrationCenterState();
}

class _UnifiedIncidentOrchestrationCenterState
    extends State<UnifiedIncidentOrchestrationCenter>
    with SingleTickerProviderStateMixin {
  final IncidentResponseService _incidentService =
      IncidentResponseService.instance;
  final _client = SupabaseService.instance.client;
  final ThreatCorrelationService _threatService =
      ThreatCorrelationService.instance;
  final AnomalyDetectionService _anomalyService =
      AnomalyDetectionService.instance;

  late TabController _tabController;
  List<Map<String, dynamic>> _unifiedIncidents = [];
  List<Map<String, dynamic>> _correlationClusters = [];
  bool _isLoading = true;
  String _selectedTab = 'all';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = [
          'all',
          'performance',
          'security',
          'infrastructure',
          'compliance',
        ][_tabController.index];
      });
      _loadUnifiedIncidents();
    });
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUnifiedIncidents(), _loadCorrelationClusters()]);
  }

  Future<void> _loadUnifiedIncidents() async {
    setState(() => _isLoading = true);

    try {
      final client = SupabaseService.instance.client;

      // Query unified incidents from multiple sources
      final query = '''
        SELECT 
          incident_id,
          incident_type,
          severity,
          title,
          description,
          detected_at,
          source_system,
          affected_resource,
          status
        FROM (
          SELECT 
            incident_id::text,
            'security_incident' as incident_type,
            severity,
            title,
            description,
            detected_at,
            'security' as source_system,
            affected_systems[1] as affected_resource,
            status
          FROM security_incidents
          WHERE detected_at > NOW() - INTERVAL '24 hours'
          
          UNION ALL
          
          SELECT 
            anomaly_id::text as incident_id,
            'performance_anomaly' as incident_type,
            severity,
            'Performance Anomaly: ' || operation_name as title,
            'P95 latency increased from ' || baseline_p95_ms || 'ms to ' || current_p95_ms || 'ms' as description,
            detected_at,
            'performance' as source_system,
            operation_name as affected_resource,
            CASE WHEN acknowledged THEN 'acknowledged' ELSE 'detected' END as status
          FROM performance_anomalies
          WHERE detected_at > NOW() - INTERVAL '24 hours'
          
          UNION ALL
          
          SELECT 
            incident_id::text,
            incident_type,
            severity,
            title,
            description,
            detected_at,
            'incident_response' as source_system,
            affected_systems[1] as affected_resource,
            status
          FROM incidents
          WHERE detected_at > NOW() - INTERVAL '24 hours'
        ) unified_incidents
        ORDER BY detected_at DESC
        LIMIT 100
      ''';

      final response = await client.rpc(
        'execute_raw_sql',
        params: {'query': query},
      );

      List<Map<String, dynamic>> incidents = [];
      if (response is List) {
        incidents = List<Map<String, dynamic>>.from(response);
      }

      // Filter by selected tab
      if (_selectedTab != 'all') {
        incidents = incidents
            .where((i) => i['source_system'] == _selectedTab)
            .toList();
      }

      setState(() {
        _unifiedIncidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load unified incidents error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCorrelationClusters() async {
    try {
      // Run correlation engine
      if (_unifiedIncidents.isNotEmpty) {
        await _runCorrelationEngine();
      }

      final clusters = await _threatService.getIncidentClusters();
      setState(() => _correlationClusters = clusters);
    } catch (e) {
      debugPrint('Load correlation clusters error: $e');
    }
  }

  Future<void> _runCorrelationEngine() async {
    try {
      // Group incidents by 10-minute time windows
      final now = DateTime.now();
      final timeWindows = <DateTime, List<Map<String, dynamic>>>{};

      for (final incident in _unifiedIncidents) {
        final detectedAt = DateTime.parse(incident['detected_at']);
        final windowStart = DateTime(
          detectedAt.year,
          detectedAt.month,
          detectedAt.day,
          detectedAt.hour,
          (detectedAt.minute ~/ 10) * 10,
        );

        if (!timeWindows.containsKey(windowStart)) {
          timeWindows[windowStart] = [];
        }
        timeWindows[windowStart]!.add(incident);
      }

      // Analyze each time window for correlations
      for (final entry in timeWindows.entries) {
        final incidents = entry.value;
        if (incidents.length >= 3) {
          await _analyzeCorrelation(incidents);
        }
      }
    } catch (e) {
      debugPrint('Run correlation engine error: $e');
    }
  }

  Future<void> _analyzeCorrelation(List<Map<String, dynamic>> incidents) async {
    try {
      // Check for common factors
      final affectedResources = incidents
          .map((i) => i['affected_resource'])
          .where((r) => r != null)
          .toSet();

      final severities = incidents.map((i) => i['severity']).toSet();

      // Calculate correlation score
      double correlationScore = 0.0;
      final correlationFactors = <String>[];

      // Same affected resource
      if (affectedResources.length == 1) {
        correlationScore += 0.4;
        correlationFactors.add('same_affected_resource');
      }

      // Similar severity
      if (severities.length <= 2) {
        correlationScore += 0.3;
        correlationFactors.add('similar_severity');
      }

      // Multiple incident types
      final incidentTypes = incidents.map((i) => i['incident_type']).toSet();
      if (incidentTypes.length >= 2) {
        correlationScore += 0.3;
        correlationFactors.add('multiple_incident_types');
      }

      // Create cluster if correlation score is significant
      if (correlationScore >= 0.6) {
        final client = SupabaseService.instance.client;
        await client.from('incident_correlation_clusters').insert({
          'incident_ids': incidents.map((i) => i['incident_id']).toList(),
          'correlation_score': correlationScore,
          'correlation_factors': correlationFactors,
          'cluster_size': incidents.length,
          'detected_at': DateTime.now().toIso8601String(),
          'status': 'active',
        });
      }
    } catch (e) {
      debugPrint('Analyze correlation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Unified Incident Orchestration',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All Incidents'),
              Tab(text: 'Performance'),
              Tab(text: 'Security'),
              Tab(text: 'Infrastructure'),
              Tab(text: 'Compliance'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: Column(
                      children: [
                        if (_correlationClusters.isNotEmpty)
                          _buildCorrelationClustersSection(),
                        Expanded(child: _buildUnifiedIncidentFeed()),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationClustersSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.orange[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_work, color: Colors.orange[700], size: 24.sp),
              SizedBox(width: 2.w),
              Text(
                'Correlated Incident Clusters',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 20.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _correlationClusters.length,
              itemBuilder: (context, index) {
                final cluster = _correlationClusters[index];
                return _buildClusterCard(cluster);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClusterCard(Map<String, dynamic> cluster) {
    final incidentCount = (cluster['incident_ids'] as List).length;
    final correlationScore = cluster['correlation_score'] as double;

    return GestureDetector(
      onTap: () => _showClusterDetails(cluster),
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.orange[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$incidentCount Related Incidents',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getCorrelationColor(correlationScore),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${(correlationScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Correlation Factors:',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 0.5.h),
            Wrap(
              spacing: 1.w,
              children: (cluster['correlation_factors'] as List<dynamic>? ?? [])
                  .map(
                    (factor) => Chip(
                      label: Text(
                        factor.toString().replaceAll('_', ' '),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                      backgroundColor: Colors.orange[100],
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _acknowledgeCluster(cluster['cluster_id']),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Acknowledge All'),
                  style: TextButton.styleFrom(foregroundColor: Colors.green),
                ),
                TextButton.icon(
                  onPressed: () => _createWarRoom(cluster),
                  icon: const Icon(Icons.meeting_room, size: 16),
                  label: const Text('War Room'),
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCorrelationColor(double score) {
    if (score >= 0.8) return Colors.red;
    if (score >= 0.6) return Colors.orange;
    return Colors.yellow[700]!;
  }

  Widget _buildUnifiedIncidentFeed() {
    if (_unifiedIncidents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64.sp, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No incidents in the last 24 hours',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _unifiedIncidents.length,
      itemBuilder: (context, index) {
        final incident = _unifiedIncidents[index];
        return _buildIncidentCard(incident);
      },
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSourceIcon(incident['source_system']),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident['title'] ?? 'Unknown Incident',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        incident['source_system'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSeverityBadge(incident['severity']),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              incident['description'] ?? '',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 14.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  _formatTimestamp(incident['detected_at']),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (incident['affected_resource'] != null)
                  Chip(
                    label: Text(
                      incident['affected_resource'],
                      style: TextStyle(fontSize: 10.sp),
                    ),
                    backgroundColor: Colors.blue[50],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon(String sourceSystem) {
    IconData icon;
    Color color;

    switch (sourceSystem) {
      case 'performance':
        icon = Icons.speed;
        color = Colors.blue;
        break;
      case 'security':
        icon = Icons.security;
        color = Colors.red;
        break;
      case 'infrastructure':
        icon = Icons.dns;
        color = Colors.yellow[700]!;
        break;
      case 'compliance':
        icon = Icons.gavel;
        color = Colors.green;
        break;
      default:
        icon = Icons.error_outline;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20.sp),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'p0':
        color = Colors.red;
        break;
      case 'high':
      case 'p1':
        color = Colors.orange;
        break;
      case 'medium':
      case 'p2':
        color = Colors.yellow[700]!;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showClusterDetails(Map<String, dynamic> cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cluster Details'),
        content: SizedBox(
          width: 80.w,
          height: 60.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Correlation Score: ${(cluster['correlation_score'] * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              Text(
                'Related Incidents:',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Expanded(
                child: ListView.builder(
                  itemCount: (cluster['incident_ids'] as List).length,
                  itemBuilder: (context, index) {
                    final incidentId = cluster['incident_ids'][index];
                    final incident = _unifiedIncidents.firstWhere(
                      (i) => i['incident_id'] == incidentId,
                      orElse: () => {},
                    );

                    if (incident.isEmpty) return const SizedBox.shrink();

                    return Card(
                      child: ListTile(
                        title: Text(
                          incident['title'] ?? 'Unknown',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        subtitle: Text(
                          incident['source_system'].toString().toUpperCase(),
                          style: TextStyle(fontSize: 10.sp),
                        ),
                        trailing: _buildSeverityBadge(incident['severity']),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createWarRoom(cluster);
            },
            child: const Text('Create War Room'),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledgeCluster(String clusterId) async {
    try {
      final cluster = _correlationClusters.firstWhere(
        (c) => c['cluster_id'] == clusterId,
      );

      final incidentIds = cluster['incident_ids'] as List;

      for (final incidentId in incidentIds) {
        await _client
            .from('incidents')
            .update({
              'status': 'acknowledged',
              'acknowledged_at': DateTime.now().toIso8601String(),
            })
            .eq('incident_id', incidentId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Acknowledged ${incidentIds.length} incidents'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createWarRoom(Map<String, dynamic> cluster) async {
    try {
      // Create Slack channel for war room
      await SlackNotificationService.instance.sendIncidentAlert(
        incident: {
          'incident_id': cluster['cluster_id'],
          'title': 'Incident Cluster War Room',
          'description':
              'War room for ${(cluster['incident_ids'] as List).length} correlated incidents',
          'severity': 'high',
          'status': 'active',
          'affected_systems': [],
          'detected_at': DateTime.now().toIso8601String(),
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('War room created in Slack'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
