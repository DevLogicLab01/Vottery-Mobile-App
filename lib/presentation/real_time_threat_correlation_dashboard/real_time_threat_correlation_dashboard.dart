import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/threat_correlation_service.dart';

class RealTimeThreatCorrelationDashboard extends StatefulWidget {
  const RealTimeThreatCorrelationDashboard({super.key});

  @override
  State<RealTimeThreatCorrelationDashboard> createState() =>
      _RealTimeThreatCorrelationDashboardState();
}

class _RealTimeThreatCorrelationDashboardState
    extends State<RealTimeThreatCorrelationDashboard> {
  final ThreatCorrelationService _service = ThreatCorrelationService.instance;
  List<Map<String, dynamic>> _clusters = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  int _activeClusters = 0;
  double _avgConsensusScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _runCorrelationEngine();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clusters = await _service.getIncidentClusters();
      setState(() {
        _clusters = clusters;
        _activeClusters = clusters
            .where((c) => c['status'] != 'resolved')
            .length;
        _avgConsensusScore = clusters.isEmpty
            ? 0.0
            : clusters
                      .map((c) => c['consensus_score'] as double)
                      .reduce((a, b) => a + b) /
                  clusters.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runCorrelationEngine() async {
    try {
      final incidents = await _service.getRecentIncidents();
      if (incidents.isNotEmpty) {
        await _service.clusterIncidents(incidents);
        await _loadData();
      }
    } catch (e) {
      debugPrint('Correlation engine error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Real-Time Threat Correlation'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusOverview(),
                    SizedBox(height: 3.h),
                    _buildCorrelationMetrics(),
                    SizedBox(height: 3.h),
                    _buildClustersList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.red[700], size: 24.sp),
              SizedBox(width: 2.w),
              Text(
                'Threat Correlation Status',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusCard(
                'Active Clusters',
                _activeClusters.toString(),
                Colors.orange,
                Icons.group_work,
              ),
              _buildStatusCard(
                'Avg Consensus',
                '${(_avgConsensusScore * 100).toStringAsFixed(1)}%',
                Colors.blue,
                Icons.analytics,
              ),
              _buildStatusCard(
                'Processing',
                'Real-time',
                Colors.green,
                Icons.sync,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCorrelationMetrics() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correlation Metrics',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem('Clusters Today', _clusters.length.toString()),
              _buildMetricItem('Root Causes', '${_clusters.length}'),
              _buildMetricItem('Prevented', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildClustersList() {
    if (_clusters.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 5.h),
            Icon(Icons.check_circle, size: 48.sp, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No Active Threat Clusters',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incident Clusters',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _clusters.length,
          itemBuilder: (context, index) {
            return _buildClusterCard(_clusters[index]);
          },
        ),
      ],
    );
  }

  Widget _buildClusterCard(Map<String, dynamic> cluster) {
    final consensusScore = (cluster['consensus_score'] as double) * 100;
    final clusterType = cluster['cluster_type'] as String;
    final incidentCount = cluster['incident_count'] as int;
    final affectedSystems = (cluster['affected_systems'] as List)
        .cast<String>();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: consensusScore >= 75 ? Colors.red : Colors.orange,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showClusterDetail(cluster),
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getClusterTypeColor(clusterType),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        clusterType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '$incidentCount related incidents',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consensus Score',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: consensusScore / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    consensusScore >= 75
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                  minHeight: 8.0,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '${consensusScore.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Affected Systems',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: affectedSystems.map((system) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        system,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.blue[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getClusterTypeColor(String type) {
    switch (type) {
      case 'coordinated_attack':
        return Colors.red;
      case 'cascading_failure':
        return Colors.orange;
      case 'anomaly_spike':
        return Colors.purple;
      case 'system_outage':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showClusterDetail(Map<String, dynamic> cluster) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(4.w),
                  children: [
                    Text(
                      'Cluster Analysis',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildDetailSection('Cluster Summary', [
                      'Type: ${cluster['cluster_type']}',
                      'Detection Time: ${cluster['detected_at']}',
                      'Status: ${cluster['status'] ?? 'active'}',
                      'Confidence: ${cluster['confidence_level']}',
                    ]),
                    SizedBox(height: 2.h),
                    _buildDetailSection('Multi-AI Consensus', [
                      'Overall Score: ${((cluster['consensus_score'] as double) * 100).toStringAsFixed(1)}%',
                      'Incident Count: ${cluster['incident_count']}',
                    ]),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Text('• $item', style: TextStyle(fontSize: 13.sp)),
            ),
          ),
        ],
      ),
    );
  }
}
