import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/alert_aggregation_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class RealTimeAlertDashboard extends StatefulWidget {
  const RealTimeAlertDashboard({super.key});

  @override
  State<RealTimeAlertDashboard> createState() => _RealTimeAlertDashboardState();
}

class _RealTimeAlertDashboardState extends State<RealTimeAlertDashboard> {
  final AlertAggregationService _alertService =
      AlertAggregationService.instance;
  final AuthService _auth = AuthService.instance;

  StreamSubscription? _alertSubscription;
  List<Map<String, dynamic>> _alerts = [];
  Map<String, dynamic> _summary = {};
  Map<String, int> _alertCountsByType = {};

  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedAlerts = {};

  // Filters
  final Set<String> _selectedSeverities = {'critical', 'high', 'medium', 'low'};
  final Set<String> _selectedTypes = {
    'threat_correlation',
    'sla_breach',
    'rule_violation',
    'security_incident',
    'system_health',
    'performance',
    'compliance',
  };
  final Set<String> _selectedStatuses = {'unacknowledged', 'acknowledged'};
  String _searchQuery = '';
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _loadSummary();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _alertService.aggregateAlerts(
        alertTypes: _selectedTypes.toList(),
        severities: _selectedSeverities.toList(),
        limit: 200,
      );
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load alerts error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _alertService.getAlertSummary();
      final counts = await _alertService.getAlertCountsByType();
      setState(() {
        _summary = summary;
        _alertCountsByType = counts;
      });
    } catch (e) {
      debugPrint('Load summary error: $e');
    }
  }

  void _setupRealTimeUpdates() {
    _alertSubscription = _alertService.streamAlerts().listen((alerts) {
      if (mounted) {
        setState(() => _alerts = alerts);
        _loadSummary();
      }
    });
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    return _alerts.where((alert) {
      // Filter by severity
      if (!_selectedSeverities.contains(alert['severity'])) return false;

      // Filter by type
      if (!_selectedTypes.contains(alert['alert_type'])) return false;

      // Filter by status
      if (!_selectedStatuses.contains(alert['acknowledgment_status'])) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final title = (alert['title'] as String? ?? '').toLowerCase();
        final description = (alert['description'] as String? ?? '')
            .toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList()..sort((a, b) {
      switch (_sortBy) {
        case 'newest':
          return DateTime.parse(
            b['detected_at'],
          ).compareTo(DateTime.parse(a['detected_at']));
        case 'oldest':
          return DateTime.parse(
            a['detected_at'],
          ).compareTo(DateTime.parse(b['detected_at']));
        case 'severity_high':
          final severityOrder = {
            'critical': 0,
            'high': 1,
            'medium': 2,
            'low': 3,
          };
          return (severityOrder[a['severity']] ?? 4).compareTo(
            severityOrder[b['severity']] ?? 4,
          );
        case 'severity_low':
          final severityOrder = {
            'low': 0,
            'medium': 1,
            'high': 2,
            'critical': 3,
          };
          return (severityOrder[a['severity']] ?? 4).compareTo(
            severityOrder[b['severity']] ?? 4,
          );
        default:
          return 0;
      }
    });
  }

  Future<void> _batchAcknowledge() async {
    if (_selectedAlerts.isEmpty) return;

    final result = await _alertService.batchAcknowledgeAlerts(
      _selectedAlerts.toList(),
      note: 'Batch acknowledged',
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Acknowledged ${result['success_count']} of ${_selectedAlerts.length} alerts',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isSelectionMode = false;
        _selectedAlerts.clear();
      });
      _loadAlerts();
    }
  }

  Future<void> _batchDismiss() async {
    if (_selectedAlerts.isEmpty) return;

    final reason = await _showDismissalReasonDialog();
    if (reason == null) return;

    final result = await _alertService.batchDismissAlerts(
      _selectedAlerts.toList(),
      reason,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dismissed ${result['success_count']} of ${_selectedAlerts.length} alerts',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isSelectionMode = false;
        _selectedAlerts.clear();
      });
      _loadAlerts();
    }
  }

  Future<String?> _showDismissalReasonDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismissal Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for dismissal',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'Real-Time Alert Dashboard',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Real-Time Alert Dashboard',
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedAlerts.clear();
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: () => setState(() => _isSelectionMode = true),
              ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const ShimmerSkeletonLoader(child: SkeletonDashboard())
            : RefreshIndicator(
                onRefresh: _loadAlerts,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(),
                      SizedBox(height: 2.h),
                      _buildSearchBar(),
                      SizedBox(height: 2.h),
                      _buildFilterChips(),
                      SizedBox(height: 2.h),
                      _buildSortControls(),
                      SizedBox(height: 2.h),
                      _buildAlertList(),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _isSelectionMode && _selectedAlerts.isNotEmpty
            ? _buildBatchActionsBar()
            : null,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SizedBox(
      height: 12.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            'Total Active',
            _summary['total_active']?.toString() ?? '0',
            Icons.notifications_active,
            Colors.blue,
          ),
          SizedBox(width: 3.w),
          _buildSummaryCard(
            'Critical',
            _summary['critical_alerts']?.toString() ?? '0',
            Icons.warning,
            Colors.red,
          ),
          SizedBox(width: 3.w),
          _buildSummaryCard(
            'Unacknowledged',
            _summary['unacknowledged']?.toString() ?? '0',
            Icons.error_outline,
            Colors.orange,
          ),
          SizedBox(width: 3.w),
          _buildSummaryCard(
            'Avg Response',
            '${_summary['avg_response_time_minutes'] ?? 0}m',
            Icons.timer,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 35.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 6.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search alerts...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        filled: true,
        fillColor: Colors.white,
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: [
        ..._selectedSeverities.map(
          (severity) => FilterChip(
            label: Text(severity.toUpperCase()),
            selected: true,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedSeverities.add(severity);
                } else {
                  _selectedSeverities.remove(severity);
                }
              });
            },
            selectedColor: _getSeverityColor(severity).withAlpha(51),
          ),
        ),
      ],
    );
  }

  Widget _buildSortControls() {
    return Row(
      children: [
        Text(
          'Sort by:',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: DropdownButton<String>(
            value: _sortBy,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
              DropdownMenuItem(
                value: 'severity_high',
                child: Text('Severity: High to Low'),
              ),
              DropdownMenuItem(
                value: 'severity_low',
                child: Text('Severity: Low to High'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortBy = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertList() {
    if (_filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Icon(Icons.check_circle_outline, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No alerts found',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredAlerts.map((alert) => _buildAlertCard(alert)).toList(),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final alertId = alert['id'] as String;
    final isSelected = _selectedAlerts.contains(alertId);
    final severity = alert['severity'] as String;
    final alertType = alert['alert_type'] as String;
    final title = alert['title'] as String? ?? 'Alert';
    final description = alert['description'] as String? ?? '';
    final detectedAt = DateTime.parse(alert['detected_at']);
    final status = alert['acknowledgment_status'] as String;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.withAlpha(26) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: _getSeverityColor(severity), width: 3.0),
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedAlerts.remove(alertId);
              } else {
                _selectedAlerts.add(alertId);
              }
            });
          } else {
            _showAlertDetails(alert);
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedAlerts.add(alertId);
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 6.w,
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _getAlertTypeColor(alertType).withAlpha(51),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getAlertTypeIcon(alertType),
                    color: _getAlertTypeColor(alertType),
                    size: 5.w,
                  ),
                ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(severity),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withAlpha(51),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          timeago.format(detectedAt),
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        ),
                      ],
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

  Widget _buildBatchActionsBar() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            '${_selectedAlerts.length} selected',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _batchAcknowledge,
            icon: const Icon(Icons.check),
            label: const Text('Acknowledge'),
          ),
          TextButton.icon(
            onPressed: _batchDismiss,
            icon: const Icon(Icons.close),
            label: const Text('Dismiss'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Severity'),
              ..._buildSeverityCheckboxes(),
              SizedBox(height: 2.h),
              const Text('Alert Type'),
              ..._buildTypeCheckboxes(),
              SizedBox(height: 2.h),
              const Text('Status'),
              ..._buildStatusCheckboxes(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAlerts();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeverityCheckboxes() {
    return ['critical', 'high', 'medium', 'low'].map((severity) {
      return CheckboxListTile(
        title: Text(severity.toUpperCase()),
        value: _selectedSeverities.contains(severity),
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedSeverities.add(severity);
            } else {
              _selectedSeverities.remove(severity);
            }
          });
        },
      );
    }).toList();
  }

  List<Widget> _buildTypeCheckboxes() {
    return [
      'threat_correlation',
      'sla_breach',
      'rule_violation',
      'security_incident',
      'system_health',
      'performance',
      'compliance',
    ].map((type) {
      return CheckboxListTile(
        title: Text(type.replaceAll('_', ' ').toUpperCase()),
        value: _selectedTypes.contains(type),
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedTypes.add(type);
            } else {
              _selectedTypes.remove(type);
            }
          });
        },
      );
    }).toList();
  }

  List<Widget> _buildStatusCheckboxes() {
    return ['unacknowledged', 'acknowledged', 'resolved', 'dismissed'].map((
      status,
    ) {
      return CheckboxListTile(
        title: Text(status.toUpperCase()),
        value: _selectedStatuses.contains(status),
        onChanged: (checked) {
          setState(() {
            if (checked == true) {
              _selectedStatuses.add(status);
            } else {
              _selectedStatuses.remove(status);
            }
          });
        },
      );
    }).toList();
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alert['title'] ?? 'Alert Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'Description',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 0.5.h),
              Text(
                alert['description'] ?? 'No description',
                style: TextStyle(fontSize: 12.sp),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _alertService.acknowledgeAlert(alert['id']);
                        Navigator.pop(context);
                        _loadAlerts();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Acknowledge'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _alertService.resolveAlert(
                          alert['id'],
                          resolutionNotes: 'Resolved from dashboard',
                        );
                        Navigator.pop(context);
                        _loadAlerts();
                      },
                      icon: const Icon(Icons.done_all),
                      label: const Text('Resolve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getAlertTypeColor(String type) {
    switch (type) {
      case 'threat_correlation':
        return Colors.red;
      case 'sla_breach':
        return Colors.orange;
      case 'rule_violation':
        return Colors.purple;
      case 'security_incident':
        return Colors.red[900]!;
      case 'system_health':
        return Colors.green;
      case 'performance':
        return Colors.blue;
      case 'compliance':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertTypeIcon(String type) {
    switch (type) {
      case 'threat_correlation':
        return Icons.link;
      case 'sla_breach':
        return Icons.timeline;
      case 'rule_violation':
        return Icons.block;
      case 'security_incident':
        return Icons.security;
      case 'system_health':
        return Icons.favorite;
      case 'performance':
        return Icons.speed;
      case 'compliance':
        return Icons.policy;
      default:
        return Icons.notifications;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'unacknowledged':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'dismissed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
