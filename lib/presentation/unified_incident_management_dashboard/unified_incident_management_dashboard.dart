import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/unified_incident_aggregator_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/incident_card_widget.dart';
import './widgets/incident_summary_card_widget.dart';

class UnifiedIncidentManagementDashboard extends StatefulWidget {
  const UnifiedIncidentManagementDashboard({super.key});

  @override
  State<UnifiedIncidentManagementDashboard> createState() =>
      _UnifiedIncidentManagementDashboardState();
}

class _UnifiedIncidentManagementDashboardState
    extends State<UnifiedIncidentManagementDashboard> {
  bool _isLoading = true;
  final List<UnifiedIncident> _incidents = [];
  StreamSubscription<UnifiedIncident>? _incidentSubscription;
  final _aggregator = UnifiedIncidentAggregator();

  int _totalActive = 0;
  int _criticalIncidents = 0;
  double _avgResponseTime = 0.0;
  int _resolvedToday = 0;
  int _escalatedIncidents = 0;
  int _slaAtRisk = 0;
  double _resolutionRate = 0.0;
  double _effectivenessScore = 0.0;

  String _filterType = 'all';
  String _filterSeverity = 'all';

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _startIncidentStream();
  }

  @override
  void dispose() {
    _incidentSubscription?.cancel();
    _aggregator.dispose();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      _incidents.clear();

      // Load existing incidents from database
      final response = await supabase
          .from('incidents')
          .select()
          .inFilter('status', [
            'detected',
            'acknowledged',
            'triaged',
            'investigating',
            'resolved',
            'escalated',
          ])
          .order('detected_at', ascending: false)
          .limit(50);

      // Convert to UnifiedIncident objects
      for (final record in response) {
        final incident = UnifiedIncident(
          incidentId: record['id'],
          incidentType: _parseIncidentType(record['type']),
          severity: _parseSeverity(record['severity']),
          title: record['title'],
          description: record['description'] ?? '',
          sourceSystem: 'incidents_table',
          detectedAt: DateTime.parse(record['detected_at']),
          status: _parseStatus(record['status']),
          affectedResources: List<String>.from(
            record['affected_systems'] ?? [],
          ),
          metadata: record,
          assignedTo: record['assigned_to'],
        );

        // Calculate priority score
        incident.priorityScore = _aggregator.calculatePriorityScore(incident);

        _incidents.add(incident);
      }

      _calculateStats();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading incidents: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startIncidentStream() {
    _incidentSubscription = _aggregator.startAggregation().listen((incident) {
      // Calculate priority score
      incident.priorityScore = _aggregator.calculatePriorityScore(incident);

      // Auto-assign to team
      final team = _aggregator.routeToTeam(incident.incidentType);
      incident.assignedTo = team;

      setState(() {
        _incidents.insert(0, incident);
        _calculateStats();
      });

      // Show notification for critical incidents
      if (incident.severity == IncidentSeverity.critical) {
        _showCriticalIncidentNotification(incident);
      }
    });
  }

  void _calculateStats() {
    _totalActive = _incidents
        .where((i) =>
            i.status != IncidentStatus.resolved &&
            i.status != IncidentStatus.escalated)
        .length;
    _criticalIncidents = _incidents
        .where((i) => i.severity == IncidentSeverity.critical)
        .length;
    _escalatedIncidents = _incidents
        .where((i) => i.status == IncidentStatus.escalated)
        .length;
    _slaAtRisk = _incidents
        .where((incident) => _isIncidentSlaAtRisk(incident))
        .length;

    final resolvedIncidents = _incidents.where(
      (i) => i.status == IncidentStatus.resolved,
    );
    final totalIncidents = _incidents.length;
    _resolutionRate = totalIncidents > 0
        ? (resolvedIncidents.length / totalIncidents) * 100
        : 0.0;

    if (resolvedIncidents.isNotEmpty) {
      final totalResponseTime = resolvedIncidents.fold<int>(0, (sum, incident) {
        final resolvedAt = _extractDateTime(
          incident.metadata['resolved_at']?.toString(),
        );
        final endTime = resolvedAt ?? DateTime.now();
        return sum + endTime.difference(incident.detectedAt).inMinutes;
      });
      _avgResponseTime = totalResponseTime / resolvedIncidents.length;
    } else {
      _avgResponseTime = 0.0;
    }

    _resolvedToday = _incidents.where((i) {
      return i.status == IncidentStatus.resolved &&
          i.detectedAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).length;

    // Blended effectiveness score balancing resolution quality and SLA pressure.
    final responseTimeScore = (100 - (_avgResponseTime / 2)).clamp(0, 100);
    final slaPenalty = (_slaAtRisk * 8).clamp(0, 40);
    _effectivenessScore =
        ((_resolutionRate * 0.6) + (responseTimeScore * 0.4) - slaPenalty)
            .clamp(0, 100)
            .toDouble();
  }

  DateTime? _extractDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool _isIncidentSlaAtRisk(UnifiedIncident incident) {
    if (incident.status == IncidentStatus.resolved) return false;
    final slaDeadline = _extractDateTime(
      incident.metadata['sla_deadline']?.toString(),
    );
    if (slaDeadline != null) {
      final remaining = slaDeadline.difference(DateTime.now()).inMinutes;
      return remaining <= 30;
    }
    final escalationLevel = incident.metadata['escalation_level']?.toString();
    return escalationLevel == 'P0' || escalationLevel == 'P1';
  }

  void _showCriticalIncidentNotification(UnifiedIncident incident) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Critical Incident: ${incident.title}'),
        backgroundColor: AppTheme.errorLight,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _openIncidentDetail(incident),
        ),
      ),
    );
  }

  IncidentType _parseIncidentType(String? type) {
    switch (type?.toLowerCase()) {
      case 'fraud':
        return IncidentType.fraud;
      case 'ai_failover':
        return IncidentType.aiFailover;
      case 'security':
        return IncidentType.security;
      case 'performance':
        return IncidentType.performance;
      case 'health':
        return IncidentType.health;
      case 'compliance':
        return IncidentType.compliance;
      default:
        return IncidentType.security;
    }
  }

  IncidentSeverity _parseSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'p0':
      case 'critical':
        return IncidentSeverity.critical;
      case 'p1':
      case 'high':
        return IncidentSeverity.high;
      case 'p2':
      case 'medium':
        return IncidentSeverity.medium;
      case 'p3':
      case 'low':
        return IncidentSeverity.low;
      default:
        return IncidentSeverity.medium;
    }
  }

  IncidentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'detected':
      case 'new':
        return IncidentStatus.newIncident;
      case 'triaged':
        return IncidentStatus.triaged;
      case 'investigating':
        return IncidentStatus.investigating;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'escalated':
        return IncidentStatus.escalated;
      default:
        return IncidentStatus.newIncident;
    }
  }

  List<UnifiedIncident> get _filteredIncidents {
    return _incidents.where((incident) {
      if (_filterType != 'all' &&
          incident.incidentType.toString().split('.').last != _filterType) {
        return false;
      }
      if (_filterSeverity != 'all' &&
          incident.severity.toString().split('.').last != _filterSeverity) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'UnifiedIncidentManagementDashboard',
      onRetry: _loadIncidents,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Incident Management',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'filter_list',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadIncidents,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  // Summary cards
                  Container(
                    padding: EdgeInsets.all(4.w),
                    color: AppTheme.surfaceLight,
                    child: Row(
                      children: [
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'Total Active',
                            value: _totalActive.toString(),
                            color: AppTheme.primaryLight,
                            icon: Icons.warning_amber,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'Critical',
                            value: _criticalIncidents.toString(),
                            color: AppTheme.errorLight,
                            icon: Icons.error,
                            isPulsing: _criticalIncidents > 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    color: AppTheme.surfaceLight,
                    child: Row(
                      children: [
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'Avg Response',
                            value: '${_avgResponseTime.toStringAsFixed(0)}m',
                            color: AppTheme.secondaryLight,
                            icon: Icons.timer,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'Resolved Today',
                            value: _resolvedToday.toString(),
                            color: AppTheme.accentLight,
                            icon: Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    color: AppTheme.surfaceLight,
                    child: Row(
                      children: [
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'SLA At Risk',
                            value: _slaAtRisk.toString(),
                            color: _slaAtRisk > 0
                                ? AppTheme.errorLight
                                : AppTheme.accentLight,
                            icon: Icons.gpp_maybe,
                            isPulsing: _slaAtRisk > 0,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'Effectiveness',
                            value: '${_effectivenessScore.toStringAsFixed(0)}%',
                            color: AppTheme.primaryLight,
                            icon: Icons.insights,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: IncidentSummaryCardWidget(
                            title: 'Escalated',
                            value: _escalatedIncidents.toString(),
                            color: Colors.orange,
                            icon: Icons.priority_high,
                            isPulsing: _escalatedIncidents > 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Incident feed
                  Expanded(
                    child: _filteredIncidents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 15.w,
                                  color: AppTheme.accentLight,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No active incidents',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(4.w),
                            itemCount: _filteredIncidents.length,
                            itemBuilder: (context, index) {
                              return IncidentCardWidget(
                                incident: _filteredIncidents[index],
                                onTap: () => _openIncidentDetail(
                                  _filteredIncidents[index],
                                ),
                                onAssign: () =>
                                    _assignIncident(_filteredIncidents[index]),
                                onEscalate: () =>
                                    _escalateIncident(_filteredIncidents[index]),
                                onTriage: () =>
                                    _triageIncident(_filteredIncidents[index]),
                                onInvestigate: () => _investigateIncident(
                                  _filteredIncidents[index],
                                ),
                                onResolve: () =>
                                    _resolveIncident(_filteredIncidents[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Incidents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _filterType,
              decoration: InputDecoration(labelText: 'Incident Type'),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
                DropdownMenuItem(
                  value: 'aiFailover',
                  child: Text('AI Failover'),
                ),
                DropdownMenuItem(value: 'security', child: Text('Security')),
                DropdownMenuItem(
                  value: 'performance',
                  child: Text('Performance'),
                ),
                DropdownMenuItem(value: 'health', child: Text('Health')),
                DropdownMenuItem(
                  value: 'compliance',
                  child: Text('Compliance'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _filterType = value ?? 'all'),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _filterSeverity,
              decoration: InputDecoration(labelText: 'Severity'),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Severities')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (value) =>
                  setState(() => _filterSeverity = value ?? 'all'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openIncidentDetail(UnifiedIncident incident) {
    // Navigate to incident detail screen
    Navigator.pushNamed(context, AppRoutes.incidentDetail, arguments: incident);
  }

  void _triageIncident(UnifiedIncident incident) {
    _applyIncidentStatusUpdate(incident, IncidentStatus.triaged);
  }

  void _investigateIncident(UnifiedIncident incident) {
    _applyIncidentStatusUpdate(incident, IncidentStatus.investigating);
  }

  void _resolveIncident(UnifiedIncident incident) {
    _applyIncidentStatusUpdate(incident, IncidentStatus.resolved);
  }

  Future<void> _assignIncident(UnifiedIncident incident) async {
    final ownerController = TextEditingController(text: incident.assignedTo ?? '');
    final notesController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Incident Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ownerController,
              decoration: InputDecoration(labelText: 'Owner user ID / team'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(labelText: 'Assignment notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Assign'),
          ),
        ],
      ),
    );

    if (submitted != true || ownerController.text.trim().isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('incidents')
          .update({
            'assigned_to': ownerController.text.trim(),
            'assignment_notes': notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            'assigned_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incident.incidentId);

      final index = _incidents.indexWhere((i) => i.incidentId == incident.incidentId);
      if (index != -1) {
        setState(() {
          _incidents[index] = incident.copyWith(
            assignedTo: ownerController.text.trim(),
          );
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Incident owner assigned')));
    } catch (e) {
      debugPrint('Failed to assign incident owner: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to assign owner')));
    }
  }

  Future<void> _escalateIncident(UnifiedIncident incident) async {
    String selectedLevel = 'P1';
    final notesController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Escalate Incident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: InputDecoration(labelText: 'Escalation level'),
                items: ['P0', 'P1', 'P2', 'P3']
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedLevel = value);
                },
              ),
              SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: 'Escalation notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Escalate'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) return;

    final severityValue = selectedLevel == 'P0'
        ? 'critical'
        : selectedLevel == 'P1'
            ? 'high'
            : selectedLevel == 'P2'
                ? 'medium'
                : 'low';

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('incidents')
          .update({
            'status': 'escalated',
            'escalation_level': selectedLevel,
            'escalation_notes': notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            'severity': severityValue,
            'escalated_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incident.incidentId);

      final index = _incidents.indexWhere((i) => i.incidentId == incident.incidentId);
      if (index != -1) {
        setState(() {
          _incidents[index] = incident.copyWith(
            status: IncidentStatus.escalated,
            severity: _parseSeverity(severityValue),
          );
          _calculateStats();
        });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Incident escalated to $selectedLevel')));
    } catch (e) {
      debugPrint('Failed to escalate incident: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to escalate incident')));
    }
  }

  Future<void> _applyIncidentStatusUpdate(
    UnifiedIncident incident,
    IncidentStatus nextStatus,
  ) async {
    final statusValue = _statusToDatabase(nextStatus);
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('incidents')
          .update({'status': statusValue, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', incident.incidentId);

      final index = _incidents.indexWhere((i) => i.incidentId == incident.incidentId);
      if (index != -1) {
        setState(() {
          _incidents[index] = incident.copyWith(status: nextStatus);
          _calculateStats();
        });
      }

      final label = nextStatus.toString().split('.').last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incident ${label.replaceAll('Incident', '')} updated')),
      );
    } catch (e) {
      debugPrint('Failed to update incident status: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update incident status')));
    }
  }

  String _statusToDatabase(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.newIncident:
        return 'detected';
      case IncidentStatus.triaged:
        return 'triaged';
      case IncidentStatus.investigating:
        return 'investigating';
      case IncidentStatus.resolved:
        return 'resolved';
      case IncidentStatus.escalated:
        return 'escalated';
    }
  }
}
