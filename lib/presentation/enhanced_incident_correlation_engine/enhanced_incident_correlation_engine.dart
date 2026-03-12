import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/multi_ai_orchestration_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class EnhancedIncidentCorrelationEngine extends StatefulWidget {
  const EnhancedIncidentCorrelationEngine({super.key});

  @override
  State<EnhancedIncidentCorrelationEngine> createState() =>
      _EnhancedIncidentCorrelationEngineState();
}

class _EnhancedIncidentCorrelationEngineState
    extends State<EnhancedIncidentCorrelationEngine> {
  final MultiAIOrchestrationService _aiOrchestrator =
      MultiAIOrchestrationService.instance;
  final AuthService _auth = AuthService.instance;
  final _client = SupabaseService.instance.client;

  bool _isLoading = false;
  List<Map<String, dynamic>> _incidentClusters = [];
  List<Map<String, dynamic>> _correlatedIncidents = [];
  Map<String, dynamic>? _rootCauseAnalysis;
  final String _selectedCluster = '';

  @override
  void initState() {
    super.initState();
    _loadIncidentData();
  }

  Future<void> _loadIncidentData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final clusters = await _client
          .from('incident_clusters')
          .select()
          .order('created_at', ascending: false)
          .limit(20);

      final correlated = await _client
          .from('correlated_incidents')
          .select()
          .order('correlation_confidence', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _incidentClusters = List<Map<String, dynamic>>.from(clusters ?? []);
          _correlatedIncidents = List<Map<String, dynamic>>.from(
            correlated ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load incident data error: $e');
      if (mounted) {
        setState(() {
          _incidentClusters = _getMockClusters();
          _correlatedIncidents = _getMockCorrelatedIncidents();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockClusters() {
    return [
      {
        'id': '1',
        'cluster_name': 'Payment Processing Anomaly',
        'incident_count': 5,
        'avg_confidence': 92.5,
        'severity': 'high',
        'status': 'active',
      },
      {
        'id': '2',
        'cluster_name': 'Fraud Detection Spike',
        'incident_count': 3,
        'avg_confidence': 87.0,
        'severity': 'medium',
        'status': 'investigating',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockCorrelatedIncidents() {
    return [
      {
        'id': '1',
        'type': 'fraud_alert',
        'related_type': 'revenue_anomaly',
        'correlation_confidence': 95.0,
        'description': 'Suspicious voting pattern detected',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': '2',
        'type': 'system_failure',
        'related_type': 'fraud_alert',
        'correlation_confidence': 88.0,
        'description': 'Database connection timeout',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      },
    ];
  }

  Future<void> _performRootCauseAnalysis(String clusterId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final analysis = await _client.rpc(
        'perform_root_cause_analysis',
        params: {'cluster_id': clusterId},
      );

      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _rootCauseAnalysis = analysis);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _executeRemediationPlaybook(String clusterId) async {
    try {
      await _client.rpc(
        'execute_remediation_playbook',
        params: {'cluster_id': clusterId},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Remediation playbook executed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadIncidentData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remediation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Correlation Engine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidentData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusOverview(),
                  SizedBox(height: 2.h),
                  _buildIncidentClusters(),
                  SizedBox(height: 2.h),
                  _buildCorrelatedIncidents(),
                  if (_rootCauseAnalysis != null) ...[
                    SizedBox(height: 2.h),
                    _buildRootCauseAnalysis(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusOverview() {
    final activeCount = _incidentClusters
        .where((c) => c['status'] == 'active')
        .length;
    final avgConfidence = _correlatedIncidents.isNotEmpty
        ? _correlatedIncidents
                  .map((i) => (i['correlation_confidence'] ?? 0.0).toDouble())
                  .reduce((a, b) => a + b) /
              _correlatedIncidents.length
        : 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correlation Status Overview',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Active Clusters',
                    activeCount.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatusCard(
                    'Avg Confidence',
                    '${avgConfidence.toStringAsFixed(1)}%',
                    Icons.analytics,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatusCard(
                    'Total Incidents',
                    _correlatedIncidents.length.toString(),
                    Icons.list,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 9.sp, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentClusters() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Clusters',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.5.h),
            if (_incidentClusters.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(4.h),
                  child: Text(
                    'No active incident clusters',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._incidentClusters.map((cluster) {
                return _buildClusterCard(cluster);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterCard(Map<String, dynamic> cluster) {
    final name = cluster['cluster_name'] ?? 'Unknown Cluster';
    final count = cluster['incident_count'] ?? 0;
    final confidence = (cluster['avg_confidence'] ?? 0.0).toDouble();
    final severity = cluster['severity'] ?? 'low';
    final status = cluster['status'] ?? 'unknown';

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(2.5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSeverityBadge(severity),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.link, size: 14.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  '$count linked incidents',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
                SizedBox(width: 3.w),
                Icon(Icons.analytics, size: 14.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  '${confidence.toStringAsFixed(0)}% confidence',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _performRootCauseAnalysis(cluster['id']),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Analyze'),
                    style: OutlinedButton.styleFrom(minimumSize: Size(0, 4.h)),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _executeRemediationPlaybook(cluster['id']),
                    icon: const Icon(Icons.build, size: 16),
                    label: const Text('Remediate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(0, 4.h),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCorrelatedIncidents() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correlated Incidents',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.5.h),
            if (_correlatedIncidents.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(4.h),
                  child: Text(
                    'No correlated incidents found',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ),
              )
            else
              ..._correlatedIncidents.take(10).map((incident) {
                return _buildIncidentCard(incident);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    final type = incident['type'] ?? 'unknown';
    final relatedType = incident['related_type'] ?? 'unknown';
    final confidence = (incident['correlation_confidence'] ?? 0.0).toDouble();
    final description = incident['description'] ?? 'No description';

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          children: [
            Container(
              width: 1.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: _getIncidentTypeColor(type),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatIncidentType(type),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 12.sp),
                      Text(
                        _formatIncidentType(relatedType),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Confidence: ${confidence.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootCauseAnalysis() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Root Cause Analysis',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              _rootCauseAnalysis!['primary_cause'] ?? 'Unknown cause',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 1.h),
            Text(
              _rootCauseAnalysis!['analysis'] ?? 'No analysis available',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIncidentTypeColor(String type) {
    switch (type) {
      case 'fraud_alert':
        return Colors.red;
      case 'system_failure':
        return Colors.orange;
      case 'revenue_anomaly':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatIncidentType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
