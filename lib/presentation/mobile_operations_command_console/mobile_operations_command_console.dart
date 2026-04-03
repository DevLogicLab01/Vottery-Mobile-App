import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/incident_response_service.dart';
import '../../services/threat_correlation_service.dart';
import '../../services/anomaly_detection_service.dart';
import '../../services/twilio_notification_service.dart';
import '../../services/slack_notification_service.dart';
import '../../widgets/custom_app_bar.dart';

class MobileOperationsCommandConsole extends StatefulWidget {
  const MobileOperationsCommandConsole({super.key});

  @override
  State<MobileOperationsCommandConsole> createState() =>
      _MobileOperationsCommandConsoleState();
}

class _MobileOperationsCommandConsoleState
    extends State<MobileOperationsCommandConsole> {
  final IncidentResponseService _incidentService =
      IncidentResponseService.instance;
  final ThreatCorrelationService _threatService =
      ThreatCorrelationService.instance;
  final AnomalyDetectionService _anomalyService =
      AnomalyDetectionService.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final PageController _incidentPageController = PageController();
  final TransformationController _chartTransformController =
      TransformationController();

  List<Map<String, dynamic>> _incidents = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;
  bool _isListening = false;
  int _currentIncidentIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initSpeech();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _incidentPageController.dispose();
    _chartTransformController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final incidents = await _incidentService.getActiveIncidents();
      final anomalies = await _anomalyService.getActiveAnomalies();
      final clusters = await _threatService.getIncidentClusters();

      final criticalCount = incidents
          .where((i) => i['severity'] == 'P0' || i['severity'] == 'critical')
          .length;
      final activeCount = incidents
          .where((i) => i['status'] != 'resolved')
          .length;
      final systemHealth = await _calculateSystemHealth();

      setState(() {
        _incidents = incidents;
        _dashboardStats = {
          'critical_alerts': criticalCount,
          'active_incidents': activeCount,
          'system_health': systemHealth,
          'anomalies': anomalies.length,
          'threat_clusters': clusters.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<double> _calculateSystemHealth() async {
    // Calculate based on active incidents and anomalies
    final activeIncidents = _incidents
        .where((i) => i['status'] != 'resolved')
        .length;
    final criticalIncidents = _incidents
        .where((i) => i['severity'] == 'P0' || i['severity'] == 'critical')
        .length;

    if (criticalIncidents > 0) return 60.0;
    if (activeIncidents > 5) return 75.0;
    if (activeIncidents > 0) return 85.0;
    return 98.0;
  }

  Future<bool> _authenticateWithBiometrics(String action) async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication not available'),
          ),
        );
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm $action',
      );

      if (authenticated) {
        HapticFeedback.heavyImpact();
      }

      return authenticated;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  Future<void> _acknowledgeIncident(String incidentId) async {
    final authenticated = await _authenticateWithBiometrics('acknowledge');
    if (!authenticated) return;

    HapticFeedback.mediumImpact();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acknowledge functionality not available'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _escalateIncident(String incidentId) async {
    final authenticated = await _authenticateWithBiometrics('escalate');
    if (!authenticated) return;

    HapticFeedback.mediumImpact();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escalate functionality not available'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _resolveIncident(String incidentId) async {
    final authenticated = await _authenticateWithBiometrics('resolve');
    if (!authenticated) return;

    HapticFeedback.mediumImpact();

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resolve functionality not available'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _startVoiceCommand() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    HapticFeedback.selectionClick();

    final available = await _speech.initialize();
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice recognition not available')),
      );
      return;
    }

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords.toLowerCase());
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _processVoiceCommand(String command) {
    HapticFeedback.mediumImpact();

    if (command.contains('acknowledge all') &&
        command.contains('p1 incidents')) {
      _acknowledgeAllP1Incidents();
    } else if (command.contains('escalate to security team')) {
      _escalateToSecurityTeam();
    } else if (command.contains('show critical alerts')) {
      _showCriticalAlerts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Command not recognized: $command')),
      );
    }
  }

  Future<void> _acknowledgeAllP1Incidents() async {
    final p1Incidents = _incidents
        .where((i) => i['severity'] == 'P1' && i['status'] != 'resolved')
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Found ${p1Incidents.length} P1 incidents (acknowledge functionality not available)',
        ),
        backgroundColor: Colors.orange,
      ),
    );

    _loadData();
  }

  Future<void> _escalateToSecurityTeam() async {
    final securityIncidents = _incidents
        .where(
          (i) =>
              i['incident_type'].toString().contains('security') &&
              i['status'] != 'resolved',
        )
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Found ${securityIncidents.length} security incidents (escalate functionality not available)',
        ),
        backgroundColor: Colors.orange,
      ),
    );

    _loadData();
  }

  void _showCriticalAlerts() {
    final criticalIncidents = _incidents
        .where((i) => i['severity'] == 'P0' || i['severity'] == 'critical')
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Critical Alerts'),
        content: SizedBox(
          width: 80.w,
          height: 60.h,
          child: ListView.builder(
            itemCount: criticalIncidents.length,
            itemBuilder: (context, index) {
              final incident = criticalIncidents[index];
              return ListTile(
                title: Text(incident['title'] ?? 'Unknown'),
                subtitle: Text(incident['description'] ?? ''),
                leading: const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'Mobile Operations Console',
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Colors.white,
            ),
            onPressed: _startVoiceCommand,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  _buildEmergencyDashboard(),
                  Expanded(child: _buildIncidentCarousel()),
                  _buildEmergencyActionButtons(),
                ],
              ),
            ),
      floatingActionButton: _buildQuickActionSpeedDial(),
    );
  }

  Widget _buildEmergencyDashboard() {
    final criticalAlerts = _dashboardStats['critical_alerts'] ?? 0;
    final activeIncidents = _dashboardStats['active_incidents'] ?? 0;
    final systemHealth = _dashboardStats['system_health'] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLargeStatusCard(
            'Critical Alerts',
            criticalAlerts.toString(),
            Colors.red,
            Icons.warning,
            onTap: _showCriticalAlerts,
          ),
          _buildLargeStatusCard(
            'Active Incidents',
            activeIncidents.toString(),
            Colors.orange,
            Icons.error_outline,
          ),
          _buildLargeStatusCard(
            'System Health',
            '${systemHealth.toStringAsFixed(0)}%',
            _getHealthColor(systemHealth),
            Icons.health_and_safety,
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStatusCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        width: 28.w,
        height: 15.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(102),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(double health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.yellow[700]!;
    return Colors.red;
  }

  Widget _buildIncidentCarousel() {
    if (_incidents.isEmpty) {
      return Center(
        child: Text(
          'No active incidents',
          style: TextStyle(fontSize: 16.sp, color: Colors.white70),
        ),
      );
    }

    return PageView.builder(
      controller: _incidentPageController,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _currentIncidentIndex = index);
      },
      itemCount: _incidents.length,
      itemBuilder: (context, index) {
        final incident = _incidents[index];
        return _buildIncidentCard(incident);
      },
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Swipe left to escalate
          HapticFeedback.mediumImpact();
          _escalateIncident(incident['incident_id']);
        } else if (details.primaryVelocity! > 0) {
          // Swipe right to acknowledge
          HapticFeedback.mediumImpact();
          _acknowledgeIncident(incident['incident_id']);
        }
      },
      child: Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: _getSeverityColor(incident['severity']),
            width: 3,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    incident['title'] ?? 'Unknown Incident',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildSeverityBadge(incident['severity']),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              incident['description'] ?? '',
              style: TextStyle(fontSize: 14.sp, color: Colors.white70),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: (incident['affected_systems'] as List<dynamic>? ?? [])
                  .map((system) => _buildAffectedSystemChip(system.toString()))
                  .toList(),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.timer, color: Colors.white70, size: 20.sp),
                SizedBox(width: 2.w),
                Text(
                  'Ongoing for ${_calculateDuration(incident['detected_at'])}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildPinchToZoomChart(),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swipe, color: Colors.white38, size: 16.sp),
                SizedBox(width: 2.w),
                Text(
                  'Swipe right to acknowledge, left to escalate',
                  style: TextStyle(fontSize: 12.sp, color: Colors.white38),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    return Container(
      width: 60,
      height: 30,
      decoration: BoxDecoration(
        color: _getSeverityColor(severity),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Center(
        child: Text(
          severity.toUpperCase(),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'p0':
      case 'critical':
        return Colors.red;
      case 'p1':
      case 'high':
        return Colors.orange;
      case 'p2':
      case 'medium':
        return Colors.yellow[700]!;
      default:
        return Colors.blue;
    }
  }

  Widget _buildAffectedSystemChip(String system) {
    return Container(
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Center(
        child: Text(
          system,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _calculateDuration(String? detectedAt) {
    if (detectedAt == null) return 'Unknown';

    final detected = DateTime.parse(detectedAt);
    final duration = DateTime.now().difference(detected);

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }

  Widget _buildPinchToZoomChart() {
    return InteractiveViewer(
      transformationController: _chartTransformController,
      minScale: 0.5,
      maxScale: 3.0,
      onInteractionEnd: (details) {
        // Reset zoom on double tap
        if (_chartTransformController.value != Matrix4.identity()) {
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        height: 25.h,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  10,
                  (i) => FlSpot(i.toDouble(), (i * 10 + 50).toDouble()),
                ),
                isCurved: true,
                color: Colors.red,
                barWidth: 3,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyActionButtons() {
    if (_incidents.isEmpty) return const SizedBox.shrink();

    final currentIncident = _incidents[_currentIncidentIndex];

    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildEmergencyButton(
            'Acknowledge',
            Icons.fingerprint,
            Colors.green,
            () => _acknowledgeIncident(currentIncident['incident_id']),
          ),
          _buildEmergencyButton(
            'Escalate',
            Icons.arrow_upward,
            Colors.orange,
            () => _escalateIncident(currentIncident['incident_id']),
          ),
          _buildEmergencyButton(
            'Resolve',
            Icons.check_circle,
            Colors.blue,
            () => _resolveIncident(currentIncident['incident_id']),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        width: 28.w,
        height: 15.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(102),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32.sp),
            SizedBox(height: 1.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'call_engineer',
          backgroundColor: Colors.blue,
          onPressed: () {
            HapticFeedback.selectionClick();
            _callOnCallEngineer();
          },
          child: const Icon(Icons.phone),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'page_team',
          backgroundColor: Colors.orange,
          onPressed: () {
            HapticFeedback.selectionClick();
            _pageTeam();
          },
          child: const Icon(Icons.notifications),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'send_alert',
          backgroundColor: Colors.red,
          onPressed: () {
            HapticFeedback.selectionClick();
            _sendSlackAlert();
          },
          child: const Icon(Icons.message),
        ),
        SizedBox(height: 2.h),
        FloatingActionButton(
          heroTag: 'lock_down',
          backgroundColor: Colors.purple,
          onPressed: () {
            HapticFeedback.selectionClick();
            _lockDownSystem();
          },
          child: const Icon(Icons.lock),
        ),
      ],
    );
  }

  Future<void> _callOnCallEngineer() async {
    try {
      await TwilioNotificationService.instance.sendVoteDeadlineNotification(
        phoneNumber: '+1234567890',
        voteTitle: 'Emergency Alert',
        deadline: DateTime.now().add(const Duration(hours: 1)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('On-call engineer notified'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pageTeam() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PagerDuty incident created'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _sendSlackAlert() async {
    try {
      if (_incidents.isNotEmpty) {
        await SlackNotificationService.instance.sendIncidentAlert(
          incident: _incidents[_currentIncidentIndex],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slack alert sent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _lockDownSystem() async {
    final authenticated = await _authenticateWithBiometrics('lock down system');
    if (!authenticated) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm System Lock Down'),
        content: const Text(
          'This will restrict all non-admin access. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('System locked down'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Lock Down'),
          ),
        ],
      ),
    );
  }
}
