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

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() => _isLoading = true);
    try {
      // Fetch recent system alerts
      var query = _client
          .from('system_alerts')
          .select()
          .or(
            'resolved.eq.false,timestamp.gte.${DateTime.now().subtract(const Duration(days: 7)).toIso8601String()}',
          )
          .order('timestamp', ascending: false)
          .limit(50);

      if (_filterSeverity != 'all') {
        query = _client
            .from('system_alerts')
            .select()
            .eq('severity', _filterSeverity)
            .or(
              'resolved.eq.false,timestamp.gte.${DateTime.now().subtract(const Duration(days: 7)).toIso8601String()}',
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
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
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
                  : RefreshIndicator(
                      onRefresh: _loadIncidents,
                      child: ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _incidents.length,
                        itemBuilder: (context, index) {
                          return IncidentCardWidget(
                            incident: _incidents[index],
                            onResolve: () => _resolveIncident(
                              _incidents[index]['incident_id'] as String? ?? '',
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
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
}
