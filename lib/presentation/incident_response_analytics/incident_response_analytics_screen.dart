import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/incident_card_widget.dart';

class IncidentResponseAnalyticsScreen extends StatefulWidget {
  const IncidentResponseAnalyticsScreen({super.key});

  @override
  State<IncidentResponseAnalyticsScreen> createState() =>
      _IncidentResponseAnalyticsScreenState();
}

class _IncidentResponseAnalyticsScreenState
    extends State<IncidentResponseAnalyticsScreen> {
  final _client = SupabaseService.instance.client;
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;
  String _filterSeverity = 'all';
  String _timeRange = '7d';
  bool _autoRefresh = true;
  String _activeTab = 'correlation';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _configureAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final startDate = _timeRange == '24h'
          ? now.subtract(const Duration(hours: 24))
          : _timeRange == '30d'
              ? now.subtract(const Duration(days: 30))
              : now.subtract(const Duration(days: 7));

      // Fetch recent system alerts
      var query = _client
          .from('system_alerts')
          .select()
          .or(
            'resolved.eq.false,timestamp.gte.${startDate.toIso8601String()}',
          )
          .order('timestamp', ascending: false)
          .limit(50);

      if (_filterSeverity != 'all') {
        query = _client
            .from('system_alerts')
            .select()
            .eq('severity', _filterSeverity)
            .or(
              'resolved.eq.false,timestamp.gte.${startDate.toIso8601String()}',
            )
            .order('timestamp', ascending: false)
            .limit(50);
      }

      final alertsResponse = await query;
      final alerts = List<Map<String, dynamic>>.from(alertsResponse);

      // Fetch feature deployments for correlation
      final deploymentsResponse = await _client
          .from('feature_deployment_log')
          .select()
          .gte(
            'deployment_date',
            startDate.toIso8601String(),
          )
          .order('deployment_date', ascending: false)
          .limit(100);

      final deployments = List<Map<String, dynamic>>.from(deploymentsResponse);

      // Correlate incidents with deployments
      final correlatedIncidents = alerts.map((alert) {
        final alertTime =
            DateTime.tryParse(alert['timestamp'] as String? ?? '') ??
            DateTime.now();
        final affectedComponent = (alert['affected_component'] as String? ?? '')
            .toLowerCase();

        // Find correlated deployments within ±1 hour
        final correlated = deployments
            .where((dep) {
              final depTime =
                  DateTime.tryParse(dep['deployment_date'] as String? ?? '') ??
                  DateTime.now();
              final diff = alertTime.difference(depTime).abs();
              return diff.inHours <= 1;
            })
            .map((dep) {
              final depTime =
                  DateTime.tryParse(dep['deployment_date'] as String? ?? '') ??
                  DateTime.now();
              final diff = alertTime.difference(depTime).abs();
              final featureName = (dep['feature_name'] as String? ?? '')
                  .toLowerCase();

              // Calculate proximity score
              double proximityScore;
              if (diff.inMinutes <= 5) {
                proximityScore = 1.0;
              } else if (diff.inMinutes <= 15) {
                proximityScore = 0.8;
              } else {
                proximityScore = 0.5;
              }

              // Calculate impact score
              final severity = alert['severity'] as String? ?? '';
              double impactScore = 0.5;
              if (severity == 'critical' &&
                  affectedComponent.contains(featureName)) {
                impactScore = 1.0;
              }

              final correlationScore = proximityScore * impactScore;

              String possibleCause;
              if (correlationScore > 0.7) {
                possibleCause =
                    'Feature deployment: ${dep['feature_name']} at ${dep['deployment_date']}';
              } else if (correlationScore > 0.4) {
                possibleCause = 'Possible infrastructure issue';
              } else {
                possibleCause = 'Unknown cause';
              }

              return {
                ...dep,
                'correlation_score': correlationScore,
                'possible_cause': possibleCause,
              };
            })
            .toList();

        correlated.sort(
          (a, b) => (b['correlation_score'] as double).compareTo(
            a['correlation_score'] as double,
          ),
        );

        return {...alert, 'correlated_features': correlated};
      }).toList();

      if (mounted) {
        setState(() {
          _incidents = correlatedIncidents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load incidents error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _configureAutoRefresh() {
    _refreshTimer?.cancel();
    if (!_autoRefresh) return;
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) {
        _loadIncidents();
      }
    });
  }

  Map<String, dynamic> _analyticsSummary() {
    final total = _incidents.length;
    final critical = _incidents
        .where((incident) => incident['severity']?.toString() == 'critical')
        .length;
    final correlated = _incidents
        .where((incident) =>
            (incident['correlated_features'] as List?)?.isNotEmpty == true)
        .length;
    final deploymentLinked = _incidents
        .where((incident) {
          final correlatedFeatures =
              List<Map<String, dynamic>>.from(incident['correlated_features'] ?? []);
          if (correlatedFeatures.isEmpty) return false;
          final bestScore = correlatedFeatures
              .map((item) => (item['correlation_score'] as num?)?.toDouble() ?? 0.0)
              .fold<double>(0.0, (prev, current) => current > prev ? current : prev);
          return bestScore >= 0.7;
        })
        .length;

    final confidence = correlated > 0
        ? (_incidents
                    .where((incident) =>
                        (incident['correlated_features'] as List?)?.isNotEmpty == true)
                    .map((incident) {
                      final correlatedFeatures = List<Map<String, dynamic>>.from(
                        incident['correlated_features'] ?? [],
                      );
                      if (correlatedFeatures.isEmpty) return 0.0;
                      final topScore = correlatedFeatures
                          .map((item) =>
                              (item['correlation_score'] as num?)?.toDouble() ?? 0.0)
                          .fold<double>(0.0, (prev, current) => current > prev ? current : prev);
                      return topScore;
                    })
                    .fold<double>(0.0, (sum, score) => sum + score) /
                correlated) *
            100
        : 0.0;

    final systemHealth = (100 - (critical * 8)).clamp(0, 100).toDouble();

    return {
      'total': total,
      'critical': critical,
      'correlationConfidence': confidence,
      'deploymentLinked': deploymentLinked,
      'systemHealth': systemHealth,
    };
  }

  Future<void> _resolveIncident(String incidentId) async {
    try {
      await _client
          .from('system_alerts')
          .update({'resolved': true})
          .eq('incident_id', incidentId);
      await _loadIncidents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident marked as resolved')),
        );
      }
    } catch (e) {
      debugPrint('Resolve incident error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _analyticsSummary();
    return ErrorBoundaryWrapper(
      screenName: 'IncidentResponseAnalytics',
      onRetry: _loadIncidents,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Incident Response Analytics',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadIncidents,
            ),
            IconButton(
              icon: Icon(_autoRefresh ? Icons.pause : Icons.play_arrow),
              tooltip: _autoRefresh ? 'Pause auto-refresh' : 'Enable auto-refresh',
              onPressed: () {
                setState(() => _autoRefresh = !_autoRefresh);
                _configureAutoRefresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.assessment),
              tooltip: 'Feature Implementation Tracking',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.featureImplementationTracking,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSummaryCards(summary),
            _buildTimeRangeSelector(),
            _buildTabSelector(),
            // Severity Filter
            _buildSeverityFilter(),
            // Incidents List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _incidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No active incidents',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    )
                  : _buildAnalyticsTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTabContent() {
    return RefreshIndicator(
      onRefresh: _loadIncidents,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          if (_activeTab == 'correlation') ...[
            ..._incidents.map((incident) {
              return IncidentCardWidget(
                incident: incident,
                onResolve: () => _resolveIncident(
                  incident['incident_id'] as String? ?? '',
                ),
              );
            }),
          ],
          if (_activeTab == 'root_cause') ..._buildRootCauseSection(),
          if (_activeTab == 'health_impact') ..._buildHealthImpactSection(),
          if (_activeTab == 'deployment') ..._buildDeploymentSection(),
          if (_activeTab == 'predictive') ..._buildPredictiveSection(),
          if (_activeTab == 'intelligence') ..._buildIntelligenceSection(),
        ],
      ),
    );
  }

  Widget _buildSeverityFilter() {
    final severities = ['all', 'critical', 'high', 'medium', 'low'];
    return Container(
      height: 5.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: severities.length,
        itemBuilder: (context, index) {
          final sev = severities[index];
          final isSelected = _filterSeverity == sev;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(sev.toUpperCase()),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _filterSeverity = sev);
                _loadIncidents();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final ranges = <String, String>{
      '24h': '24h',
      '7d': '7d',
      '30d': '30d',
    };
    return Container(
      height: 5.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ranges.entries.map((entry) {
          final selected = _timeRange == entry.key;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) {
                setState(() => _timeRange = entry.key);
                _loadIncidents();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = <(String, String, IconData)>[
      ('correlation', 'Correlation', Icons.hub),
      ('root_cause', 'Root Cause', Icons.search),
      ('health_impact', 'Health Impact', Icons.health_and_safety),
      ('deployment', 'Deployment', Icons.rocket_launch),
      ('predictive', 'Predictive', Icons.trending_up),
      ('intelligence', 'Intelligence', Icons.auto_awesome),
    ];
    return Container(
      height: 5.2.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tabs.map((tab) {
          final selected = _activeTab == tab.$1;
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: ChoiceChip(
              avatar: Icon(tab.$3, size: 16, color: selected ? Colors.white : null),
              label: Text(tab.$2),
              selected: selected,
              onSelected: (_) => setState(() => _activeTab = tab.$1),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildRootCauseSection() {
    final causes = <String, int>{};
    for (final incident in _incidents) {
      final correlated = List<Map<String, dynamic>>.from(
        incident['correlated_features'] ?? [],
      );
      final cause = correlated.isNotEmpty
          ? (correlated.first['possible_cause']?.toString() ?? 'Unknown cause')
          : 'Unknown cause';
      causes[cause] = (causes[cause] ?? 0) + 1;
    }
    if (causes.isEmpty) {
      return [const ListTile(title: Text('No root cause evidence available'))];
    }
    return causes.entries.map((entry) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lightbulb_outline),
          title: Text(entry.key),
          subtitle: Text('Incidents linked: ${entry.value}'),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPredictiveSection() {
    final criticalCount = _incidents
        .where((incident) => incident['severity']?.toString() == 'critical')
        .length;
    final highCount = _incidents
        .where((incident) => incident['severity']?.toString() == 'high')
        .length;
    final predictedNext24h = (criticalCount * 1.2 + highCount * 0.8).round();
    final riskLevel = predictedNext24h > 8
        ? 'High'
        : predictedNext24h > 4
            ? 'Medium'
            : 'Low';
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.timelapse),
          title: const Text('Predicted incidents (next 24h)'),
          trailing: Text(
            '$predictedNext24h',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.warning_amber),
          title: const Text('Projected risk level'),
          trailing: Text(
            riskLevel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: riskLevel == 'High'
                  ? Colors.red
                  : riskLevel == 'Medium'
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildHealthImpactSection() {
    final summary = _analyticsSummary();
    final critical = summary['critical'] as int? ?? 0;
    final active = summary['total'] as int? ?? 0;
    final health = summary['systemHealth'] as double? ?? 0.0;
    final impactSeverity = critical >= 3
        ? 'Severe'
        : critical >= 1
            ? 'Moderate'
            : 'Low';

    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.health_and_safety),
          title: const Text('System Health Score'),
          trailing: Text(
            '${health.toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.warning_amber),
          title: const Text('Critical Impact Severity'),
          subtitle: Text('Critical incidents: $critical • Active incidents: $active'),
          trailing: Text(
            impactSeverity,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: impactSeverity == 'Severe'
                  ? Colors.red
                  : impactSeverity == 'Moderate'
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDeploymentSection() {
    final deploymentInsights = _incidents
        .where((incident) =>
            (incident['correlated_features'] as List?)?.isNotEmpty == true)
        .map((incident) {
          final correlated = List<Map<String, dynamic>>.from(
            incident['correlated_features'] ?? [],
          );
          final top = correlated.isEmpty ? null : correlated.first;
          return {
            'incident': incident['alert_type']?.toString() ?? 'Unknown incident',
            'feature': top?['feature_name']?.toString() ?? 'Unknown feature',
            'score': (top?['correlation_score'] as num?)?.toDouble() ?? 0.0,
            'cause': top?['possible_cause']?.toString() ?? 'Unknown cause',
          };
        })
        .toList();

    if (deploymentInsights.isEmpty) {
      return [
        const ListTile(
          leading: Icon(Icons.rocket_launch),
          title: Text('No deployment correlations detected in selected range'),
        ),
      ];
    }

    return deploymentInsights.map((insight) {
      final score = insight['score'] as double;
      return Card(
        child: ListTile(
          leading: const Icon(Icons.link),
          title: Text(insight['incident'] as String),
          subtitle: Text(
            '${insight['feature']} • ${insight['cause']}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: score >= 0.7
                  ? Colors.red
                  : score >= 0.4
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildIntelligenceSection() {
    final deploymentLinked = _incidents.where((incident) {
      final correlatedFeatures =
          List<Map<String, dynamic>>.from(incident['correlated_features'] ?? []);
      return correlatedFeatures.any((f) {
        final score = (f['correlation_score'] as num?)?.toDouble() ?? 0.0;
        return score >= 0.7;
      });
    }).length;
    final confidence = _analyticsSummary()['correlationConfidence'] as double;
    final recommendation = deploymentLinked > 0
        ? 'High deployment correlation detected. Prioritize rollback / feature-gating checks.'
        : 'No strong deployment correlation. Prioritize infra and dependency diagnostics.';

    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.hub),
          title: const Text('High-confidence deployment links'),
          trailing: Text(
            '$deploymentLinked',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.track_changes),
          title: const Text('Correlation confidence'),
          trailing: Text(
            '${confidence.toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Automated Correlation Intelligence',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(recommendation),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final cards = [
      (
        'Active',
        '${summary['total'] ?? 0}',
        Icons.warning_amber_rounded,
        Colors.red
      ),
      (
        'Corr. Confidence',
        '${(summary['correlationConfidence'] as double).toStringAsFixed(0)}%',
        Icons.track_changes,
        Colors.blue
      ),
      (
        'Deployment Linked',
        '${summary['deploymentLinked'] ?? 0}',
        Icons.rocket_launch,
        Colors.purple
      ),
      (
        'System Health',
        '${(summary['systemHealth'] as double).toStringAsFixed(0)}%',
        Icons.health_and_safety,
        Colors.green
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, index) {
          final card = cards[index];
          return Container(
            padding: EdgeInsets.all(2.6.w),
            decoration: BoxDecoration(
              color: card.$4.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: card.$4.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(card.$3, color: card.$4),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.$1,
                        style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        card.$2,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
